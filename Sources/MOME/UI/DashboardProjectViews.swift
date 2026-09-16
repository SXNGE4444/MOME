import SwiftUI
import AppKit

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
                        Text("COMMAND CENTER").font(.caption.weight(.semibold)).foregroundStyle(.secondary).tracking(1.2)
                        Text("Build. Test. Ship.").font(.system(size: 34, weight: .bold, design: .rounded))
                        Text("One operational surface for your Mac, projects, devices, builds, AI and release paths.").foregroundStyle(.secondary)
                    }
                    Spacer()
                    Button { model.isSetupPresented = true } label: { Label("Setup", systemImage: "wand.and.stars") }
                    Button { workspace.pickAndAddProject() } label: { Label("Add Project", systemImage: "plus") }
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
                            EmptyState(title: "No projects yet", detail: "Add a source folder and MOME will inspect its real stack before offering actions.")
                        } else {
                            ForEach(workspace.projects.prefix(5)) { project in
                                Button {
                                    model.section = .projects
                                } label: {
                                    HStack(spacing: 12) {
                                        Image(systemName: icon(for: project.kind)).frame(width: 26)
                                        VStack(alignment: .leading) {
                                            Text(project.name).fontWeight(.semibold)
                                            Text(project.kind.label + "  •  " + project.path).font(.caption).foregroundStyle(.secondary).lineLimit(1)
                                        }
                                        Spacer()
                                        Image(systemName: "chevron.right").foregroundStyle(.tertiary)
                                    }
                                    .contentShape(Rectangle())
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)

                    MOMECard("Live Activity") {
                        if processes.sessions.isEmpty {
                            EmptyState(title: "Nothing running", detail: "Builds, shells, renders and deployments will stream here.")
                        } else {
                            ForEach(processes.sessions.prefix(6)) { session in
                                HStack {
                                    StatusDot(active: session.state == .running)
                                    VStack(alignment: .leading) {
                                        Text(session.title).fontWeight(.medium)
                                        Text(session.command).font(.caption.monospaced()).foregroundStyle(.secondary).lineLimit(1)
                                    }
                                    Spacer()
                                    Text(session.state.rawValue.uppercased()).font(.caption2.monospaced()).foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)
                }

                MOMECard("Environment") {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 180), spacing: 10)], spacing: 10) {
                        ForEach(model.tools) { tool in
                            HStack(spacing: 9) {
                                StatusDot(active: tool.isInstalled)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(tool.name).font(.subheadline.weight(.medium))
                                    Text(tool.version ?? (tool.isInstalled ? "Ready" : "Not detected"))
                                        .font(.caption2).foregroundStyle(.secondary).lineLimit(1)
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
                .padding(.horizontal, 14).padding(.top, 14)

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
                EmptyState(title: "Add your first project", detail: "MOME will detect its real stack and generate the appropriate build, simulator, engine, cloud and source-control actions.")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .background(Color(nsColor: .windowBackgroundColor))
    }
}

private struct ProjectDetailView: View {
    @EnvironmentObject private var model: AppModel
    @EnvironmentObject private var workspace: WorkspaceStore
    let project: MOMEProject
    @State private var configMessage: String?

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
                    Button("Reload Config") { workspace.reloadProject(project.id) }
                    Button("Reveal in Finder") { NSWorkspace.shared.activateFileViewerSelecting([project.folderURL]) }
                }

                MOMECard("Run / Build / Open") {
                    if actions.isEmpty {
                        EmptyState(title: "No stack actions detected", detail: "Add forge.json commands or verify that the project contains its platform configuration files.")
                    } else {
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 215), spacing: 10)], spacing: 10) {
                            ForEach(actions) { action in
                                Button { model.request(action, for: project) } label: {
                                    HStack {
                                        Image(systemName: action.symbol)
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(action.title).lineLimit(1)
                                            if let help = action.help {
                                                Text(help).font(.caption2).foregroundStyle(.secondary).lineLimit(2)
                                            }
                                        }
                                        Spacer()
                                        RiskBadge(risk: action.risk)
                                    }
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.vertical, 5)
                                }
                                .buttonStyle(.bordered)
                            }
                        }
                    }
                }

                HStack(alignment: .top, spacing: 14) {
                    MOMECard("Configuration") {
                        if FileManager.default.fileExists(atPath: project.folderURL.appendingPathComponent("forge.json").path) {
                            Label("forge.json detected", systemImage: "checkmark.seal").foregroundStyle(.secondary)
                        } else {
                            Text("No forge.json yet. Basic stack detection still works, but release paths need explicit configuration.").foregroundStyle(.secondary)
                            Button("Create Starter forge.json") {
                                do {
                                    try workspace.writeStarterForgeConfig(for: project)
                                    configMessage = "Created forge.json. Edit it, then choose Reload Config."
                                } catch {
                                    configMessage = error.localizedDescription
                                }
                            }
                        }
                        if let configMessage { Text(configMessage).font(.caption).foregroundStyle(.secondary) }
                    }
                    .frame(maxWidth: .infinity)

                    MOMECard("Release Paths") {
                        if project.deployment.isEmpty {
                            Text("No deployment targets declared.").foregroundStyle(.secondary)
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
                    ForEach(workspace.projects) { Text($0.name).tag(Optional($0.id)) }
                }.frame(width: 220)
            }

            if let project {
                HStack {
                    TextField("Add a task, content item, build step…", text: $title)
                    Picker("Kind", selection: $kind) { ForEach(TaskKind.allCases) { Text($0.rawValue.capitalized).tag($0) } }.frame(width: 150)
                    Button("Add") {
                        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
                        guard !trimmed.isEmpty else { return }
                        workspace.addTask(projectID: project.id, title: trimmed, kind: kind)
                        title = ""
                    }.buttonStyle(.borderedProminent)
                }

                ScrollView(.horizontal) {
                    HStack(alignment: .top, spacing: 12) {
                        ForEach(TaskStage.allCases) { stage in
                            MOMECard(stage.label) {
                                let tasks = (workspace.project(project.id)?.tasks ?? []).filter { $0.stage == stage }
                                if tasks.isEmpty { Text("No items").font(.caption).foregroundStyle(.secondary) }
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
                                            } label: { Image(systemName: "arrow.right.circle") }
                                        }
                                    }
                                    .padding(10)
                                    .background(Color.primary.opacity(0.04), in: RoundedRectangle(cornerRadius: 10))
                                }
                            }.frame(width: 230)
                        }
                    }
                }
            } else {
                EmptyState(title: "No project selected", detail: "Add a project first, then manage product, design, content, engineering and release tasks here.")
            }
            Spacer()
        }.momePage()
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
                    Button { model.isSetupPresented = true } label: { Label("Configure", systemImage: "gearshape") }
                    Button { Task { await model.refreshEnvironment() } } label: { Label(model.isScanning ? "Scanning…" : "Rescan", systemImage: "arrow.clockwise") }.disabled(model.isScanning)
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
                                        Text(tool.location ?? "Not detected").font(.caption.monospaced()).foregroundStyle(.secondary).textSelection(.enabled)
                                    }
                                    Spacer()
                                    Text(tool.version ?? (tool.isInstalled ? "Installed" : "Missing")).font(.caption).foregroundStyle(.secondary).lineLimit(1)
                                }
                            }
                        }
                    }
                }
            }
        }.momePage()
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
                Text("Only stack-relevant release actions are shown. Every production-affecting action remains approval-gated.").foregroundStyle(.secondary)

                ForEach(workspace.projects) { project in
                    let releaseActions = AdapterRegistry.actions(for: project).filter { $0.risk == .release }
                    if !releaseActions.isEmpty {
                        MOMECard(project.name) {
                            ForEach(releaseActions) { action in
                                HStack {
                                    VStack(alignment: .leading) {
                                        Text(action.title).fontWeight(.semibold)
                                        if let help = action.help { Text(help).font(.caption).foregroundStyle(.secondary) }
                                    }
                                    Spacer()
                                    Button("Review & Run") { model.request(action, for: project) }.buttonStyle(.bordered)
                                }
                            }
                        }
                    }
                }

                if workspace.projects.isEmpty {
                    EmptyState(title: "No projects", detail: "Add a project to create deployment surfaces.")
                }
            }
        }.momePage()
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
        items.append(("Guided setup", "Help", { model.isSetupPresented = true; dismiss() }))
        items.append(("Open MOME guide", "Help", { model.isGuidePresented = true; dismiss() }))
        items.append(("Rescan developer environment", "System", { Task { await model.refreshEnvironment() }; dismiss() }))
        items.append(("New home shell", "Terminal", { _ = processes.startShell(); model.section = .terminal; dismiss() }))
        for project in workspace.projects {
            items.append(("New shell — \(project.name)", project.name, { _ = processes.startShell(title: project.name + " Shell", workingDirectory: project.folderURL); model.section = .terminal; dismiss() }))
            for action in AdapterRegistry.actions(for: project).prefix(20) {
                items.append((action.title + " — " + project.name, project.name, { model.request(action, for: project); dismiss() }))
            }
        }
        return items
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Image(systemName: "command")
                TextField("Type a command…", text: $query).textFieldStyle(.plain).font(.title3)
            }.padding(18)
            Divider()
            ScrollView {
                LazyVStack(spacing: 4) {
                    ForEach(Array(filtered.enumerated()), id: \.offset) { _, item in
                        Button(action: item.2) {
                            HStack { Text(item.0).fontWeight(.medium); Spacer(); Text(item.1).font(.caption).foregroundStyle(.secondary) }
                                .padding(10).contentShape(Rectangle())
                        }.buttonStyle(.plain)
                    }
                }.padding(8)
            }
        }.frame(width: 680, height: 520)
    }

    private var filtered: [(String, String, () -> Void)] {
        guard !query.isEmpty else { return commands }
        return commands.filter { $0.0.localizedCaseInsensitiveContains(query) || $0.1.localizedCaseInsensitiveContains(query) }
    }
}

struct EmptyState: View {
    let title: String
    let detail: String
    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title).fontWeight(.semibold)
            Text(detail).font(.callout).foregroundStyle(.secondary)
        }.padding(.vertical, 8)
    }
}

func icon(for kind: ProjectKind) -> String {
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
