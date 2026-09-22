import SwiftUI

struct RootView: View {
    @EnvironmentObject private var model: AppModel

    var body: some View {
        NavigationSplitView {
            SidebarView()
                .navigationSplitViewColumnWidth(min: 210, ideal: 230, max: 270)
        } detail: {
            Group {
                switch model.section {
                case .dashboard: DashboardView()
                case .projects: ProjectsView()
                case .workspaces: WorkspacesView()
                case .inbox: UnifiedInboxView()
                case .automations: AutomationsHubView()
                case .agents: AgentsHubView()
                case .services: ServiceIntegrationsView()
                case .revenue: RevenueIntelligenceView()
                case .roadmap: CommunityRoadmapView()
                case .plan: PlanView()
                case .terminal: TerminalView()
                case .devices: DevicesView()
                case .tools: ToolsView()
                case .ai: AIView()
                case .deploy: DeploymentsView()
                case .learn: LearnView()
                }
            }
        }
        .sheet(isPresented: $model.isCommandPalettePresented) {
            CommandPaletteView()
                .environmentObject(model)
                .environmentObject(model.workspace)
                .environmentObject(model.processes)
        }
        .alert(item: $model.pendingApproval) { pending in
            Alert(
                title: Text("Approve \(pending.action.risk.rawValue.capitalized) Action?"),
                message: Text(approvalMessage(for: pending)),
                primaryButton: .destructive(Text("Approve")) {
                    model.approvePendingAction()
                },
                secondaryButton: .cancel()
            )
        }
    }

    private func approvalMessage(for pending: PendingAction) -> String {
        var message = pending.action.command
        if let project = pending.project {
            message += "\n\nProject: \(project.name)"
        }
        if let help = pending.action.help {
            message += "\n\n\(help)"
        }
        return message
    }
}

private struct SidebarView: View {
    @EnvironmentObject private var model: AppModel

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.primary)
                        .frame(width: 34, height: 34)
                    Text("M")
                        .font(.headline.weight(.black))
                        .foregroundStyle(Color(nsColor: .windowBackgroundColor))
                }
                VStack(alignment: .leading, spacing: 1) {
                    Text("MOME").font(.headline.weight(.bold))
                    Text("Developer Command Center").font(.caption2).foregroundStyle(.secondary)
                }
                Spacer()
            }
            .padding(16)

            List(SidebarSection.allCases, selection: $model.section) { item in
                Label(item.rawValue, systemImage: item.symbol)
                    .tag(item)
            }
            .listStyle(.sidebar)

            VStack(spacing: 10) {
                Button {
                    model.isSetupPresented = true
                } label: {
                    Label("Guided Setup", systemImage: "wand.and.stars")
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .buttonStyle(.plain)

                HStack {
                    StatusDot(active: model.tools.contains(where: { $0.isInstalled }))
                    Text(model.isScanning ? "Scanning environment…" : "Local system connected")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                }
            }
            .padding(16)
        }
    }
}
