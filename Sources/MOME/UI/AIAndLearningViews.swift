import SwiftUI

struct AIView: View {
    @EnvironmentObject private var model: AppModel
    @EnvironmentObject private var workspace: WorkspaceStore
    @EnvironmentObject private var processes: ProcessSupervisor

    @State private var provider: AIProvider = .openAI
    @State private var projectID: UUID?
    @State private var apiKey = ""
    @State private var prompt = ""
    @State private var response = ""
    @State private var isLoading = false
    @State private var errorMessage: String?

    private var project: MOMEProject? { workspace.project(projectID) ?? workspace.projects.first }

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack {
                VStack(alignment: .leading) {
                    Text("FORGE AI").font(.caption.weight(.bold)).foregroundStyle(.secondary)
                    Text("Reason over real project and build context").font(.title.weight(.bold))
                }
                Spacer()
                Picker("Project", selection: $projectID) {
                    Text("No project").tag(nil as UUID?)
                    ForEach(workspace.projects) { Text($0.name).tag(Optional($0.id)) }
                }.frame(width: 210)
                Picker("Provider", selection: $provider) {
                    ForEach(AIProvider.allCases) { Text($0.rawValue).tag($0) }
                }
                .pickerStyle(.segmented).frame(width: 410)
            }

            MOMECard("Secure API Credential") {
                HStack {
                    SecureField("API key stored in macOS Keychain", text: $apiKey)
                    Button("Save to Keychain") {
                        do {
                            try model.keychain.save(apiKey, account: provider.keychainAccount)
                            errorMessage = nil
                        } catch {
                            errorMessage = error.localizedDescription
                        }
                    }
                }
            }

            MOMECard("Prompt") {
                TextEditor(text: $prompt)
                    .font(.body.monospaced()).frame(minHeight: 150).scrollContentBackground(.hidden)
                    .padding(8).background(Color.primary.opacity(0.04), in: RoundedRectangle(cornerRadius: 10))

                HStack {
                    Menu("Insert Context") {
                        Button("Latest Build Log") { insertLatestLog() }
                        Button("Project Snapshot") { insertProjectSnapshot() }
                        Button("Environment Snapshot") { insertEnvironmentSnapshot() }
                    }
                    Spacer()
                    Button(isLoading ? "Thinking…" : "Ask \(provider.rawValue)") { ask() }
                        .buttonStyle(.borderedProminent)
                        .disabled(isLoading || prompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }

            MOMECard("Response") {
                if let errorMessage {
                    Text(errorMessage).foregroundStyle(.red).textSelection(.enabled)
                } else if response.isEmpty {
                    Text("Ask about a build, project, tool or deployment. MOME AI can explain and diagnose, but suggested write/release commands still pass through MOME's approval gates.")
                        .foregroundStyle(.secondary)
                } else {
                    ScrollView {
                        Text(response).textSelection(.enabled).frame(maxWidth: .infinity, alignment: .leading)
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

    private func insertLatestLog() {
        guard let session = processes.sessions.first else { return }
        prompt = "Analyze this developer output. Identify the root cause, explain it in plain language, and give precise next actions. Do not assume a command succeeded unless the log proves it.\n\nWorking directory: \(session.workingDirectory)\nCommand: \(session.command)\nState: \(session.state.rawValue)\n\nOutput:\n\(session.output)"
    }

    private func insertProjectSnapshot() {
        guard let project else { return }
        let actions = AdapterRegistry.actions(for: project).map(\.title).joined(separator: ", ")
        prompt = "Help me with this project.\n\nName: \(project.name)\nType: \(project.kind.label)\nPath: \(project.path)\nRepository: \(project.repository ?? "not declared")\nDetected MOME actions: \(actions)\nSettings keys: \(project.settings?.keys.sorted().joined(separator: ", ") ?? "none")\n\nQuestion: "
    }

    private func insertEnvironmentSnapshot() {
        let summary = model.tools.map { "\($0.name): \($0.isInstalled ? "installed" : "missing") \($0.version ?? "")" }.joined(separator: "\n")
        prompt = "Explain my MOME developer environment and identify anything missing for the task I describe.\n\n\(summary)\n\nTask: "
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

struct LearnView: View {
    @EnvironmentObject private var model: AppModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                HStack {
                    VStack(alignment: .leading, spacing: 5) {
                        Text("MOME ACADEMY").font(.caption.bold()).foregroundStyle(.secondary).tracking(1)
                        Text("Learn while you build").font(.largeTitle.bold())
                        Text("Guides are tied to the same tools and workflows MOME controls.").foregroundStyle(.secondary)
                    }
                    Spacer()
                    Button("Open Full Guide") { model.isGuidePresented = true }.buttonStyle(.borderedProminent)
                    Button("Run Guided Setup") { model.isSetupPresented = true }
                }

                ForEach(GuideCategory.allCases) { category in
                    let articles = LearningLibrary.articles.filter { $0.category == category }
                    if !articles.isEmpty {
                        VStack(alignment: .leading, spacing: 10) {
                            Text(category.rawValue.uppercased()).font(.caption.bold()).foregroundStyle(.secondary)
                            LazyVGrid(columns: [GridItem(.adaptive(minimum: 280), spacing: 12)], spacing: 12) {
                                ForEach(articles) { article in
                                    MOMECard {
                                        Text(article.title).font(.headline)
                                        Text(article.summary).font(.callout).foregroundStyle(.secondary)
                                        Button("Read Guide") { model.isGuidePresented = true }
                                            .buttonStyle(.borderless)
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }.momePage()
    }
}

struct GuideLibraryView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var category: GuideCategory = .gettingStarted
    @State private var selectedID: String = LearningLibrary.articles.first?.id ?? ""

    private var articles: [GuideArticle] { LearningLibrary.articles.filter { $0.category == category } }
    private var selected: GuideArticle? { LearningLibrary.articles.first { $0.id == selectedID } ?? articles.first }

    var body: some View {
        HStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 12) {
                Text("MOME GUIDE").font(.caption.bold()).foregroundStyle(.secondary).padding(.horizontal, 14).padding(.top, 16)
                List(GuideCategory.allCases, selection: $category) { item in
                    Text(item.rawValue).tag(item)
                }.listStyle(.sidebar)
            }.frame(width: 190)

            Divider()

            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    Picker("Guide", selection: $selectedID) {
                        ForEach(articles) { Text($0.title).tag($0.id) }
                    }.frame(maxWidth: 340)
                    Spacer()
                    Button("Done") { dismiss() }
                }.padding(14)
                Divider()

                if let selected {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 18) {
                            Text(selected.title).font(.largeTitle.bold())
                            Text(selected.summary).font(.title3).foregroundStyle(.secondary)
                            Divider()
                            ForEach(Array(selected.steps.enumerated()), id: \.offset) { index, step in
                                HStack(alignment: .top, spacing: 14) {
                                    Text("\(index + 1)").font(.caption.bold()).frame(width: 26, height: 26).background(Color.primary.opacity(0.08), in: Circle())
                                    Text(step).frame(maxWidth: .infinity, alignment: .leading)
                                }
                            }
                            if !selected.commandExamples.isEmpty {
                                MOMECard("Examples") {
                                    ForEach(selected.commandExamples, id: \.self) { command in
                                        Text("$ " + command).font(.body.monospaced()).textSelection(.enabled)
                                    }
                                }
                            }
                        }.padding(28)
                    }
                }
            }
        }
        .onChange(of: category) { _, newCategory in
            selectedID = LearningLibrary.articles.first { $0.category == newCategory }?.id ?? ""
        }
    }
}

struct SetupAssistantView: View {
    @EnvironmentObject private var model: AppModel
    @EnvironmentObject private var workspace: WorkspaceStore
    @State private var step = 0
    @State private var openAIKey = ""
    @State private var deepSeekKey = ""
    @State private var experientialLabsKey = ""
    @State private var ascKeyID = ""
    @State private var ascIssuerID = ""
    @State private var statusMessage: String?

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text("MOME GUIDED SETUP").font(.caption.bold()).foregroundStyle(.secondary)
                    Text(stepTitle).font(.title.bold())
                }
                Spacer()
                Text("Step \(step + 1) of 4").font(.caption).foregroundStyle(.secondary)
            }.padding(22)
            Divider()

            Group {
                switch step {
                case 0: environmentStep
                case 1: credentialsStep
                case 2: projectsStep
                default: completeStep
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .padding(24)

            Divider()
            HStack {
                if step > 0 { Button("Back") { step -= 1 } }
                Spacer()
                Button("Skip Setup") { model.markSetupComplete() }
                if step < 3 {
                    Button("Continue") { step += 1 }.buttonStyle(.borderedProminent)
                } else {
                    Button("Finish") { model.markSetupComplete() }.buttonStyle(.borderedProminent)
                }
            }.padding(18)
        }
        .onAppear { loadCredentials() }
    }

    private var stepTitle: String {
        ["Check your development environment", "Connect secure credentials", "Add your projects", "MOME is ready"][step]
    }

    private var environmentStep: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                Text("MOME only reports tools it can actually detect on this Mac. Missing tools can be installed later.").foregroundStyle(.secondary)
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 220), spacing: 10)], spacing: 10) {
                    ForEach(model.tools) { tool in
                        HStack {
                            StatusDot(active: tool.isInstalled)
                            VStack(alignment: .leading) {
                                Text(tool.name).fontWeight(.semibold)
                                Text(tool.isInstalled ? (tool.version ?? "Installed") : "Not detected").font(.caption).foregroundStyle(.secondary).lineLimit(1)
                            }
                            Spacer()
                        }.padding(10).background(Color.primary.opacity(0.04), in: RoundedRectangle(cornerRadius: 10))
                    }
                }
                Button(model.isScanning ? "Scanning…" : "Rescan") { Task { await model.refreshEnvironment() } }.disabled(model.isScanning)
            }
        }
    }

    private var credentialsStep: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Secrets are stored in macOS Keychain, not forge.json or the project repository.").foregroundStyle(.secondary)
                credentialField("OpenAI API key", text: $openAIKey, secure: true)
                credentialField("DeepSeek API key", text: $deepSeekKey, secure: true)
                credentialField("Experiential Labs API key", text: $experientialLabsKey, secure: true)
                credentialField("App Store Connect Key ID", text: $ascKeyID, secure: false)
                credentialField("App Store Connect Issuer ID", text: $ascIssuerID, secure: false)
                HStack {
                    Button("Save Credentials") { saveCredentials() }.buttonStyle(.borderedProminent)
                    if let statusMessage { Text(statusMessage).font(.caption).foregroundStyle(.secondary) }
                }
                Text("For TestFlight uploads, the App Store Connect private key file AuthKey_<KEYID>.p8 remains a local file in an Apple-supported private_keys directory. MOME does not write it into source control.").font(.caption).foregroundStyle(.secondary)
            }
        }
    }

    private var projectsStep: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Registered projects: \(workspace.projects.count)").font(.headline)
            Text("Add the ROOT folder for each product. MOME detects stack markers and only exposes relevant actions.").foregroundStyle(.secondary)
            Button { workspace.pickAndAddProject() } label: { Label("Add Project", systemImage: "plus") }.buttonStyle(.borderedProminent)
            if workspace.projects.isEmpty {
                EmptyState(title: "No projects yet", detail: "You can finish setup now and add projects later from the Projects screen.")
            } else {
                ForEach(workspace.projects.prefix(8)) { project in
                    HStack { Image(systemName: icon(for: project.kind)); Text(project.name); Spacer(); Text(project.kind.label).foregroundStyle(.secondary) }
                }
            }
        }
    }

    private var completeStep: some View {
        VStack(alignment: .leading, spacing: 16) {
            Image(systemName: "checkmark.seal.fill").font(.system(size: 46)).foregroundStyle(.green)
            Text("Core setup complete").font(.title2.bold())
            Text("Next, open a project and use its detected actions. Use Learn for walkthroughs covering terminal sessions, simulators, TestFlight, Android AVDs, Play Console, Blender, Unity, Unreal, GitHub, Cloudflare, Vercel and AI.").foregroundStyle(.secondary)
            Button("Open Learn after setup") { model.section = .learn }
        }
    }

    @ViewBuilder
    private func credentialField(_ title: String, text: Binding<String>, secure: Bool) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title).font(.caption.bold())
            if secure { SecureField(title, text: text) } else { TextField(title, text: text) }
        }
    }

    private func loadCredentials() {
        openAIKey = model.keychain.read(account: "openai.apiKey") ?? ""
        deepSeekKey = model.keychain.read(account: "deepseek.apiKey") ?? ""
        experientialLabsKey = model.keychain.read(account: "experientiallabs.apiKey") ?? ""
        ascKeyID = model.keychain.read(account: "appstore.keyID") ?? ""
        ascIssuerID = model.keychain.read(account: "appstore.issuerID") ?? ""
    }

    private func saveCredentials() {
        do {
            if !openAIKey.isEmpty { try model.keychain.save(openAIKey, account: "openai.apiKey") }
            if !deepSeekKey.isEmpty { try model.keychain.save(deepSeekKey, account: "deepseek.apiKey") }
            if !experientialLabsKey.isEmpty { try model.keychain.save(experientialLabsKey, account: "experientiallabs.apiKey") }
            if !ascKeyID.isEmpty { try model.keychain.save(ascKeyID, account: "appstore.keyID") }
            if !ascIssuerID.isEmpty { try model.keychain.save(ascIssuerID, account: "appstore.issuerID") }
            statusMessage = "Saved to Keychain."
        } catch {
            statusMessage = error.localizedDescription
        }
    }
}
