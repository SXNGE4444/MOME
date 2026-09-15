import Foundation

protocol MOMEAdapter {
    var id: ToolID { get }
    var name: String { get }
    func actions(for project: MOMEProject) -> [ToolAction]
}

struct AdapterRegistry {
    static let all: [any MOMEAdapter] = [
        XcodeAdapter(),
        VSCodeAdapter(),
        AndroidStudioAdapter(),
        BlenderAdapter(),
        UnityAdapter(),
        UnrealAdapter(),
        GitAdapter(),
        CloudflareAdapter(),
        VercelAdapter()
    ]

    static func actions(for project: MOMEProject) -> [ToolAction] {
        var actions = all.flatMap { $0.actions(for: project) }
        actions += project.commands.sorted(by: { $0.key < $1.key }).map { name, command in
            ToolAction(title: name.capitalized, command: command, risk: .safe, symbol: "play.circle")
        }
        return actions
    }
}

struct XcodeAdapter: MOMEAdapter {
    let id: ToolID = .xcode
    let name = "Xcode"
    func actions(for project: MOMEProject) -> [ToolAction] {
        [
            ToolAction(title: "Open in Xcode", command: "open -a Xcode .", risk: .read, tool: id, symbol: "hammer"),
            ToolAction(title: "Inspect Xcode Project", command: "xcodebuild -list", risk: .read, tool: id, symbol: "list.bullet"),
            ToolAction(title: "Run Tests", command: "xcodebuild test", risk: .safe, tool: id, symbol: "checkmark.circle")
        ]
    }
}

struct VSCodeAdapter: MOMEAdapter {
    let id: ToolID = .vscode
    let name = "VS Code"
    func actions(for project: MOMEProject) -> [ToolAction] {
        [ToolAction(title: "Open in VS Code", command: "code .", risk: .read, tool: id, symbol: "chevron.left.forwardslash.chevron.right")]
    }
}

struct AndroidStudioAdapter: MOMEAdapter {
    let id: ToolID = .androidStudio
    let name = "Android Studio"
    func actions(for project: MOMEProject) -> [ToolAction] {
        [
            ToolAction(title: "Open Android Studio", command: "open -a 'Android Studio' .", risk: .read, tool: id, symbol: "apps.iphone"),
            ToolAction(title: "Build Debug APK", command: "test -x ./gradlew && ./gradlew assembleDebug || (cd android && ./gradlew assembleDebug)", risk: .safe, tool: id, symbol: "shippingbox")
        ]
    }
}

struct BlenderAdapter: MOMEAdapter {
    let id: ToolID = .blender
    let name = "Blender"
    func actions(for project: MOMEProject) -> [ToolAction] {
        [ToolAction(title: "Open Blender", command: "open -a Blender", risk: .read, tool: id, symbol: "cube")]
    }
}

struct UnityAdapter: MOMEAdapter {
    let id: ToolID = .unity
    let name = "Unity"
    func actions(for project: MOMEProject) -> [ToolAction] {
        [ToolAction(title: "Open Unity Hub", command: "open -a 'Unity Hub'", risk: .read, tool: id, symbol: "cube.transparent")]
    }
}

struct UnrealAdapter: MOMEAdapter {
    let id: ToolID = .unreal
    let name = "Unreal Engine"
    func actions(for project: MOMEProject) -> [ToolAction] {
        [ToolAction(title: "Open Epic Games Launcher", command: "open -a 'Epic Games Launcher'", risk: .read, tool: id, symbol: "gamecontroller")]
    }
}

struct GitAdapter: MOMEAdapter {
    let id: ToolID = .git
    let name = "Git"
    func actions(for project: MOMEProject) -> [ToolAction] {
        [
            ToolAction(title: "Git Status", command: "git status --short --branch", risk: .read, tool: id, symbol: "arrow.triangle.branch"),
            ToolAction(title: "Git Pull", command: "git pull --ff-only", risk: .write, tool: id, symbol: "arrow.down.circle")
        ]
    }
}

struct CloudflareAdapter: MOMEAdapter {
    let id: ToolID = .wrangler
    let name = "Cloudflare"
    func actions(for project: MOMEProject) -> [ToolAction] {
        [
            ToolAction(title: "Cloudflare Dev", command: "wrangler dev", risk: .safe, tool: id, symbol: "cloud"),
            ToolAction(title: "Deploy Cloudflare", command: "wrangler deploy", risk: .release, tool: id, symbol: "cloud.upload")
        ]
    }
}

struct VercelAdapter: MOMEAdapter {
    let id: ToolID = .vercel
    let name = "Vercel"
    func actions(for project: MOMEProject) -> [ToolAction] {
        [
            ToolAction(title: "Vercel Dev", command: "vercel dev", risk: .safe, tool: id, symbol: "play.rectangle"),
            ToolAction(title: "Deploy Vercel Preview", command: "vercel", risk: .write, tool: id, symbol: "arrow.up.right"),
            ToolAction(title: "Deploy Vercel Production", command: "vercel --prod", risk: .release, tool: id, symbol: "bolt.horizontal.circle")
        ]
    }
}
