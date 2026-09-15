import Foundation
import AppKit
import Combine

@MainActor
final class WorkspaceStore: ObservableObject {
    @Published private(set) var projects: [MOMEProject] = []

    private let fileManager = FileManager.default
    private let storageURL: URL

    init() {
        let root = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("MOME", isDirectory: true)
        try? fileManager.createDirectory(at: root, withIntermediateDirectories: true)
        storageURL = root.appendingPathComponent("projects.json")
        load()
    }

    func pickAndAddProject() {
        let panel = NSOpenPanel()
        panel.title = "Add a project to MOME"
        panel.prompt = "Add Project"
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.canCreateDirectories = false

        if panel.runModal() == .OK, let url = panel.url {
            addProject(at: url)
        }
    }

    func addProject(at url: URL) {
        guard !projects.contains(where: { $0.path == url.path }) else { return }
        var project = projectFromForgeConfig(at: url) ?? MOMEProject(
            name: url.lastPathComponent,
            path: url.path,
            kind: inferKind(at: url)
        )
        project.path = url.path
        projects.insert(project, at: 0)
        save()
    }

    func removeProject(_ id: UUID) {
        projects.removeAll { $0.id == id }
        save()
    }

    func addTask(projectID: UUID, title: String, kind: TaskKind) {
        guard let index = projects.firstIndex(where: { $0.id == projectID }) else { return }
        projects[index].tasks.append(ProjectTask(title: title, kind: kind))
        save()
    }

    func moveTask(projectID: UUID, taskID: UUID, to stage: TaskStage) {
        guard let p = projects.firstIndex(where: { $0.id == projectID }),
              let t = projects[p].tasks.firstIndex(where: { $0.id == taskID }) else { return }
        projects[p].tasks[t].stage = stage
        save()
    }

    func project(_ id: UUID?) -> MOMEProject? {
        guard let id else { return nil }
        return projects.first { $0.id == id }
    }

    private func projectFromForgeConfig(at directory: URL) -> MOMEProject? {
        let configURL = directory.appendingPathComponent("forge.json")
        guard let data = try? Data(contentsOf: configURL),
              let config = try? JSONDecoder().decode(ForgeConfiguration.self, from: data) else {
            return nil
        }

        return MOMEProject(
            name: config.name,
            path: directory.path,
            kind: config.type,
            repository: config.repository,
            commands: config.commands ?? [:],
            editors: config.editors ?? [],
            deployment: config.deployment ?? [:]
        )
    }

    private func inferKind(at directory: URL) -> ProjectKind {
        func exists(_ path: String) -> Bool {
            fileManager.fileExists(atPath: directory.appendingPathComponent(path).path)
        }

        if exists("project.godot") || exists("Assets") && exists("ProjectSettings") { return .game }
        if (try? fileManager.contentsOfDirectory(atPath: directory.path).contains(where: { $0.hasSuffix(".uproject") })) == true { return .game }
        if exists("Package.swift") && (exists("Sources") || exists("Package.resolved")) { return .nativeMac }
        if exists("android") || exists("ios") || exists("app.json") { return .mobile }
        if exists("package.json") || exists("wrangler.toml") || exists("vercel.json") { return .web }
        if (try? fileManager.contentsOfDirectory(atPath: directory.path).contains(where: { $0.hasSuffix(".blend") })) == true { return .threeD }
        return .unknown
    }

    private func load() {
        guard let data = try? Data(contentsOf: storageURL),
              let decoded = try? JSONDecoder().decode([MOMEProject].self, from: data) else {
            return
        }
        projects = decoded
    }

    private func save() {
        guard let data = try? JSONEncoder.pretty.encode(projects) else { return }
        try? data.write(to: storageURL, options: .atomic)
    }
}

private extension JSONEncoder {
    static var pretty: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }
}
