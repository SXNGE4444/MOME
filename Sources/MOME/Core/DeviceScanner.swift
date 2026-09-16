import Foundation

enum DeviceScanner {
    static func scanAll() async -> [DeviceInfo] {
        await Task.detached(priority: .utility) {
            scanIOS() + scanAndroid()
        }.value
    }

    private static func scanIOS() -> [DeviceInfo] {
        guard let raw = Shell.capture("xcrun simctl list devices available -j"),
              let data = raw.data(using: .utf8),
              let payload = try? JSONDecoder().decode(SimctlPayload.self, from: data) else {
            return []
        }

        return payload.devices.flatMap { runtime, devices in
            devices.map {
                DeviceInfo(
                    id: $0.udid,
                    name: $0.name,
                    platform: .iOS,
                    state: $0.state,
                    runtime: runtime
                        .replacingOccurrences(of: "com.apple.CoreSimulator.SimRuntime.", with: "")
                        .replacingOccurrences(of: "-", with: " "),
                    virtual: true
                )
            }
        }
        .sorted {
            if $0.isBooted != $1.isBooted { return $0.isBooted }
            return $0.name < $1.name
        }
    }

    private static func scanAndroid() -> [DeviceInfo] {
        guard let adb = androidBinary(relative: "platform-tools/adb", fallback: "adb") else {
            return scanAVDDefinitions(runningNames: [])
        }

        var devices: [DeviceInfo] = []
        var runningAVDs = Set<String>()
        let adbQ = Shell.shellQuote(adb)

        if let raw = Shell.capture("\(adbQ) devices") {
            for line in raw.split(separator: "\n").dropFirst() {
                let parts = line.split(whereSeparator: { $0 == "\t" || $0 == " " })
                guard parts.count >= 2 else { continue }
                let serial = String(parts[0])
                let state = String(parts[1])
                let emulator = serial.hasPrefix("emulator-")
                var displayName = serial
                var runtime: String? = emulator ? "Android Emulator" : "Android Device"

                if emulator,
                   let avdRaw = Shell.capture("\(adbQ) -s \(Shell.shellQuote(serial)) emu avd name | head -1"),
                   !avdRaw.isEmpty {
                    displayName = avdRaw
                    runningAVDs.insert(avdRaw)
                } else if !emulator,
                          let model = Shell.capture("\(adbQ) -s \(Shell.shellQuote(serial)) shell getprop ro.product.model") {
                    displayName = model.isEmpty ? serial : model
                    runtime = Shell.capture("\(adbQ) -s \(Shell.shellQuote(serial)) shell getprop ro.build.version.release")
                        .map { "Android \($0)" }
                }

                devices.append(DeviceInfo(
                    id: serial,
                    name: displayName,
                    platform: .android,
                    state: state,
                    runtime: runtime,
                    virtual: emulator
                ))
            }
        }

        devices += scanAVDDefinitions(runningNames: runningAVDs)
        return devices.sorted {
            if $0.isBooted != $1.isBooted { return $0.isBooted }
            return $0.name < $1.name
        }
    }

    private static func scanAVDDefinitions(runningNames: Set<String>) -> [DeviceInfo] {
        guard let emulator = androidBinary(relative: "emulator/emulator", fallback: "emulator"),
              let raw = Shell.capture("\(Shell.shellQuote(emulator)) -list-avds") else { return [] }

        return raw.split(separator: "\n").compactMap { value in
            let name = String(value).trimmingCharacters(in: .whitespacesAndNewlines)
            guard !name.isEmpty, !runningNames.contains(name) else { return nil }
            return DeviceInfo(
                id: "avd:\(name)",
                name: name,
                platform: .android,
                state: "Shutdown",
                runtime: "Android Virtual Device",
                virtual: true
            )
        }
    }

    static func androidBinary(relative: String, fallback: String) -> String? {
        if let direct = Shell.which(fallback) { return direct }
        let environment = ProcessInfo.processInfo.environment
        let candidates = [
            environment["ANDROID_HOME"],
            environment["ANDROID_SDK_ROOT"],
            FileManager.default.homeDirectoryForCurrentUser
                .appendingPathComponent("Library/Android/sdk").path
        ].compactMap { $0 }

        for root in candidates {
            let path = URL(fileURLWithPath: root).appendingPathComponent(relative).path
            if FileManager.default.isExecutableFile(atPath: path) { return path }
        }
        return nil
    }
}

private struct SimctlPayload: Decodable {
    let devices: [String: [SimctlDevice]]
}

private struct SimctlDevice: Decodable {
    let state: String
    let name: String
    let udid: String
}
