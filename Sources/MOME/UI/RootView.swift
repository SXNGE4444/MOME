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
                case .plan: PlanView()
                case .terminal: TerminalView()
                case .devices: DevicesView()
                case .tools: ToolsView()
                case .ai: AIView()
                case .deploy: DeploymentsView()
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
                message: Text("\(pending.action.command)\n\nMOME will run this command\(pending.project.map { " in \($0.name)" } ?? "")."),
                primaryButton: .destructive(Text("Approve")) {
                    model.approvePendingAction()
                },
                secondaryButton: .cancel()
            )
        }
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

            HStack {
                StatusDot(active: model.tools.contains(where: { $0.isInstalled }))
                Text(model.isScanning ? "Scanning environment…" : "Local system connected")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
            }
            .padding(16)
        }
    }
}

struct DashboardView: View {
    @EnvironmentObject private var model: AppModel
    @EnvironmentObject private var workspace: WorkspaceStore
    @EnvironmentObject private var processes: ProcessSupervisor

    private var installedCount: Int { model.tools.filter(\.isInstalled).count }
    private var runningCount: Int { processes.sessions.filter { $0.state == .running }.count }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 5) {
                        Text("COMMAND CENTER")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                            .tracking(1.2)
                        Text("Build. Test. Ship.")
                            .font(.system(size: 34, weight: .bold, design: .rounded))
                        Text("Your Mac, projects, tools and release paths in one operational surface.")
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Button {
                        workspace.pickAndAddProject()
                    } label: {
                        Label("Add Project", systemImage: "plus")
                    }
                    .buttonStyle(.borderedProminent)
                }

                HStack(spacing: 14) {
                    MetricCard(value: "\(workspace.projects.count)", label: "Projects", symbol: "shippingbox")
                    MetricCard(value: "\(installedCount)", label: "Tools Ready", symbol: "checkmark.seal")
                    MetricCard(value: "\(runningCount)", label: "Processes", symbol: "waveform.path")
                    MetricCard(value: "\(model.devices.count)", label: "Devices", symbol: "iphone.gen3")
                }

                HStack(alignment: .top, spacing: 14) {
                    MOMECard("Recent Projects") {
                        if workspace.projects.isEmpty {
                            EmptyState(title: "No projects yet", detail: "Add a project folder and MOME will detect its stack and commands.")
                        } else {
                            ForEach(workspace.projects.prefix(5)) { project in
                                Button {
                                    model.section = .projects
                                } label: {
                                    HStack(spacing: 12) {
                                        Image(systemName: icon(for: project.kind))
                                            .frame(width: 26)
                                        VStack(alignment: .leading) {
                                            Text(project.name).fontWeight(.semibold)
                                            Text(project.kind.label + "  •  " + project.path)
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                                .lineLimit(1)
                                        }
                                        Spacer()
                                        Image(systemName: "chevron.right")
                                            .foregroundStyle(.tertiary)
                                    }
                                    .contentShape(Rectangle())
                                }
                                .buttonStyle(.plain)
                                if project.id != workspace.projects.prefix(5).last?.id { Divider() }
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)

                    MOMECard("Live Activity") {
                        if processes.sessions.isEmpty {
                            EmptyState(title: "Nothing running", detail: "Commands, builds and deployments will stream here.")
                        } else {
                            ForEach(processes.sessions.prefix(5)) { session in
                                HStack {
                                    StatusDot(active: session.state == .running)
                                    VStack(alignment: .leading) {
                                        Text(session.title).fontWeight(.medium)
                                        Text(session.command).font(.caption.monospaced()).foregroundStyle(.secondary).lineLimit(1)
                                    }
                                    Spacer()
                                    Text(session.state.rawValue.uppercased())
                                        .font(.caption2.monospaced())
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)
                }

                MOMECard("Environment") {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 170), spacing: 10)], spacing: 10) {
                        ForEach(model.tools.prefix(12)) { tool in
                            HStack(spacing: 9) {
                                StatusDot(active: tool.isInstalled)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(tool.name).font(.subheadline.weight(.medium))
                                    Text(tool.version ?? (tool.isInstalled ? "Ready" : "Not detected"))
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                        .lineLimit(1)
                                }
                                Spacer()
                            }
                            .padding(10)
                            .background(Color.primary.opacity(0.035), in: RoundedRectangle(cornerRadius: 10))
                        }
                    }
                }
            }
        }
        .momePage()
    }
}

private struct MetricCard: View {
    let value: String
    let label: String
    let symbol: String

    var body: some View {
        MOMECard {
            HStack {
                VStack(alignment: .leading, spacing: 5) {
                    Text(value).font(.system(size: 28, weight: .bold, design: .rounded))
                    Text(label).font(.caption).foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: symbol).font(.title2).foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
    }
}

struct ProjectsView: View {
    @EnvironmentObject private var model: AppModel
    @EnvironmentObject private var workspace: WorkspaceStore
    @State private var selectedID: UUID?

    var body: some View {
        HStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("PROJECTS").font(.caption.weight(.bold)).foregroundStyle(.secondary)
                    Spacer()
                    Button { workspace.pickAndAddProject() } label: { Image(systemName: "plus") }
                }
                .padding(.horizontal, 14)
                .padding(.top, 14)

                List(workspace.projects, selection: $selectedID) { project in
                    VStack(alignment: .leading, spacing: 3) {
                        Text(project.name).fontWeight(.semibold)
                        Text(project.kind.label).font(.caption).foregroundStyle(.secondary)
                    }
                    .tag(project.id)
                }
                .listStyle(.sidebar)
            }
            .frame(width: 250)

            Divider()

            if let project = workspace.project(selectedID) ?? workspace.projects.first {
                ProjectDetailView(project: project)
            } else {
                EmptyState(title: "Add your first project", detail: "MOME will turn the folder into a command surface for its editor, build, device and deployment tools.")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .background(Color(nsColor: .windowBackgroundColor))
    }
}

private struct ProjectDetailView: View {
    @EnvironmentObject private var model: AppModel
    let project: MOMEProject

    private var actions: [ToolAction] { AdapterRegistry.actions(for: project) }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                HStack {
                    VStack(alignment: .leading, spacing: 5) {
                        Text(project.kind.label.uppercased()).font(.caption.weight(.bold)).foregroundStyle(.secondary)
                        Text(project.name).font(.largeTitle.weight(.bold))
                        Text(project.path).font(.caption.monospaced()).foregroundStyle(.secondary).textSelection(.enabled)
                    }
                    Spacer()
                    Button("Reveal in Finder") {
                        NSWorkspace.shared.activateFileViewerSelecting([project.folderURL])
                    }
                }

                MOMECard("Run / Build / Open") {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 190), spacing: 10)], spacing: 10) {
                        ForEach(actions) { action in
                            Button {
                                model.request(action, for: project)
                            } label: {
                                HStack {
                                    Image(systemName: action.symbol)
                                    Text(action.title).lineLimit(1)
                                    Spacer()
                                    RiskBadge(risk: action.risk)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 6)
                            }
                            .buttonStyle(.bordered)
                        }
                    }
                }

                HStack(alignment: .top, spacing: 14) {
                    MOMECard("Repository") {
                        Text(project.repository ?? "No repository declared")
                            .font(.callout.monospaced())
                            .foregroundStyle(project.repository == nil ? .secondary : .primary)
                            .textSelection(.enabled)
                    }
                    .frame(maxWidth: .infinity)

                    MOMECard("Release Paths") {
                        if project.deployment.isEmpty {
                            Text("No deployment targets declared in forge.json")
                                .foregroundStyle(.secondary)
                        } else {
                            ForEach(project.deployment.sorted(by: { $0.key < $1.key }), id: \.key) { key, value in
                                HStack { Text(key.capitalized); Spacer(); Text(value).foregroundStyle(.secondary) }
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .momePage()
    }
}

struct PlanView: View {
    @EnvironmentObject private var workspace: WorkspaceStore
    @State private var projectID: UUID?
    @State private var title = ""
    @State private var kind: TaskKind = .engineering

    private var project: MOMEProject? { workspace.project(projectID) ?? workspace.projects.first }

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack {
                VStack(alignment: .leading) {
                    Text("PLAN").font(.caption.weight(.bold)).foregroundStyle(.secondary)
                    Text("Product → Build → Release").font(.title.weight(.bold))
                }
                Spacer()
                Picker("Project", selection: $projectID) {
                    Text("Select project").tag(nil as UUID?)
                    ForEach(workspace.projects) { p in Text(p.name).tag(Optional(p.id)) }
                }
                .frame(width: 220)
            }

            if let project {
                HStack {
                    TextField("Add a task, content item, build step…", text: $title)
                    Picker("Kind", selection: $kind) {
                        ForEach(TaskKind.allCases) { Text($0.rawValue.capitalized).tag($0) }
                    }
                    .frame(width: 150)
                    Button("Add") {
                        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
                        guard !trimmed.isEmpty else { return }
                        workspace.addTask(projectID: project.id, title: trimmed, kind: kind)
                        title = ""
                    }
                    .buttonStyle(.borderedProminent)
                }

                ScrollView(.horizontal) {
                    HStack(alignment: .top, spacing: 12) {
                        ForEach(TaskStage.allCases) { stage in
                            MOMECard(stage.label) {
                                let tasks = (workspace.project(project.id)?.tasks ?? []).filter { $0.stage == stage }
                                if tasks.isEmpty {
                                    Text("No items").font(.caption).foregroundStyle(.secondary)
                                }
                                ForEach(tasks) { task in
                                    VStack(alignment: .leading, spacing: 8) {
                                        Text(task.title).fontWeight(.medium)
                                        HStack {
                                            Text(task.kind.rawValue.uppercased()).font(.caption2.monospaced()).foregroundStyle(.secondary)
                                            Spacer()
                                            Menu {
                                                ForEach(TaskStage.allCases) { target in
                                                    Button(target.label) { workspace.moveTask(projectID: project.id, taskID: task.id, to: target) }
                                                }
                                            } label: {
                                                Image(systemName: "arrow.right.circle")
                                            }
                                        }
                                    }
                                    .padding(10)
                                    .background(Color.primary.opacity(0.04), in: RoundedRectangle(cornerRadius: 10))
                                }
                            }
                            .frame(width: 230)
                        }
                    }
                }
            } else {
                EmptyState(title: "No project selected", detail: "Add a project first, then manage product, design, content, engineering and release tasks here.")
            }
            Spacer()
        }
        .momePage()
    }
}

struct ToolsView: View {
    @EnvironmentObject private var model: AppModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                HStack {
                    VStack(alignment: .leading) {
                        Text("INTEGRATIONS").font(.caption.weight(.bold)).foregroundStyle(.secondary)
                        Text("Developer Environment").font(.title.weight(.bold))
                    }
                    Spacer()
                    Button {
                        Task { await model.refreshEnvironment() }
                    } label: {
                        Label(model.isScanning ? "Scanning…" : "Rescan", systemImage: "arrow.clockwise")
                    }
                    .disabled(model.isScanning)
                }

                ForEach(ToolCategory.allCases, id: \.self) { category in
                    let tools = model.tools.filter { $0.category == category }
                    if !tools.isEmpty {
                        MOMECard(category.rawValue) {
                            ForEach(tools) { tool in
                                HStack(spacing: 12) {
                                    StatusDot(active: tool.isInstalled)
                                    VStack(alignment: .leading, spacing: 3) {
                                        Text(tool.name).fontWeight(.semibold)
                                        Text(tool.location ?? "Not detected")
                                            .font(.caption.monospaced())
                                            .foregroundStyle(.secondary)
                                            .textSelection(.enabled)
                                    }
                                    Spacer()
                                    Text(tool.version ?? (tool.isInstalled ? "Installed" : "Missing"))
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                        .lineLimit(1)
                                }
                                if tool.id != tools.last?.id { Divider() }
                            }
                        }
                    }
                }
            }
        }
        .momePage()
    }
}

struct TerminalView: View {
    @EnvironmentObject private var processes: ProcessSupervisor
    @EnvironmentObject private var workspace: WorkspaceStore
    @State private var projectID: UUID?
    @State private var command = ""
    @State private var selectedSessionID: UUID?

    private var selectedProject: MOMEProject? { workspace.project(projectID) }
    private var selectedSession: ProcessSession? {
        processes.sessions.first { $0.id == selectedSessionID } ?? processes.sessions.first
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 10) {
                Picker("Project", selection: $projectID) {
                    Text("Home directory").tag(nil as UUID?)
                    ForEach(workspace.projects) { p in Text(p.name).tag(Optional(p.id)) }
                }
                .frame(width: 220)

                TextField("Run a command…", text: $command)
                    .font(.body.monospaced())
                    .onSubmit(run)

                Button("Run", action: run)
                    .buttonStyle(.borderedProminent)
            }
            .padding(14)

            Divider()

            HStack(spacing: 0) {
                List(processes.sessions, selection: $selectedSessionID) { session in
                    VStack(alignment: .leading, spacing: 3) {
                        HStack {
                            StatusDot(active: session.state == .running)
                            Text(session.title).fontWeight(.semibold).lineLimit(1)
                        }
                        Text(session.state.rawValue).font(.caption).foregroundStyle(.secondary)
                    }
                    .tag(session.id)
                }
                .frame(width: 230)

                Divider()

                if let session = selectedSession {
                    VStack(spacing: 0) {
                        HStack {
                            VStack(alignment: .leading, spacing: 3) {
                                Text(session.title).fontWeight(.semibold)
                                Text(session.workingDirectory).font(.caption.monospaced()).foregroundStyle(.secondary)
                            }
                            Spacer()
                            RiskBadge(risk: session.risk)
                            if session.state == .running {
                                Button("Stop") { processes.stop(session.id) }
                            }
                        }
                        .padding(12)
                        Divider()
                        ScrollView([.vertical, .horizontal]) {
                            Text(session.output)
                                .font(.system(.body, design: .monospaced))
                                .textSelection(.enabled)
                                .frame(maxWidth: .infinity, alignment: .topLeading)
                                .padding(14)
                        }
                        .background(Color.black.opacity(0.18))
                    }
                } else {
                    EmptyState(title: "Terminal ready", detail: "Run a command against your home directory or one of your registered projects.")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
        }
        .background(Color(nsColor: .windowBackgroundColor))
    }

    private func run() {
        let trimmed = command.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        processes.start(
            title: trimmed.split(separator: " ").first.map(String.init) ?? "Command",
            command: trimmed,
            workingDirectory: selectedProject?.folderURL,
            risk: .safe
        )
        command = ""
    }
}

struct DevicesView: View {
    @EnvironmentObject private var model: AppModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                HStack {
                    VStack(alignment: .leading) {
                        Text("DEVICES").font(.caption.weight(.bold)).foregroundStyle(.secondary)
                        Text("Simulators & Connected Hardware").font(.title.weight(.bold))
                    }
                    Spacer()
                    Button("Open iOS Simulator") {
                        model.request(ToolAction(title: "Open iOS Simulator", command: "open -a Simulator", risk: .read, symbol: "iphone"), for: nil)
                    }
                    Button {
                        Task { await model.refreshEnvironment() }
                    } label: { Image(systemName: "arrow.clockwise") }
                }

                if model.devices.isEmpty {
                    EmptyState(title: "No devices detected", detail: "Install Xcode simulator runtimes or connect/start an Android device, then rescan.")
                } else {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 280), spacing: 12)], spacing: 12) {
                        ForEach(model.devices) { device in
                            MOMECard {
                                HStack {
                                    Image(systemName: device.platform == .iOS ? "iphone" : "apps.iphone")
                                        .font(.title2)
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(device.name).fontWeight(.semibold)
                                        Text([device.platform.rawValue, device.runtime, device.state].compactMap { $0 }.joined(separator: "  •  "))
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                    Spacer()
                                    StatusDot(active: device.state.lowercased().contains("boot") || device.state.lowercased() == "device")
                                }
                            }
                        }
                    }
                }
            }
        }
        .momePage()
    }
}

struct AIView: View {
    @EnvironmentObject private var model: AppModel
    @EnvironmentObject private var workspace: WorkspaceStore
    @EnvironmentObject private var processes: ProcessSupervisor

    @State private var provider: AIProvider = .openAI
    @State private var apiKey = ""
    @State private var prompt = ""
    @State private var response = ""
    @State private var isLoading = false
    @State private var errorMessage: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack {
                VStack(alignment: .leading) {
                    Text("FORGE AI").font(.caption.weight(.bold)).foregroundStyle(.secondary)
                    Text("Reason over your build context").font(.title.weight(.bold))
                }
                Spacer()
                Picker("Provider", selection: $provider) {
                    ForEach(AIProvider.allCases) { Text($0.rawValue).tag($0) }
                }
                .pickerStyle(.segmented)
                .frame(width: 240)
            }

            MOMECard("Secure API Credential") {
                HStack {
                    SecureField("API key stored in macOS Keychain", text: $apiKey)
                    Button("Save to Keychain") {
                        try? model.keychain.save(apiKey, account: provider.keychainAccount)
                    }
                }
            }

            MOMECard("Prompt") {
                TextEditor(text: $prompt)
                    .font(.body.monospaced())
                    .frame(minHeight: 130)
                    .scrollContentBackground(.hidden)
                    .padding(8)
                    .background(Color.primary.opacity(0.04), in: RoundedRectangle(cornerRadius: 10))

                HStack {
                    Button("Use Latest Build Log") {
                        if let session = processes.sessions.first {
                            prompt = "Analyze this developer command/build output. Identify the root cause and give precise next actions. Do not execute destructive or release commands.\n\nProject context: \(session.workingDirectory)\nCommand: \(session.command)\n\nOutput:\n\(session.output)"
                        }
                    }
                    .disabled(processes.sessions.isEmpty)
                    Spacer()
                    Button(isLoading ? "Thinking…" : "Ask \(provider.rawValue)") {
                        ask()
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(isLoading || prompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }

            MOMECard("Response") {
                if let errorMessage {
                    Text(errorMessage).foregroundStyle(.red)
                } else if response.isEmpty {
                    Text("AI output will appear here. MOME never executes AI-suggested write, release or dangerous commands without explicit approval.")
                        .foregroundStyle(.secondary)
                } else {
                    ScrollView {
                        Text(response)
                            .textSelection(.enabled)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            }
            .frame(maxHeight: .infinity)
        }
        .momePage()
        .onAppear { loadKey() }
        .onChange(of: provider) { _, _ in loadKey() }
    }

    private func loadKey() {
        apiKey = model.keychain.read(account: provider.keychainAccount) ?? ""
    }

    private func ask() {
        let key = apiKey.isEmpty ? (model.keychain.read(account: provider.keychainAccount) ?? "") : apiKey
        guard !key.isEmpty else {
            errorMessage = "Add an API key for \(provider.rawValue) first."
            return
        }
        errorMessage = nil
        isLoading = true
        let currentPrompt = prompt
        let currentProvider = provider
        Task {
            do {
                response = try await model.ai.ask(currentPrompt, provider: currentProvider, apiKey: key)
            } catch {
                errorMessage = error.localizedDescription
            }
            isLoading = false
        }
    }
}

struct DeploymentsView: View {
    @EnvironmentObject private var model: AppModel
    @EnvironmentObject private var workspace: WorkspaceStore

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("DEPLOYMENTS").font(.caption.weight(.bold)).foregroundStyle(.secondary)
                Text("Preview → Production").font(.title.weight(.bold))
                Text("Production-affecting actions are always approval-gated.").foregroundStyle(.secondary)

                ForEach(workspace.projects) { project in
                    MOMECard(project.name) {
                        HStack {
                            ForEach(deployActions(for: project)) { action in
                                Button {
                                    model.request(action, for: project)
                                } label: {
                                    Label(action.title, systemImage: action.symbol)
                                }
                                .buttonStyle(.bordered)
                            }
                            Spacer()
                        }
                    }
                }

                if workspace.projects.isEmpty {
                    EmptyState(title: "No deployment surfaces yet", detail: "Add a project. Cloudflare and Vercel commands become available from the same project context.")
                }
            }
        }
        .momePage()
    }

    private func deployActions(for project: MOMEProject) -> [ToolAction] {
        CloudflareAdapter().actions(for: project) + VercelAdapter().actions(for: project)
    }
}

struct CommandPaletteView: View {
    @EnvironmentObject private var model: AppModel
    @EnvironmentObject private var workspace: WorkspaceStore
    @EnvironmentObject private var processes: ProcessSupervisor
    @Environment(\.dismiss) private var dismiss
    @State private var query = ""

    private var commands: [(String, String, () -> Void)] {
        var items: [(String, String, () -> Void)] = SidebarSection.allCases.map { section in
            (section.rawValue, "Navigate", { model.section = section; dismiss() })
        }
        items.append(("Rescan developer environment", "System", { Task { await model.refreshEnvironment() }; dismiss() }))
        items.append(("Open iOS Simulator", "Device", { model.request(ToolAction(title: "Open Simulator", command: "open -a Simulator", risk: .read), for: nil); dismiss() }))
        for project in workspace.projects {
            items.append(("Open \(project.name) in VS Code", project.name, {
                model.request(ToolAction(title: "Open VS Code", command: "code .", risk: .read, tool: .vscode), for: project)
                dismiss()
            }))
            items.append(("Git status — \(project.name)", project.name, {
                model.request(ToolAction(title: "Git Status", command: "git status --short --branch", risk: .read, tool: .git), for: project)
                dismiss()
            }))
        }
        return items
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Image(systemName: "command")
                TextField("Type a command…", text: $query)
                    .textFieldStyle(.plain)
                    .font(.title3)
            }
            .padding(18)
            Divider()

            ScrollView {
                LazyVStack(spacing: 4) {
                    ForEach(Array(filtered.enumerated()), id: \.offset) { _, item in
                        Button(action: item.2) {
                            HStack {
                                Text(item.0).fontWeight(.medium)
                                Spacer()
                                Text(item.1).font(.caption).foregroundStyle(.secondary)
                            }
                            .padding(10)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(8)
            }
        }
        .frame(width: 620, height: 470)
    }

    private var filtered: [(String, String, () -> Void)] {
        guard !query.isEmpty else { return commands }
        return commands.filter { $0.0.localizedCaseInsensitiveContains(query) || $0.1.localizedCaseInsensitiveContains(query) }
    }
}

private struct EmptyState: View {
    let title: String
    let detail: String

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title).fontWeight(.semibold)
            Text(detail).font(.callout).foregroundStyle(.secondary)
        }
        .padding(.vertical, 8)
    }
}

private func icon(for kind: ProjectKind) -> String {
    switch kind {
    case .mobile: return "apps.iphone"
    case .web: return "globe"
    case .nativeMac: return "macbook"
    case .game: return "gamecontroller"
    case .threeD: return "cube"
    case .backend: return "server.rack"
    case .unknown: return "folder"
    }
}
