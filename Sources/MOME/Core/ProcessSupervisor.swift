import Foundation
import Combine

@MainActor
final class ProcessSupervisor: ObservableObject {
    @Published private(set) var sessions: [ProcessSession] = []

    private var processes: [UUID: Process] = [:]
    private var inputPipes: [UUID: Pipe] = [:]

    func start(
        title: String,
        command: String,
        workingDirectory: URL? = nil,
        risk: CommandRisk = .safe
    ) {
        let id = UUID()
        let directory = workingDirectory ?? FileManager.default.homeDirectoryForCurrentUser
        var session = ProcessSession(
            id: id,
            title: title,
            command: command,
            workingDirectory: directory.path,
            risk: risk,
            output: "$ \(command)\n\n",
            state: .running,
            startedAt: Date(),
            exitCode: nil
        )
        sessions.insert(session, at: 0)

        let process = Process()
        let outputPipe = Pipe()
        let inputPipe = Pipe()

        process.executableURL = URL(fileURLWithPath: "/bin/zsh")
        process.arguments = ["-lc", command]
        process.currentDirectoryURL = directory
        process.environment = ProcessInfo.processInfo.environment.merging([
            "TERM": "xterm-256color"
        ]) { _, new in new }
        process.standardOutput = outputPipe
        process.standardError = outputPipe
        process.standardInput = inputPipe

        outputPipe.fileHandleForReading.readabilityHandler = { [weak self] handle in
            let data = handle.availableData
            guard !data.isEmpty, let text = String(data: data, encoding: .utf8) else { return }
            Task { @MainActor in
                self?.append(text, to: id)
            }
        }

        process.terminationHandler = { [weak self] terminated in
            Task { @MainActor in
                outputPipe.fileHandleForReading.readabilityHandler = nil
                self?.finish(id: id, code: terminated.terminationStatus)
            }
        }

        do {
            try process.run()
            processes[id] = process
            inputPipes[id] = inputPipe
        } catch {
            session.state = .failed
            session.output += "Failed to launch: \(error.localizedDescription)\n"
            if let index = sessions.firstIndex(where: { $0.id == id }) {
                sessions[index] = session
            }
        }
    }

    func stop(_ id: UUID) {
        processes[id]?.terminate()
        if let index = sessions.firstIndex(where: { $0.id == id }) {
            sessions[index].state = .stopped
            sessions[index].output += "\nProcess stopped by user.\n"
        }
        processes[id] = nil
        inputPipes[id] = nil
    }

    func send(_ text: String, to id: UUID) {
        guard let data = (text + "\n").data(using: .utf8) else { return }
        inputPipes[id]?.fileHandleForWriting.write(data)
    }

    func clearCompleted() {
        sessions.removeAll { $0.state != .running }
    }

    private func append(_ text: String, to id: UUID) {
        guard let index = sessions.firstIndex(where: { $0.id == id }) else { return }
        sessions[index].output += text
        if sessions[index].output.count > 250_000 {
            sessions[index].output = String(sessions[index].output.suffix(200_000))
        }
    }

    private func finish(id: UUID, code: Int32) {
        guard let index = sessions.firstIndex(where: { $0.id == id }) else { return }
        if sessions[index].state != .stopped {
            sessions[index].state = code == 0 ? .succeeded : .failed
        }
        sessions[index].exitCode = code
        sessions[index].output += "\n[process exited \(code)]\n"
        processes[id] = nil
        inputPipes[id] = nil
    }
}
