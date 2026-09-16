import Foundation

enum DeviceActions {
    static func actions(for device: DeviceInfo, project: MOMEProject?) -> [ToolAction] {
        switch device.platform {
        case .iOS:
            return iosActions(for: device, project: project)
        case .android:
            return androidActions(for: device, project: project)
        }
    }

    private static func iosActions(for device: DeviceInfo, project: MOMEProject?) -> [ToolAction] {
        let udid = Shell.shellQuote(device.id)
        var actions: [ToolAction] = []

        if device.isBooted {
            actions.append(ToolAction(
                title: "Open Simulator",
                command: "open -a Simulator",
                risk: .read,
                tool: .xcode,
                symbol: "iphone",
                help: "Bring Apple's Simulator application to the foreground."
            ))
            actions.append(ToolAction(
                title: "Shutdown",
                command: "xcrun simctl shutdown \(udid)",
                risk: .write,
                tool: .xcode,
                symbol: "power",
                help: "Shut down this simulator without erasing its data."
            ))
        } else {
            actions.append(ToolAction(
                title: "Boot",
                command: "xcrun simctl boot \(udid) 2>/dev/null || true; open -a Simulator; xcrun simctl bootstatus \(udid) -b",
                risk: .safe,
                tool: .xcode,
                symbol: "play.fill",
                help: "Boot the selected simulator and wait until iOS reports that it is ready."
            ))
        }

        actions.append(ToolAction(
            title: "Erase",
            command: "xcrun simctl shutdown \(udid) 2>/dev/null || true; xcrun simctl erase \(udid)",
            risk: .dangerous,
            tool: .xcode,
            symbol: "trash",
            help: "Erase all apps and data from this simulator."
        ))

        if let project,
           let appPath = project.setting("ios.appPath") {
            actions.append(ToolAction(
                title: "Install App",
                command: "xcrun simctl install \(udid) \(Shell.shellQuote(appPath))",
                risk: .write,
                tool: .xcode,
                symbol: "square.and.arrow.down",
                help: "Install the configured iOS .app bundle onto this simulator."
            ))
        }

        if let project,
           let bundleID = project.setting("ios.bundleId") {
            actions.append(ToolAction(
                title: "Launch App",
                command: "xcrun simctl launch \(udid) \(Shell.shellQuote(bundleID))",
                risk: .safe,
                tool: .xcode,
                symbol: "arrow.up.forward.app",
                help: "Launch the configured bundle identifier on this simulator."
            ))
        }

        return actions
    }

    private static func androidActions(for device: DeviceInfo, project: MOMEProject?) -> [ToolAction] {
        var actions: [ToolAction] = []

        if device.isAndroidAVDDefinition {
            let name = String(device.id.dropFirst(4))
            let emulatorCommand = "EMU=$(command -v emulator 2>/dev/null || true); if [ -z \"$EMU\" ]; then EMU=\"${ANDROID_HOME:-${ANDROID_SDK_ROOT:-$HOME/Library/Android/sdk}}/emulator/emulator\"; fi; \"$EMU\" -avd \(Shell.shellQuote(name))"
            actions.append(ToolAction(
                title: "Start AVD",
                command: emulatorCommand,
                risk: .safe,
                tool: .emulator,
                symbol: "play.fill",
                help: "Start this Android Virtual Device. Keep the terminal session running while the emulator is open."
            ))
            return actions
        }

        let serial = Shell.shellQuote(device.id)
        actions.append(ToolAction(
            title: "Logcat",
            command: "adb -s \(serial) logcat",
            risk: .read,
            tool: .adb,
            symbol: "doc.text.magnifyingglass",
            help: "Stream Android system and application logs from this device."
        ))

        if device.virtual {
            actions.append(ToolAction(
                title: "Stop Emulator",
                command: "adb -s \(serial) emu kill",
                risk: .write,
                tool: .adb,
                symbol: "power",
                help: "Stop this running Android emulator."
            ))
        } else {
            actions.append(ToolAction(
                title: "Reboot Device",
                command: "adb -s \(serial) reboot",
                risk: .write,
                tool: .adb,
                symbol: "arrow.clockwise",
                help: "Reboot the connected Android device."
            ))
        }

        if let project,
           let apk = project.setting("android.apkPath") {
            actions.append(ToolAction(
                title: "Install APK",
                command: "adb -s \(serial) install -r \(Shell.shellQuote(apk))",
                risk: .write,
                tool: .adb,
                symbol: "square.and.arrow.down",
                help: "Install or replace the configured APK on this device."
            ))
        }

        if let project,
           let packageName = project.setting("android.package") {
            let activity = project.setting("android.activity")
            let launch: String
            if let activity {
                launch = "adb -s \(serial) shell am start -n \(Shell.shellQuote(packageName + "/" + activity))"
            } else {
                launch = "adb -s \(serial) shell monkey -p \(Shell.shellQuote(packageName)) -c android.intent.category.LAUNCHER 1"
            }
            actions.append(ToolAction(
                title: "Launch App",
                command: launch,
                risk: .safe,
                tool: .adb,
                symbol: "arrow.up.forward.app",
                help: "Launch the configured Android package."
            ))
        }

        return actions
    }
}
