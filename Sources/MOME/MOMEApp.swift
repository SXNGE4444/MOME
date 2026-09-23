import SwiftUI
import Combine

@main
struct MOMEApp: App {
    @StateObject private var model = AppModel()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(model)
                .environmentObject(model.workspace)
                .environmentObject(model.processes)
                .environmentObject(model.nausicaa)
                .frame(minWidth: 1120, minHeight: 720)
                .task {
                    await model.initialise()
                }
                .sheet(isPresented: $model.isSetupPresented) {
                    SetupAssistantView()
                        .environmentObject(model)
                        .environmentObject(model.workspace)
                        .frame(minWidth: 760, minHeight: 600)
                }
                .sheet(isPresented: $model.isGuidePresented) {
                    GuideLibraryView()
                        .environmentObject(model)
                        .environmentObject(model.workspace)
                        .frame(minWidth: 880, minHeight: 650)
                }
        }
        .windowStyle(.hiddenTitleBar)
        .commands {
            CommandMenu("MOME") {
                Button("Command Palette") {
                    model.isCommandPalettePresented = true
                }
                .keyboardShortcut("k", modifiers: [.command])

                Button("Rescan Developer Environment") {
                    Task { await model.refreshEnvironment() }
                }
                .keyboardShortcut("r", modifiers: [.command, .shift])

                Divider()

                Button("Guided Setup") {
                    model.isSetupPresented = true
                }

                Button("MOME Guide") {
                    model.isGuidePresented = true
                }
                .keyboardShortcut("?", modifiers: [.command])

                Divider()

                Button("Check for Updates…") {
                    Task { await model.checkForUpdates() }
                }
            }
        }
    }
}

@MainActor
final class AppModel: ObservableObject {
    @Published var section: SidebarSection = .dashboard
    @Published var tools: [ToolDescriptor] = []
    @Published var devices: [DeviceInfo] = []
    @Published var isScanning = false
    @Published var isCommandPalettePresented = false
    @Published var isSetupPresented = false
    @Published var isGuidePresented = false
    @Published var pendingApproval: PendingAction?
    @Published var updateNotice: UpdateNotice?

    let workspace = WorkspaceStore()
    let processes = ProcessSupervisor()
    let nausicaa = NausicaaStore()
    let keychain = KeychainVault(service: "za.co.mome.devcenter")
    let ai = AIService()

    private let setupKey = "mome.setup.completed.v2"

    var displayVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "development"
    }

    func initialise() async {
        await refreshEnvironment()
        if !UserDefaults.standard.bool(forKey: setupKey) {
            isSetupPresented = true
        }
    }

    func markSetupComplete() {
        UserDefaults.standard.set(true, forKey: setupKey)
        isSetupPresented = false
    }

    func resetSetup() {
        UserDefaults.standard.removeObject(forKey: setupKey)
        isSetupPresented = true
    }

    func refreshEnvironment() async {
        isScanning = true
        async let toolScan = ToolScanner.scanAll()
        async let deviceScan = DeviceScanner.scanAll()
        tools = await toolScan
        devices = await deviceScan
        isScanning = false
    }

    func request(_ action: ToolAction, for project: MOMEProject?) {
        if action.risk.requiresApproval {
            pendingApproval = PendingAction(action: action, project: project)
        } else {
            execute(action, for: project)
        }
    }

    func approvePendingAction() {
        guard let pendingApproval else { return }
        self.pendingApproval = nil
        execute(pendingApproval.action, for: pendingApproval.project)
    }

    func execute(_ action: ToolAction, for project: MOMEProject?) {
        let directory = project.map { URL(fileURLWithPath: $0.path) }
        var environment: [String: String] = [:]
        for binding in action.secretBindings {
            if let value = keychain.read(account: binding.keychainAccount), !value.isEmpty {
                environment[binding.environmentVariable] = value
            }
        }
        processes.start(
            title: action.title,
            command: action.command,
            workingDirectory: directory,
            risk: action.risk,
            environment: environment
        )
        section = .terminal
    }

    func checkForUpdates() async {
        do {
            updateNotice = try await ReleaseUpdateChecker.check(currentVersion: displayVersion)
        } catch {
            updateNotice = UpdateNotice(
                title: "Update Check Failed",
                message: error.localizedDescription,
                releaseURL: URL(string: "https://github.com/SXNGE4444/MOME/releases")
            )
        }
    }

    func runDeviceAction(_ action: ToolAction, project: MOMEProject?) {
        request(action, for: project)
        Task {
            try? await Task.sleep(for: .seconds(2))
            await refreshEnvironment()
        }
    }
}
