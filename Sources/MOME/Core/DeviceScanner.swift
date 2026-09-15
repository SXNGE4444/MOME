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
                    runtime: runtime.replacingOccurrences(of: "com.apple.CoreSimulator.SimRuntime.", with: "")
                        .replacingOccurrences(of: "-", with: " ")
                )
            }
        }
        .sorted { $0.name < $1.name }
    }

    private static func scanAndroid() -> [DeviceInfo] {
        guard let raw = Shell.capture("adb devices") else { return [] }
        return raw.split(separator: "\n").dropFirst().compactMap { line in
            let parts = line.split(whereSeparator: { $0 == "\t" || $0 == " " })
            guard parts.count >= 2 else { return nil }
            let id = String(parts[0])
            return DeviceInfo(id: id, name: id, platform: .android, state: String(parts[1]), runtime: nil)
        }
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
