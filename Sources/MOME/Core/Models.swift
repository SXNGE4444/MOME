import Foundation

// MARK: - Navigation

enum SidebarSection: String, CaseIterable, Identifiable, Hashable {
    case dashboard = "Command Center"
    case projects = "Projects"
    case workspaces = "Workspaces"
    case inbox = "Inbox"
    case automations = "Automations"
    case agents = "Agents"
    case services = "Service Connectors"
    case revenue = "Revenue"
    case roadmap = "Roadmap"
    case plan = "Plan"
    case terminal = "Terminal"
    case devices = "Devices"
    case tools = "Integrations"
    case ai = "Forge AI"
    case deploy = "Deployments"
    case learn = "Learn"

    var id: String { rawValue }

    var symbol: String {
        switch self {
        case .dashboard: return "square.grid.2x2"
        case .projects: return "shippingbox"
        case .workspaces: return "person.3"
        case .inbox: return "tray.full"
        case .automations: return "bolt.horizontal.circle"
        case .agents: return "person.crop.circle.badge.sparkles"
        case .services: return "link"
        case .revenue: return "chart.line.uptrend.xyaxis"
        case .roadmap: return "map"
        case .plan: return "checklist"
        case .terminal: return "terminal"
        case .devices: return "rectangle.connected.to.line.below"
        case .tools: return "puzzlepiece.extension"
        case .ai: return "sparkles"
        case .deploy: return "cloud"
        case .learn: return "graduationcap"
        }
    }
}

// MARK: - Projects

enum ProjectKind: String, Codable, CaseIterable, Hashable {
    case mobile
    case web
    case nativeMac = "native-mac"
    case game
    case threeD = "3d"
    case backend
    case unknown

    var label: String {
        switch self {
        case .nativeMac: return "macOS"
        case .threeD: return "3D"
        default: return rawValue.capitalized
        }
    }
}

enum TaskStage: String, Codable, CaseIterable, Identifiable, Hashable {
    case backlog
    case building
    case testing
    case ready
    case released

    var id: String { rawValue }
    var label: String { rawValue.capitalized }
}

enum TaskKind: String, Codable, CaseIterable, Identifiable, Hashable {
    case product
    case design
    case content
    case engineering
    case release

    var id: String { rawValue }
}

struct ProjectTask: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var title: String
    var kind: TaskKind = .engineering
    var stage: TaskStage = .backlog
    var createdAt: Date = Date()
}

struct MOMEProject: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var name: String
    var path: String
    var kind: ProjectKind = .unknown
    var repository: String?
    var commands: [String: String] = [:]
    var editors: [String] = []
    var deployment: [String: String] = [:]
    var settings: [String: String]?
    var tasks: [ProjectTask] = []
    var createdAt: Date = Date()

    var folderURL: URL { URL(fileURLWithPath: path) }

    func setting(_ key: String) -> String? {
        settings?[key]?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty
    }
}

struct ForgeConfiguration: Codable {
    var name: String
    var type: ProjectKind
    var repository: String?
    var commands: [String: String]?
    var editors: [String]?
    var deployment: [String: String]?
    var settings: [String: String]?
}

// MARK: - Tools

enum ToolCategory: String, Codable, CaseIterable, Hashable {
    case editor = "Editors"
    case apple = "Apple"
    case android = "Android"
    case engine3D = "3D / Engines"
    case runtime = "Runtimes"
    case ai = "AI Runtimes"
    case cloud = "Cloud"
    case source = "Source Control"
    case release = "Release & Distribution"
}

enum ToolID: String, Codable, CaseIterable, Hashable {
    case xcode
    case vscode
    case androidStudio
    case blender
    case unity
    case unreal
    case git
    case github
    case node
    case pnpm
    case python
    case wrangler
    case vercel
    case adb
    case emulator
    case podman
    case docker
    case eas
    case supabase
    case fastlane
    case huggingFace
    case lmStudio
    case ollama
    case vllm
    case llamaServer
    case localAI
    case jan
    case mlxLM
    case tgi
}

enum InstallationState: String, Codable, Hashable {
    case installed
    case missing
}

struct ToolDescriptor: Identifiable, Codable, Hashable {
    var id: ToolID
    var name: String
    var category: ToolCategory
    var state: InstallationState
    var location: String?
    var version: String?

    var isInstalled: Bool { state == .installed }
}

// MARK: - Commands / Safety

enum CommandRisk: String, Codable, CaseIterable, Hashable {
    case read
    case safe
    case write
    case release
    case dangerous

    var requiresApproval: Bool {
        switch self {
        case .read, .safe: return false
        case .write, .release, .dangerous: return true
        }
    }
}

struct SecretBinding: Hashable {
    var environmentVariable: String
    var keychainAccount: String
}

struct ToolAction: Identifiable, Hashable {
    let id = UUID()
    var title: String
    var command: String
    var risk: CommandRisk
    var tool: ToolID?
    var symbol: String = "play.fill"
    var help: String? = nil
    var secretBindings: [SecretBinding] = []
}

struct PendingAction: Identifiable {
    let id = UUID()
    var action: ToolAction
    var project: MOMEProject?
}

// MARK: - Devices

enum DevicePlatform: String, Codable, Hashable {
    case iOS
    case android
}

struct DeviceInfo: Identifiable, Hashable {
    var id: String
    var name: String
    var platform: DevicePlatform
    var state: String
    var runtime: String?
    var virtual: Bool = true

    var isBooted: Bool {
        let value = state.lowercased()
        return value.contains("booted") || value == "device" || value == "online" || value == "running"
    }

    var isAndroidAVDDefinition: Bool {
        platform == .android && id.hasPrefix("avd:")
    }
}

// MARK: - Processes

enum SessionState: String, Hashable {
    case running
    case succeeded
    case failed
    case stopped
}

struct ProcessSession: Identifiable {
    let id: UUID
    var title: String
    var command: String
    var workingDirectory: String
    var risk: CommandRisk
    var output: String
    var state: SessionState
    var startedAt: Date
    var exitCode: Int32?
    var interactive: Bool = false
}

private extension String {
    var nilIfEmpty: String? { isEmpty ? nil : self }
}
