import Foundation

protocol MOMEAdapter {
    var id: ToolID { get }
    var name: String { get }
    func supports(_ project: MOMEProject) -> Bool
    func actions(for project: MOMEProject) -> [ToolAction]
}

struct AdapterRegistry {
    static let all: [any MOMEAdapter] = [
        XcodeAdapter(),
        VSCodeAdapter(),
        AndroidStudioAdapter(),
        ExpoAdapter(),
        BlenderAdapter(),
        UnityAdapter(),
        UnrealAdapter(),
        GitAdapter(),
        GitHubAdapter(),
        SupabaseAdapter(),
        CloudflareAdapter(),
        VercelAdapter()
    ]

    static func actions(for project: MOMEProject) -> [ToolAction] {
        var actions = all
            .filter { $0.supports(project) }
            .flatMap { $0.actions(for: project) }

        actions += project.commands.sorted(by: { $0.key < $1.key }).map { name, command in
            ToolAction(
                title: name.capitalized,
                command: command,
                risk: .safe,
                symbol: "play.circle",
                help: "Custom command declared by this project's forge.json."
            )
        }
        return actions
    }
}

struct XcodeAdapter: MOMEAdapter {
    let id: ToolID = .xcode
    let name = "Xcode"

    func supports(_ project: MOMEProject) -> Bool {
        project.kind == .nativeMac || ProjectProbe.hasDirectory("ios", in: project) || ProjectProbe.hasSuffix(".xcodeproj", in: project) || ProjectProbe.hasSuffix(".xcworkspace", in: project)
    }

    func actions(for project: MOMEProject) -> [ToolAction] {
        let invocation = xcodeInvocation(project)
        var actions = [
            ToolAction(title: "Open in Xcode", command: "open -a Xcode .", risk: .read, tool: id, symbol: "hammer", help: "Open this project in Xcode."),
            ToolAction(title: "Inspect Xcode Project", command: "xcodebuild \(invocation) -list", risk: .read, tool: id, symbol: "list.bullet", help: "List Xcode targets, build configurations and shared schemes.")
        ]

        if let scheme = project.setting("ios.scheme") ?? project.setting("xcode.scheme") {
            let schemeArg = "-scheme \(Shell.shellQuote(scheme))"
            let destination = project.setting("ios.destination").map { "-destination \(Shell.shellQuote($0))" } ?? ""
            actions.append(ToolAction(
                title: "Build Xcode",
                command: "xcodebuild \(invocation) \(schemeArg) \(destination) build",
                risk: .safe,
                tool: id,
                symbol: "hammer.fill",
                help: "Compile the configured Xcode scheme. Add ios.destination in forge.json when a specific simulator/device is required."
            ))
            actions.append(ToolAction(
                title: "Run Xcode Tests",
                command: "xcodebuild \(invocation) \(schemeArg) \(destination) test",
                risk: .safe,
                tool: id,
                symbol: "checkmark.circle",
                help: "Run tests for the configured shared scheme."
            ))

            let archivePath = project.setting("ios.archivePath") ?? "build/mome/\(project.name).xcarchive"
            actions.append(ToolAction(
                title: "Archive iOS",
                command: "mkdir -p build/mome && xcodebuild \(invocation) \(schemeArg) -configuration Release -archivePath \(Shell.shellQuote(archivePath)) archive",
                risk: .write,
                tool: id,
                symbol: "archivebox",
                help: "Create a signed Release archive. Xcode signing must already be valid for the scheme."
            ))

            if let exportPlist = project.setting("ios.exportOptionsPlist") {
                let exportPath = project.setting("ios.exportPath") ?? "build/mome/export"
                actions.append(ToolAction(
                    title: "Export IPA",
                    command: "xcodebuild -exportArchive -archivePath \(Shell.shellQuote(archivePath)) -exportPath \(Shell.shellQuote(exportPath)) -exportOptionsPlist \(Shell.shellQuote(exportPlist))",
                    risk: .write,
                    tool: id,
                    symbol: "shippingbox",
                    help: "Export the archive using your ExportOptions.plist."
                ))
            }
        }

        if let ipa = project.setting("ios.ipaPath") {
            let command = "IPA=\(Shell.shellQuote(ipa)); test -f \"$IPA\" || { echo \"IPA not found: $IPA\"; exit 2; }; test -n \"$MOME_ASC_KEY_ID\" || { echo \"App Store Connect Key ID is not configured in MOME.\"; exit 2; }; test -n \"$MOME_ASC_ISSUER_ID\" || { echo \"App Store Connect Issuer ID is not configured in MOME.\"; exit 2; }; if xcrun iTMSTransporter -help >/dev/null 2>&1; then xcrun iTMSTransporter -m upload -assetFile \"$IPA\" -apiKey \"$MOME_ASC_KEY_ID\" -apiIssuer \"$MOME_ASC_ISSUER_ID\"; else xcrun altool --upload-app -f \"$IPA\" -t ios --apiKey \"$MOME_ASC_KEY_ID\" --apiIssuer \"$MOME_ASC_ISSUER_ID\"; fi"
            actions.append(ToolAction(
                title: "Upload to TestFlight",
                command: command,
                risk: .release,
                tool: id,
                symbol: "paperplane",
                help: "Upload the configured IPA with App Store Connect API credentials. The AuthKey_<KEYID>.p8 private key must be installed in an Apple-supported private_keys directory.",
                secretBindings: [
                    SecretBinding(environmentVariable: "MOME_ASC_KEY_ID", keychainAccount: "appstore.keyID"),
                    SecretBinding(environmentVariable: "MOME_ASC_ISSUER_ID", keychainAccount: "appstore.issuerID")
                ]
            ))
        }

        return actions
    }

    private func xcodeInvocation(_ project: MOMEProject) -> String {
        if let workspace = project.setting("ios.workspace") ?? project.setting("xcode.workspace") {
            return "-workspace \(Shell.shellQuote(workspace))"
        }
        if let xcodeProject = project.setting("ios.project") ?? project.setting("xcode.project") {
            return "-project \(Shell.shellQuote(xcodeProject))"
        }
        if ProjectProbe.hasDirectory("ios", in: project) {
            return "-project \(Shell.shellQuote("ios"))"
        }
        return ""
    }
}

struct VSCodeAdapter: MOMEAdapter {
    let id: ToolID = .vscode
    let name = "VS Code"
    func supports(_ project: MOMEProject) -> Bool { true }
    func actions(for project: MOMEProject) -> [ToolAction] {
        [ToolAction(title: "Open in VS Code", command: "code .", risk: .read, tool: id, symbol: "chevron.left.forwardslash.chevron.right", help: "Open this folder in Visual Studio Code.")]
    }
}

struct AndroidStudioAdapter: MOMEAdapter {
    let id: ToolID = .androidStudio
    let name = "Android Studio"

    func supports(_ project: MOMEProject) -> Bool {
        ProjectProbe.hasDirectory("android", in: project) || ProjectProbe.hasFile("gradlew", in: project) || ProjectProbe.hasFile("build.gradle", in: project)
    }

    func actions(for project: MOMEProject) -> [ToolAction] {
        let gradle = ProjectProbe.hasFile("gradlew", in: project) ? "./gradlew" : "cd android && ./gradlew"
        var actions = [
            ToolAction(title: "Open Android Studio", command: "open -a 'Android Studio' .", risk: .read, tool: id, symbol: "apps.iphone", help: "Open this project in Android Studio."),
            ToolAction(title: "Build Debug APK", command: "\(gradle) assembleDebug", risk: .safe, tool: id, symbol: "shippingbox", help: "Compile a debug APK with Gradle."),
            ToolAction(title: "Build Release AAB", command: "\(gradle) bundleRelease", risk: .write, tool: id, symbol: "shippingbox.fill", help: "Compile a release Android App Bundle. Signing configuration must already be valid.")
        ]

        if let package = project.setting("android.package"),
           let aab = project.setting("android.aabPath"),
           let jsonKey = project.setting("android.playJsonKey") {
            let track = project.setting("android.playTrack") ?? "internal"
            actions.append(ToolAction(
                title: "Upload to Play Console",
                command: "fastlane supply --aab \(Shell.shellQuote(aab)) --package_name \(Shell.shellQuote(package)) --track \(Shell.shellQuote(track)) --json_key \(Shell.shellQuote(jsonKey))",
                risk: .release,
                tool: .fastlane,
                symbol: "paperplane",
                help: "Upload the configured AAB to Google Play with fastlane supply. android.playJsonKey should point to your local Google Play service-account JSON file."
            ))
        }
        return actions
    }
}

struct ExpoAdapter: MOMEAdapter {
    let id: ToolID = .node
    let name = "Expo / EAS"

    func supports(_ project: MOMEProject) -> Bool {
        ProjectProbe.packageContains("expo", in: project) || ProjectProbe.hasFile("app.json", in: project) || ProjectProbe.hasFile("eas.json", in: project)
    }

    func actions(for project: MOMEProject) -> [ToolAction] {
        var actions = [
            ToolAction(title: "Expo Start", command: "npx expo start", risk: .safe, tool: .node, symbol: "play.rectangle", help: "Start the Expo development server."),
            ToolAction(title: "Expo iOS", command: "npx expo run:ios", risk: .write, tool: .xcode, symbol: "iphone", help: "Generate/build the native iOS project and run it."),
            ToolAction(title: "Expo Android", command: "npx expo run:android", risk: .write, tool: .androidStudio, symbol: "apps.iphone", help: "Generate/build the native Android project and run it.")
        ]
        if ProjectProbe.hasFile("eas.json", in: project) {
            actions += [
                ToolAction(title: "EAS Build iOS", command: "eas build --platform ios", risk: .write, tool: .eas, symbol: "hammer", help: "Start an EAS iOS cloud build using eas.json."),
                ToolAction(title: "EAS Build Android", command: "eas build --platform android", risk: .write, tool: .eas, symbol: "hammer", help: "Start an EAS Android cloud build using eas.json."),
                ToolAction(title: "EAS Submit iOS", command: "eas submit --platform ios --latest", risk: .release, tool: .eas, symbol: "paperplane", help: "Submit the latest successful EAS iOS build."),
                ToolAction(title: "EAS Submit Android", command: "eas submit --platform android --latest", risk: .release, tool: .eas, symbol: "paperplane", help: "Submit the latest successful EAS Android build.")
            ]
        }
        return actions
    }
}

struct BlenderAdapter: MOMEAdapter {
    let id: ToolID = .blender
    let name = "Blender"

    func supports(_ project: MOMEProject) -> Bool {
        project.kind == .threeD || ProjectProbe.hasSuffix(".blend", in: project)
    }

    func actions(for project: MOMEProject) -> [ToolAction] {
        let configured = project.setting("blender.file")
        let fileExpression = configured.map(Shell.shellQuote) ?? "\"$(find . -maxdepth 3 -name '*.blend' -print -quit)\""
        return [
            ToolAction(title: "Open Blender Project", command: "BLEND=\(fileExpression); test -n \"$BLEND\" || { echo 'No .blend file found'; exit 2; }; open -a Blender \"$BLEND\"", risk: .read, tool: id, symbol: "cube", help: "Open the configured or first discovered .blend file."),
            ToolAction(title: "Render Frame", command: "BLEND=\(fileExpression); test -n \"$BLEND\" || { echo 'No .blend file found'; exit 2; }; blender -b \"$BLEND\" -f \(project.setting("blender.frame") ?? "1")", risk: .safe, tool: id, symbol: "photo", help: "Render one frame headlessly with the scene's configured render engine and output settings."),
            ToolAction(title: "Render Animation", command: "BLEND=\(fileExpression); test -n \"$BLEND\" || { echo 'No .blend file found'; exit 2; }; blender -b \"$BLEND\" -a", risk: .write, tool: id, symbol: "film", help: "Render the complete configured animation headlessly.")
        ]
    }
}

struct UnityAdapter: MOMEAdapter {
    let id: ToolID = .unity
    let name = "Unity"

    func supports(_ project: MOMEProject) -> Bool {
        ProjectProbe.hasDirectory("Assets", in: project) && ProjectProbe.hasDirectory("ProjectSettings", in: project)
    }

    func actions(for project: MOMEProject) -> [ToolAction] {
        let unity = "UNITY=$(find /Applications/Unity/Hub/Editor -path '*/Unity.app/Contents/MacOS/Unity' -type f 2>/dev/null | sort | tail -1); test -x \"$UNITY\" || { echo 'Unity Editor executable not found'; exit 2; };"
        var actions = [
            ToolAction(title: "Open Unity Project", command: "open -a 'Unity Hub' .", risk: .read, tool: id, symbol: "cube.transparent", help: "Open the current project through Unity Hub."),
            ToolAction(title: "Run Unity Tests", command: "\(unity) \"$UNITY\" -batchmode -projectPath \"$PWD\" -runTests -testPlatform EditMode -testResults build/mome/unity-tests.xml -quit -logFile -", risk: .safe, tool: id, symbol: "checkmark.circle", help: "Run Unity EditMode tests in batch mode and stream the editor log.")
        ]
        if let method = project.setting("unity.buildMethod") {
            actions.append(ToolAction(title: "Unity Batch Build", command: "\(unity) \"$UNITY\" -batchmode -projectPath \"$PWD\" -executeMethod \(Shell.shellQuote(method)) -quit -logFile -", risk: .write, tool: id, symbol: "shippingbox", help: "Invoke the configured static Unity build method. Define unity.buildMethod in forge.json."))
        }
        return actions
    }
}

struct UnrealAdapter: MOMEAdapter {
    let id: ToolID = .unreal
    let name = "Unreal Engine"

    func supports(_ project: MOMEProject) -> Bool { ProjectProbe.hasSuffix(".uproject", in: project) }

    func actions(for project: MOMEProject) -> [ToolAction] {
        let projectFile = project.setting("unreal.project") ?? "$(find . -maxdepth 2 -name '*.uproject' -print -quit)"
        let engine = "ENGINE=$(find '/Users/Shared/Epic Games' -maxdepth 1 -type d -name 'UE_*' 2>/dev/null | sort | tail -1); test -d \"$ENGINE\" || { echo 'Unreal Engine installation not found'; exit 2; };"
        return [
            ToolAction(title: "Open Unreal Project", command: "UPROJECT=\"\(projectFile)\"; test -f \"$UPROJECT\" || { echo 'No .uproject found'; exit 2; }; open \"$UPROJECT\"", risk: .read, tool: id, symbol: "gamecontroller", help: "Open the configured or first discovered Unreal project."),
            ToolAction(title: "Package Unreal for Mac", command: "\(engine) UPROJECT=\"\(projectFile)\"; \"$ENGINE/Engine/Build/BatchFiles/RunUAT.sh\" BuildCookRun -project=\"$PWD/${UPROJECT#./}\" -platform=Mac -clientconfig=Development -build -cook -stage -pak -archive -archivedirectory=\"$PWD/build/mome/unreal\"", risk: .write, tool: id, symbol: "shippingbox", help: "Build, cook, stage and archive a Development package for macOS with Unreal AutomationTool.")
        ]
    }
}

struct GitAdapter: MOMEAdapter {
    let id: ToolID = .git
    let name = "Git"
    func supports(_ project: MOMEProject) -> Bool { ProjectProbe.hasDirectory(".git", in: project) }
    func actions(for project: MOMEProject) -> [ToolAction] {
        [
            ToolAction(title: "Git Status", command: "git status --short --branch", risk: .read, tool: id, symbol: "arrow.triangle.branch", help: "Show branch and working-tree changes."),
            ToolAction(title: "Git Fetch", command: "git fetch --all --prune", risk: .safe, tool: id, symbol: "arrow.down.circle", help: "Fetch remote branches without modifying your working tree."),
            ToolAction(title: "Git Pull", command: "git pull --ff-only", risk: .write, tool: id, symbol: "arrow.down.circle.fill", help: "Fast-forward the current branch only; MOME will not create an automatic merge commit.")
        ]
    }
}

struct GitHubAdapter: MOMEAdapter {
    let id: ToolID = .github
    let name = "GitHub"
    func supports(_ project: MOMEProject) -> Bool { ProjectProbe.hasDirectory(".git", in: project) || project.repository != nil }
    func actions(for project: MOMEProject) -> [ToolAction] {
        [
            ToolAction(title: "GitHub PRs", command: "gh pr list", risk: .read, tool: id, symbol: "arrow.triangle.pull", help: "List pull requests for this repository."),
            ToolAction(title: "GitHub Actions", command: "gh run list --limit 20", risk: .read, tool: id, symbol: "bolt", help: "List recent GitHub Actions workflow runs."),
            ToolAction(title: "Watch Latest Workflow", command: "RUN=$(gh run list --limit 1 --json databaseId --jq '.[0].databaseId'); test -n \"$RUN\" && gh run watch \"$RUN\"", risk: .read, tool: id, symbol: "eye", help: "Follow the newest workflow run until it completes.")
        ]
    }
}

struct SupabaseAdapter: MOMEAdapter {
    let id: ToolID = .supabase
    let name = "Supabase"
    func supports(_ project: MOMEProject) -> Bool { ProjectProbe.hasDirectory("supabase", in: project) }
    func actions(for project: MOMEProject) -> [ToolAction] {
        [
            ToolAction(title: "Supabase Status", command: "supabase status", risk: .read, tool: id, symbol: "server.rack", help: "Show local Supabase service URLs and status."),
            ToolAction(title: "Supabase Start", command: "supabase start", risk: .safe, tool: id, symbol: "play.fill", help: "Start the local Supabase development stack."),
            ToolAction(title: "Supabase Functions", command: "supabase functions serve", risk: .safe, tool: id, symbol: "function", help: "Serve local Supabase Edge Functions."),
            ToolAction(title: "Supabase DB Push", command: "supabase db push", risk: .release, tool: id, symbol: "arrow.up.circle", help: "Push local migrations to the linked remote database."),
            ToolAction(title: "Reset Local Database", command: "supabase db reset", risk: .dangerous, tool: id, symbol: "trash", help: "Destroy and rebuild the LOCAL database from migrations and seed files.")
        ]
    }
}

struct CloudflareAdapter: MOMEAdapter {
    let id: ToolID = .wrangler
    let name = "Cloudflare"
    func supports(_ project: MOMEProject) -> Bool {
        ProjectProbe.hasFile("wrangler.toml", in: project) || ProjectProbe.hasFile("wrangler.json", in: project) || ProjectProbe.hasFile("wrangler.jsonc", in: project) || project.deployment.values.contains(where: { $0.lowercased().contains("cloudflare") })
    }
    func actions(for project: MOMEProject) -> [ToolAction] {
        [
            ToolAction(title: "Cloudflare Who Am I", command: "wrangler whoami", risk: .read, tool: id, symbol: "person.crop.circle", help: "Verify the Cloudflare account currently authenticated by Wrangler."),
            ToolAction(title: "Cloudflare Dev", command: "wrangler dev", risk: .safe, tool: id, symbol: "cloud", help: "Start the project's Cloudflare local development runtime."),
            ToolAction(title: "Deploy Cloudflare", command: "wrangler deploy", risk: .release, tool: id, symbol: "cloud.upload", help: "Deploy the current Cloudflare Worker configuration to the configured account/environment.")
        ]
    }
}

struct VercelAdapter: MOMEAdapter {
    let id: ToolID = .vercel
    let name = "Vercel"
    func supports(_ project: MOMEProject) -> Bool {
        ProjectProbe.hasDirectory(".vercel", in: project) || ProjectProbe.hasFile("vercel.json", in: project) || project.deployment.values.contains(where: { $0.lowercased().contains("vercel") })
    }
    func actions(for project: MOMEProject) -> [ToolAction] {
        [
            ToolAction(title: "Vercel Who Am I", command: "vercel whoami", risk: .read, tool: id, symbol: "person.crop.circle", help: "Verify the Vercel account currently authenticated by the CLI."),
            ToolAction(title: "Vercel Dev", command: "vercel dev", risk: .safe, tool: id, symbol: "play.rectangle", help: "Run the Vercel project locally."),
            ToolAction(title: "Deploy Vercel Preview", command: "vercel", risk: .write, tool: id, symbol: "arrow.up.right", help: "Create a preview deployment."),
            ToolAction(title: "Deploy Vercel Production", command: "vercel --prod", risk: .release, tool: id, symbol: "bolt.horizontal.circle", help: "Deploy the current project to its Vercel production target.")
        ]
    }
}

private enum ProjectProbe {
    static func hasFile(_ relative: String, in project: MOMEProject) -> Bool {
        FileManager.default.fileExists(atPath: project.folderURL.appendingPathComponent(relative).path)
    }

    static func hasDirectory(_ relative: String, in project: MOMEProject) -> Bool {
        var isDirectory: ObjCBool = false
        let exists = FileManager.default.fileExists(atPath: project.folderURL.appendingPathComponent(relative).path, isDirectory: &isDirectory)
        return exists && isDirectory.boolValue
    }

    static func hasSuffix(_ suffix: String, in project: MOMEProject) -> Bool {
        guard let enumerator = FileManager.default.enumerator(at: project.folderURL, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles, .skipsPackageDescendants]) else { return false }
        var checked = 0
        for case let url as URL in enumerator {
            checked += 1
            if url.lastPathComponent.hasSuffix(suffix) { return true }
            if checked > 500 { break }
        }
        return false
    }

    static func packageContains(_ needle: String, in project: MOMEProject) -> Bool {
        let url = project.folderURL.appendingPathComponent("package.json")
        guard let data = try? Data(contentsOf: url), let text = String(data: data, encoding: .utf8) else { return false }
        return text.localizedCaseInsensitiveContains(needle)
    }
}
