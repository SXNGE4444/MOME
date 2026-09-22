import SwiftUI
import Combine

struct MOMEWorkspace: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var name: String
    var detail: String
    var createdAt: Date = Date()
}

struct UnifiedInboxItem: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var source: String
    var title: String
    var body: String
    var createdAt: Date = Date()
    var isRead: Bool = false
}

struct MOMEAutomation: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var name: String
    var trigger: String
    var action: String
    var isEnabled: Bool = true
    var runCount: Int = 0
    var lastRunAt: Date?
}

struct MOMEAgent: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var name: String
    var role: String
    var instructions: String
    var isEnabled: Bool = true
}

enum ServiceConnectionState: String, Codable, CaseIterable {
    case disconnected
    case configured
    case connected
    case error
}

struct ServiceIntegration: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var name: String
    var category: String
    var authType: String
    var capabilities: [String]
    var state: ServiceConnectionState = .disconnected
}

struct RevenueEntry: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var label: String
    var amount: Double
    var createdAt: Date = Date()
}

enum RoadmapStatus: String, Codable, CaseIterable {
    case proposed = "Proposed"
    case planned = "Planned"
    case building = "Building"
    case shipped = "Shipped"
}

struct CommunityRoadmapItem: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var title: String
    var detail: String
    var status: RoadmapStatus = .proposed
    var votes: Int = 0
}

private struct NausicaaSnapshot: Codable {
    var workspaces: [MOMEWorkspace]
    var inbox: [UnifiedInboxItem]
    var automations: [MOMEAutomation]
    var agents: [MOMEAgent]
    var integrations: [ServiceIntegration]
    var revenue: [RevenueEntry]
    var roadmap: [CommunityRoadmapItem]
}

@MainActor
final class NausicaaStore: ObservableObject {
    @Published var workspaces: [MOMEWorkspace] = []
    @Published var inbox: [UnifiedInboxItem] = []
    @Published var automations: [MOMEAutomation] = []
    @Published var agents: [MOMEAgent] = []
    @Published var integrations: [ServiceIntegration] = []
    @Published var revenue: [RevenueEntry] = []
    @Published var roadmap: [CommunityRoadmapItem] = []

    private let storageURL: URL

    init() {
        let fm = FileManager.default
        let root = fm.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("MOME", isDirectory: true)
        try? fm.createDirectory(at: root, withIntermediateDirectories: true)
        storageURL = root.appendingPathComponent("nausicaa-features.json")
        load()
        seedCatalogsIfNeeded()
    }

    func addWorkspace(name: String, detail: String) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        workspaces.insert(MOMEWorkspace(name: trimmed, detail: detail), at: 0)
        record(source: "Workspace", title: "Workspace created", body: trimmed)
        save()
    }

    func removeWorkspace(_ id: UUID) {
        workspaces.removeAll { $0.id == id }
        save()
    }

    func record(source: String, title: String, body: String) {
        inbox.insert(UnifiedInboxItem(source: source, title: title, body: body), at: 0)
        if inbox.count > 250 { inbox = Array(inbox.prefix(250)) }
        save()
    }

    func toggleRead(_ id: UUID) {
        guard let index = inbox.firstIndex(where: { $0.id == id }) else { return }
        inbox[index].isRead.toggle()
        save()
    }

    func addAutomation(name: String, trigger: String, action: String) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        automations.insert(MOMEAutomation(name: trimmed, trigger: trigger, action: action), at: 0)
        record(source: "Automation", title: "Automation created", body: trimmed)
        save()
    }

    func toggleAutomation(_ id: UUID) {
        guard let index = automations.firstIndex(where: { $0.id == id }) else { return }
        automations[index].isEnabled.toggle()
        save()
    }

    func runAutomation(_ id: UUID) {
        guard let index = automations.firstIndex(where: { $0.id == id }),
              automations[index].isEnabled else { return }
        automations[index].runCount += 1
        automations[index].lastRunAt = Date()
        let item = automations[index]
        record(
            source: "Automation",
            title: item.name,
            body: "Triggered: \(item.trigger) → \(item.action)"
        )
        save()
    }

    func addAgent(name: String, role: String, instructions: String) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        agents.insert(MOMEAgent(name: trimmed, role: role, instructions: instructions), at: 0)
        record(source: "Agent", title: "Agent created", body: trimmed)
        save()
    }

    func toggleAgent(_ id: UUID) {
        guard let index = agents.firstIndex(where: { $0.id == id }) else { return }
        agents[index].isEnabled.toggle()
        save()
    }

    func cycleIntegrationState(_ id: UUID) {
        guard let index = integrations.firstIndex(where: { $0.id == id }) else { return }
        switch integrations[index].state {
        case .disconnected: integrations[index].state = .configured
        case .configured: integrations[index].state = .connected
        case .connected: integrations[index].state = .disconnected
        case .error: integrations[index].state = .configured
        }
        let item = integrations[index]
        record(source: "Integration", title: item.name, body: "State changed to \(item.state.rawValue)")
        save()
    }

    func addRevenue(label: String, amount: Double) {
        let trimmed = label.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        revenue.insert(RevenueEntry(label: trimmed, amount: amount), at: 0)
        record(source: "Revenue", title: trimmed, body: String(format: "R %.2f", amount))
        save()
    }

    func addRoadmap(title: String, detail: String) {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        roadmap.insert(CommunityRoadmapItem(title: trimmed, detail: detail), at: 0)
        save()
    }

    func vote(_ id: UUID) {
        guard let index = roadmap.firstIndex(where: { $0.id == id }) else { return }
        roadmap[index].votes += 1
        save()
    }

    func advance(_ id: UUID) {
        guard let index = roadmap.firstIndex(where: { $0.id == id }) else { return }
        switch roadmap[index].status {
        case .proposed: roadmap[index].status = .planned
        case .planned: roadmap[index].status = .building
        case .building: roadmap[index].status = .shipped
        case .shipped: roadmap[index].status = .proposed
        }
        save()
    }

    var monthlyRevenue: Double {
        let calendar = Calendar.current
        return revenue
            .filter { calendar.isDate($0.createdAt, equalTo: Date(), toGranularity: .month) }
            .reduce(0) { $0 + $1.amount }
    }

    private func seedCatalogsIfNeeded() {
        if integrations.isEmpty {
            integrations = [
                ServiceIntegration(name: "GitHub", category: "Development", authType: "OAuth / gh", capabilities: ["Repositories", "Pull requests", "Actions"]),
                ServiceIntegration(name: "Slack", category: "Messaging", authType: "OAuth", capabilities: ["Messages", "Channels", "Notifications"]),
                ServiceIntegration(name: "Gmail", category: "Email", authType: "OAuth", capabilities: ["Read", "Send", "Labels"]),
                ServiceIntegration(name: "WhatsApp Business", category: "Messaging", authType: "OAuth", capabilities: ["Messages", "Media"]),
                ServiceIntegration(name: "HubSpot", category: "CRM", authType: "OAuth", capabilities: ["Contacts", "Deals", "Forms"]),
                ServiceIntegration(name: "Salesforce", category: "CRM", authType: "OAuth", capabilities: ["Leads", "Accounts", "Reports"]),
                ServiceIntegration(name: "Stripe", category: "Payments", authType: "API key", capabilities: ["Payments", "Subscriptions", "Invoices"]),
                ServiceIntegration(name: "Paystack", category: "Payments", authType: "API key", capabilities: ["Payments", "Transfers", "Settlements"]),
                ServiceIntegration(name: "Flutterwave", category: "Payments", authType: "API key", capabilities: ["Payments", "Transfers", "Collections"]),
                ServiceIntegration(name: "Google Analytics", category: "Analytics", authType: "OAuth", capabilities: ["Traffic", "Events", "Conversions"]),
                ServiceIntegration(name: "Zapier / Webhooks", category: "Automation", authType: "Webhook", capabilities: ["Triggers", "Actions", "Webhooks"])
            ]
        }
        if roadmap.isEmpty {
            roadmap = [
                CommunityRoadmapItem(title: "Plugin SDK", detail: "Stable extension API for community-maintained integrations.", status: .planned, votes: 0),
                CommunityRoadmapItem(title: "Shared automation packs", detail: "Export and import permission-gated MOME automation templates.", status: .proposed, votes: 0)
            ]
        }
        save()
    }

    private func load() {
        guard let data = try? Data(contentsOf: storageURL) else { return }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        guard let snapshot = try? decoder.decode(NausicaaSnapshot.self, from: data) else { return }
        workspaces = snapshot.workspaces
        inbox = snapshot.inbox
        automations = snapshot.automations
        agents = snapshot.agents
        integrations = snapshot.integrations
        revenue = snapshot.revenue
        roadmap = snapshot.roadmap
    }

    private func save() {
        let snapshot = NausicaaSnapshot(
            workspaces: workspaces,
            inbox: inbox,
            automations: automations,
            agents: agents,
            integrations: integrations,
            revenue: revenue,
            roadmap: roadmap
        )
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        guard let data = try? encoder.encode(snapshot) else { return }
        try? data.write(to: storageURL, options: .atomic)
    }
}

struct WorkspacesView: View {
    @EnvironmentObject private var nausicaa: NausicaaStore
    @State private var name = ""
    @State private var detail = ""

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                pageHeader("WORKSPACES", "Organize projects, teams and operating contexts.")
                MOMECard("Create workspace") {
                    TextField("Workspace name", text: $name)
                    TextField("Description", text: $detail)
                    Button("Create Workspace") {
                        nausicaa.addWorkspace(name: name, detail: detail)
                        name = ""; detail = ""
                    }.buttonStyle(.borderedProminent)
                }
                ForEach(nausicaa.workspaces) { workspace in
                    MOMECard {
                        HStack {
                            VStack(alignment: .leading) {
                                Text(workspace.name).font(.headline)
                                Text(workspace.detail.isEmpty ? "No description" : workspace.detail).foregroundStyle(.secondary)
                            }
                            Spacer()
                            Button(role: .destructive) { nausicaa.removeWorkspace(workspace.id) } label: {
                                Image(systemName: "trash")
                            }
                        }
                    }
                }
            }
        }.momePage()
    }
}

struct UnifiedInboxView: View {
    @EnvironmentObject private var nausicaa: NausicaaStore

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                pageHeader("UNIFIED INBOX", "One activity stream for MOME workspaces, automations, agents and integrations.")
                if nausicaa.inbox.isEmpty {
                    EmptyState(title: "Inbox is clear", detail: "MOME records local activity here as you use migrated Nausicaa features.")
                } else {
                    ForEach(nausicaa.inbox) { item in
                        MOMECard {
                            HStack(alignment: .top) {
                                VStack(alignment: .leading, spacing: 5) {
                                    HStack {
                                        Text(item.source.uppercased()).font(.caption.bold()).foregroundStyle(.secondary)
                                        if !item.isRead { Text("NEW").font(.caption2.bold()).padding(.horizontal, 5).background(.blue.opacity(0.14), in: Capsule()) }
                                    }
                                    Text(item.title).font(.headline)
                                    Text(item.body).foregroundStyle(.secondary)
                                    Text(item.createdAt.formatted()).font(.caption2).foregroundStyle(.tertiary)
                                }
                                Spacer()
                                Button(item.isRead ? "Unread" : "Read") { nausicaa.toggleRead(item.id) }
                            }
                        }
                    }
                }
            }
        }.momePage()
    }
}

struct AutomationsHubView: View {
    @EnvironmentObject private var nausicaa: NausicaaStore
    @State private var name = ""
    @State private var trigger = ""
    @State private var action = ""

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                pageHeader("AUTOMATION HUB", "Create explicit trigger → action workflows with visible state.")
                MOMECard("New automation") {
                    TextField("Name", text: $name)
                    TextField("Trigger", text: $trigger)
                    TextField("Action", text: $action)
                    Button("Create Automation") {
                        nausicaa.addAutomation(name: name, trigger: trigger, action: action)
                        name = ""; trigger = ""; action = ""
                    }.buttonStyle(.borderedProminent)
                }
                ForEach(nausicaa.automations) { item in
                    MOMECard {
                        HStack {
                            VStack(alignment: .leading, spacing: 5) {
                                Text(item.name).font(.headline)
                                Text("\(item.trigger) → \(item.action)").foregroundStyle(.secondary)
                                Text("Runs: \(item.runCount)").font(.caption)
                            }
                            Spacer()
                            Toggle("Enabled", isOn: Binding(
                                get: { item.isEnabled },
                                set: { _ in nausicaa.toggleAutomation(item.id) }
                            )).labelsHidden()
                            Button("Run") { nausicaa.runAutomation(item.id) }
                                .disabled(!item.isEnabled)
                        }
                    }
                }
            }
        }.momePage()
    }
}

struct AgentsHubView: View {
    @EnvironmentObject private var model: AppModel
    @EnvironmentObject private var nausicaa: NausicaaStore
    @State private var name = ""
    @State private var role = ""
    @State private var instructions = ""

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                pageHeader("AI AGENTS", "Define reusable agent roles, then execute conversations through Forge AI.")
                MOMECard("New agent") {
                    TextField("Agent name", text: $name)
                    TextField("Role", text: $role)
                    TextField("Instructions", text: $instructions)
                    Button("Create Agent") {
                        nausicaa.addAgent(name: name, role: role, instructions: instructions)
                        name = ""; role = ""; instructions = ""
                    }.buttonStyle(.borderedProminent)
                }
                ForEach(nausicaa.agents) { agent in
                    MOMECard {
                        HStack {
                            VStack(alignment: .leading, spacing: 5) {
                                Text(agent.name).font(.headline)
                                Text(agent.role).foregroundStyle(.secondary)
                                Text(agent.instructions).font(.caption)
                            }
                            Spacer()
                            Toggle("Enabled", isOn: Binding(
                                get: { agent.isEnabled },
                                set: { _ in nausicaa.toggleAgent(agent.id) }
                            )).labelsHidden()
                            Button("Open in Forge AI") { model.section = .ai }
                                .disabled(!agent.isEnabled)
                        }
                    }
                }
            }
        }.momePage()
    }
}

struct ServiceIntegrationsView: View {
    @EnvironmentObject private var nausicaa: NausicaaStore

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                pageHeader("SERVICE CONNECTORS", "Nausicaa's business-service catalog, migrated into MOME without pretending credentials are connected.")
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 300), spacing: 12)], spacing: 12) {
                    ForEach(nausicaa.integrations) { item in
                        MOMECard {
                            HStack {
                                VStack(alignment: .leading, spacing: 5) {
                                    Text(item.name).font(.headline)
                                    Text("\(item.category) · \(item.authType)").font(.caption).foregroundStyle(.secondary)
                                    Text(item.capabilities.joined(separator: " · ")).font(.caption)
                                }
                                Spacer()
                            }
                            HStack {
                                Text(item.state.rawValue.capitalized)
                                    .font(.caption.bold())
                                Spacer()
                                Button(item.state == .connected ? "Disconnect" : "Advance Setup") {
                                    nausicaa.cycleIntegrationState(item.id)
                                }
                            }
                        }
                    }
                }
                Text("Connector state is local metadata until a provider-specific OAuth/API implementation is installed. MOME never fabricates a successful external connection.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }.momePage()
    }
}

struct RevenueIntelligenceView: View {
    @EnvironmentObject private var nausicaa: NausicaaStore
    @State private var label = ""
    @State private var amount = ""

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                pageHeader("REVENUE INTELLIGENCE", "Local-first revenue tracking for product and business workspaces.")
                HStack(spacing: 14) {
                    MetricCard(value: String(format: "R %.0f", nausicaa.monthlyRevenue), label: "This Month", symbol: "chart.line.uptrend.xyaxis")
                    MetricCard(value: "\(nausicaa.revenue.count)", label: "Entries", symbol: "list.bullet.rectangle")
                }
                MOMECard("Record revenue") {
                    TextField("Label", text: $label)
                    TextField("Amount in ZAR", text: $amount)
                    Button("Add Entry") {
                        if let value = Double(amount.replacingOccurrences(of: ",", with: ".")) {
                            nausicaa.addRevenue(label: label, amount: value)
                            label = ""; amount = ""
                        }
                    }.buttonStyle(.borderedProminent)
                }
                ForEach(nausicaa.revenue) { item in
                    MOMECard {
                        HStack {
                            VStack(alignment: .leading) {
                                Text(item.label).font(.headline)
                                Text(item.createdAt.formatted(date: .abbreviated, time: .omitted)).font(.caption).foregroundStyle(.secondary)
                            }
                            Spacer()
                            Text(String(format: "R %.2f", item.amount)).font(.headline.monospacedDigit())
                        }
                    }
                }
            }
        }.momePage()
    }
}

struct CommunityRoadmapView: View {
    @EnvironmentObject private var nausicaa: NausicaaStore
    @State private var title = ""
    @State private var detail = ""

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                pageHeader("COMMUNITY ROADMAP", "Capture, vote on and advance feature proposals.")
                MOMECard("Propose feature") {
                    TextField("Feature title", text: $title)
                    TextField("Why it matters", text: $detail)
                    Button("Add Proposal") {
                        nausicaa.addRoadmap(title: title, detail: detail)
                        title = ""; detail = ""
                    }.buttonStyle(.borderedProminent)
                }
                ForEach(nausicaa.roadmap.sorted(by: { $0.votes > $1.votes })) { item in
                    MOMECard {
                        HStack(alignment: .top) {
                            VStack(alignment: .leading, spacing: 5) {
                                Text(item.title).font(.headline)
                                Text(item.detail).foregroundStyle(.secondary)
                                Text(item.status.rawValue.uppercased()).font(.caption.bold())
                            }
                            Spacer()
                            Button("▲ \(item.votes)") { nausicaa.vote(item.id) }
                            Button("Advance") { nausicaa.advance(item.id) }
                        }
                    }
                }
            }
        }.momePage()
    }
}

@ViewBuilder
private func pageHeader(_ eyebrow: String, _ subtitle: String) -> some View {
    VStack(alignment: .leading, spacing: 5) {
        Text(eyebrow).font(.caption.weight(.semibold)).foregroundStyle(.secondary).tracking(1.2)
        Text(eyebrow.capitalized).font(.system(size: 30, weight: .bold, design: .rounded))
        Text(subtitle).foregroundStyle(.secondary)
    }
}
