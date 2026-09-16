import Foundation

enum Shell {
    static func capture(_ command: String, directory: URL? = nil) -> String? {
        let process = Process()
        let pipe = Pipe()
        process.executableURL = URL(fileURLWithPath: "/bin/zsh")
        process.arguments = ["-lc", command]
        process.currentDirectoryURL = directory
        process.standardOutput = pipe
        process.standardError = Pipe()

        do {
            try process.run()
            process.waitUntilExit()
            guard process.terminationStatus == 0 else { return nil }
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            return String(data: data, encoding: .utf8)?
                .trimmingCharacters(in: .whitespacesAndNewlines)
        } catch {
            return nil
        }
    }

    static func which(_ executable: String) -> String? {
        capture("command -v \(shellQuote(executable))")
    }

    static func shellQuote(_ value: String) -> String {
        "'" + value.replacingOccurrences(of: "'", with: "'\\''") + "'"
    }
}

enum ToolScanner {
    static func scanAll() async -> [ToolDescriptor] {
        await Task.detached(priority: .userInitiated) {
            let home = FileManager.default.homeDirectoryForCurrentUser.path
            let androidADB = "\(home)/Library/Android/sdk/platform-tools/adb"
            let androidEmulator = "\(home)/Library/Android/sdk/emulator/emulator"

            return [
                app(.xcode, "Xcode", .apple, paths: ["/Applications/Xcode.app"], versionCommand: "xcodebuild -version | head -1"),
                app(.vscode, "Visual Studio Code", .editor, paths: ["/Applications/Visual Studio Code.app"], cli: "code", versionCommand: "code --version | head -1"),
                app(.androidStudio, "Android Studio", .android, paths: ["/Applications/Android Studio.app"]),
                app(.blender, "Blender", .engine3D, paths: ["/Applications/Blender.app"], cli: "blender", versionCommand: "blender --version | head -1"),
                app(.unity, "Unity Hub", .engine3D, paths: ["/Applications/Unity Hub.app"]),
                unrealDescriptor(),
                cli(.git, "Git", .source, executable: "git", versionCommand: "git --version"),
                cli(.github, "GitHub CLI", .source, executable: "gh", versionCommand: "gh --version | head -1"),
                cli(.node, "Node.js", .runtime, executable: "node", versionCommand: "node --version"),
                cli(.pnpm, "pnpm", .runtime, executable: "pnpm", versionCommand: "pnpm --version"),
                cli(.python, "Python", .runtime, executable: "python3", versionCommand: "python3 --version"),
                cli(.wrangler, "Cloudflare Wrangler", .cloud, executable: "wrangler", versionCommand: "wrangler --version"),
                cli(.vercel, "Vercel CLI", .cloud, executable: "vercel", versionCommand: "vercel --version"),
                fileOrCLI(.adb, "Android Debug Bridge", .android, file: androidADB, executable: "adb", versionCommand: "adb version | head -1"),
                fileOrCLI(.emulator, "Android Emulator", .android, file: androidEmulator, executable: "emulator", versionCommand: "emulator -version | head -1"),
                cli(.eas, "Expo EAS CLI", .release, executable: "eas", versionCommand: "eas --version"),
                cli(.supabase, "Supabase CLI", .cloud, executable: "supabase", versionCommand: "supabase --version"),
                cli(.fastlane, "fastlane", .release, executable: "fastlane", versionCommand: "fastlane --version | tail -1"),
                cli(.podman, "Podman", .runtime, executable: "podman", versionCommand: "podman --version"),
                cli(.docker, "Docker", .runtime, executable: "docker", versionCommand: "docker --version")
            ]
        }.value
    }

    private static func app(
        _ id: ToolID,
        _ name: String,
        _ category: ToolCategory,
        paths: [String],
        cli: String? = nil,
        versionCommand: String? = nil
    ) -> ToolDescriptor {
        let fileManager = FileManager.default
        let path = paths.first(where: { fileManager.fileExists(atPath: $0) })
        let cliPath = cli.flatMap { Shell.which($0) }
        let installed = path != nil || cliPath != nil
        return ToolDescriptor(
            id: id,
            name: name,
            category: category,
            state: installed ? .installed : .missing,
            location: path ?? cliPath,
            version: installed ? versionCommand.flatMap { Shell.capture($0) } : nil
        )
    }

    private static func cli(
        _ id: ToolID,
        _ name: String,
        _ category: ToolCategory,
        executable: String,
        versionCommand: String
    ) -> ToolDescriptor {
        let path = Shell.which(executable)
        return ToolDescriptor(
            id: id,
            name: name,
            category: category,
            state: path == nil ? .missing : .installed,
            location: path,
            version: path == nil ? nil : Shell.capture(versionCommand)
        )
    }

    private static func fileOrCLI(
        _ id: ToolID,
        _ name: String,
        _ category: ToolCategory,
        file: String,
        executable: String,
        versionCommand: String
    ) -> ToolDescriptor {
        let direct = FileManager.default.fileExists(atPath: file) ? file : nil
        let path = direct ?? Shell.which(executable)
        let quoted = path.map(Shell.shellQuote)
        let version = path == nil ? nil : Shell.capture(
            executable == "emulator" && quoted != nil
                ? "\(quoted!) -version | head -1"
                : versionCommand
        )
        return ToolDescriptor(
            id: id,
            name: name,
            category: category,
            state: path == nil ? .missing : .installed,
            location: path,
            version: version
        )
    }

    private static func unrealDescriptor() -> ToolDescriptor {
        let manager = FileManager.default
        let root = "/Users/Shared/Epic Games"
        var location: String?

        if let entries = try? manager.contentsOfDirectory(atPath: root),
           let engine = entries.filter({ $0.hasPrefix("UE_") }).sorted().last {
            location = "\(root)/\(engine)"
        } else if manager.fileExists(atPath: "/Applications/Epic Games Launcher.app") {
            location = "/Applications/Epic Games Launcher.app"
        }

        return ToolDescriptor(
            id: .unreal,
            name: "Unreal Engine",
            category: .engine3D,
            state: location == nil ? .missing : .installed,
            location: location,
            version: location?.split(separator: "/").last.map(String.init)
        )
    }
}
