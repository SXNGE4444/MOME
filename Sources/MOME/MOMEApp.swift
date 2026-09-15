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
                .frame(minWidth: 1120, minHeight: 720)
                .task {
                    await model.refreshEnvironment()
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
    @Published var pendingApproval: PendingAction?

    let workspace = WorkspaceStore()
    let processes = ProcessSupervisor()
    let keychain = KeychainVault(service: "za.co.mome.devcenter")
    let ai = AIService()

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
        processes.start(
            title: action.title,
            command: action.command,
            workingDirectory: directory,
            risk: action.risk
        )
        section = .terminal
    }
}
