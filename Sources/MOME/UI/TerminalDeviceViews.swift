import SwiftUI

struct TerminalView: View {
    @EnvironmentObject private var processes: ProcessSupervisor
    @EnvironmentObject private var workspace: WorkspaceStore
    @State private var projectID: UUID?
    @State private var command = ""
    @State private var shellInput = ""
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
                    ForEach(workspace.projects) { Text($0.name).tag(Optional($0.id)) }
                }
                .frame(width: 220)

                Button {
                    let id = processes.startShell(
                        title: selectedProject.map { $0.name + " Shell" } ?? "Home Shell",
                        workingDirectory: selectedProject?.folderURL
                    )
                    selectedSessionID = id
                } label: {
                    Label("New Shell", systemImage: "terminal.fill")
                }
                .buttonStyle(.borderedProminent)

                Divider().frame(height: 24)

                TextField("Run a one-shot command…", text: $command)
                    .font(.body.monospaced())
                    .onSubmit(runJob)

                Button("Run Job", action: runJob)
            }
            .padding(14)

            Divider()

            HStack(spacing: 0) {
                VStack(spacing: 0) {
                    List(processes.sessions, selection: $selectedSessionID) { session in
                        VStack(alignment: .leading, spacing: 3) {
                            HStack {
                                StatusDot(active: session.state == .running)
                                Text(session.title).fontWeight(.semibold).lineLimit(1)
                                if session.interactive { Image(systemName: "terminal").font(.caption2).foregroundStyle(.secondary) }
                            }
                            Text(session.state.rawValue).font(.caption).foregroundStyle(.secondary)
                        }
                        .tag(session.id)
                    }

                    HStack {
                        Button("Clear Completed") { processes.clearCompleted() }
                            .font(.caption)
                        Spacer()
                    }
                    .padding(10)
                }
                .frame(width: 250)

                Divider()

                if let session = selectedSession {
                    VStack(spacing: 0) {
                        HStack {
                            VStack(alignment: .leading, spacing: 3) {
                                HStack {
                                    Text(session.title).fontWeight(.semibold)
                                    if session.interactive {
                                        Text("PTY").font(.caption2.bold()).padding(.horizontal, 6).padding(.vertical, 2).background(Color.blue.opacity(0.12), in: Capsule())
                                    }
                                }
                                Text(session.workingDirectory).font(.caption.monospaced()).foregroundStyle(.secondary)
                            }
                            Spacer()
                            RiskBadge(risk: session.risk)
                            Button("Clear") { processes.clearOutput(session.id) }
                            if session.state == .running && session.interactive {
                                Button("Interrupt") { processes.sendInterrupt(to: session.id) }
                            }
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

                        if session.interactive && session.state == .running {
                            Divider()
                            HStack {
                                Text("❯").font(.body.monospaced()).foregroundStyle(.secondary)
                                TextField("Send to shell…", text: $shellInput)
                                    .textFieldStyle(.plain)
                                    .font(.body.monospaced())
                                    .onSubmit(sendToShell)
                                Button("Send", action: sendToShell)
                                    .keyboardShortcut(.return, modifiers: [.command])
                            }
                            .padding(12)
                        }
                    }
                } else {
                    EmptyState(title: "Terminal ready", detail: "Choose New Shell for a persistent PTY-backed terminal, or Run Job for a one-shot command.")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
        }
        .background(Color(nsColor: .windowBackgroundColor))
    }

    private func runJob() {
        let trimmed = command.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        processes.start(
            title: trimmed.split(separator: " ").first.map(String.init) ?? "Command",
            command: trimmed,
            workingDirectory: selectedProject?.folderURL,
            risk: .safe
        )
        selectedSessionID = processes.sessions.first?.id
        command = ""
    }

    private func sendToShell() {
        guard let session = selectedSession, session.interactive else { return }
        let value = shellInput
        shellInput = ""
        processes.send(value, to: session.id)
    }
}

struct DevicesView: View {
    @EnvironmentObject private var model: AppModel
    @EnvironmentObject private var workspace: WorkspaceStore
    @State private var projectID: UUID?

    private var project: MOMEProject? { workspace.project(projectID) }
    private var iosDevices: [DeviceInfo] { model.devices.filter { $0.platform == .iOS } }
    private var androidDevices: [DeviceInfo] { model.devices.filter { $0.platform == .android } }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                HStack {
                    VStack(alignment: .leading) {
                        Text("DEVICES").font(.caption.weight(.bold)).foregroundStyle(.secondary)
                        Text("Simulators, Emulators & Hardware").font(.title.weight(.bold))
                    }
                    Spacer()
                    Picker("Project", selection: $projectID) {
                        Text("No app selected").tag(nil as UUID?)
                        ForEach(workspace.projects) { Text($0.name).tag(Optional($0.id)) }
                    }
                    .frame(width: 220)
                    Button("Open Simulator") {
                        model.request(ToolAction(title: "Open iOS Simulator", command: "open -a Simulator", risk: .read, tool: .xcode, symbol: "iphone"), for: nil)
                    }
                    Button { Task { await model.refreshEnvironment() } } label: { Image(systemName: "arrow.clockwise") }
                }

                deviceSection(title: "Apple / iOS", devices: iosDevices)
                deviceSection(title: "Android", devices: androidDevices)

                if model.devices.isEmpty {
                    EmptyState(title: "No devices detected", detail: "Install an Xcode simulator runtime or Android SDK/AVD, connect hardware, then rescan.")
                }
            }
        }
        .momePage()
    }

    @ViewBuilder
    private func deviceSection(title: String, devices: [DeviceInfo]) -> some View {
        if !devices.isEmpty {
            VStack(alignment: .leading, spacing: 10) {
                Text(title.uppercased()).font(.caption.bold()).foregroundStyle(.secondary).tracking(0.8)
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 340), spacing: 12)], spacing: 12) {
                    ForEach(devices) { device in
                        MOMECard {
                            HStack {
                                Image(systemName: device.platform == .iOS ? "iphone" : "apps.iphone")
                                    .font(.title2)
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(device.name).fontWeight(.semibold)
                                    Text([device.platform.rawValue, device.runtime, device.state].compactMap { $0 }.joined(separator: "  •  "))
                                        .font(.caption).foregroundStyle(.secondary)
                                }
                                Spacer()
                                StatusDot(active: device.isBooted)
                            }

                            Divider()

                            let actions = DeviceActions.actions(for: device, project: project)
                            FlowButtons(actions: actions) { action in
                                model.runDeviceAction(action, project: project)
                            }
                        }
                    }
                }
            }
        }
    }
}

private struct FlowButtons: View {
    let actions: [ToolAction]
    let run: (ToolAction) -> Void

    var body: some View {
        HStack(spacing: 8) {
            ForEach(actions) { action in
                Button {
                    run(action)
                } label: {
                    Label(action.title, systemImage: action.symbol)
                }
                .buttonStyle(.bordered)
                .help(action.help ?? action.title)
            }
            Spacer(minLength: 0)
        }
    }
}
