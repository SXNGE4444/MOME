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
        risk: CommandRisk = .safe,
        environment extraEnvironment: [String: String] = [:]
    ) {
        launch(
            title: title,
            displayCommand: command,
            executable: "/bin/zsh",
            arguments: ["-lc", command],
            workingDirectory: workingDirectory,
            risk: risk,
            environment: extraEnvironment,
            interactive: false
        )
    }

    /// Starts a persistent login shell through macOS `script`, which allocates a real PTY.
    /// This is deliberately different from one-shot build/deploy jobs so interactive CLIs,
    /// prompts, REPLs, dev servers and terminal control sequences behave like a terminal.
    @discardableResult
    func startShell(
        title: String = "Shell",
        workingDirectory: URL? = nil,
        environment extraEnvironment: [String: String] = [:]
    ) -> UUID {
        let shell = ProcessInfo.processInfo.environment["SHELL"] ?? "/bin/zsh"
        return launch(
            title: title,
            displayCommand: shell + " -l",
            executable: "/usr/bin/script",
            arguments: ["-q", "/dev/null", shell, "-l"],
            workingDirectory: workingDirectory,
            risk: .safe,
            environment: extraEnvironment,
            interactive: true
        )
    }

    func stop(_ id: UUID) {
        processes[id]?.terminate()
        if let index = sessions.firstIndex(where: { $0.id == id }) {
            sessions[index].state = .stopped
            sessions[index].output += "\n[session stopped by user]\n"
        }
        cleanup(id)
    }

    func send(_ text: String, to id: UUID) {
        guard let pipe = inputPipes[id],
              let data = (text + "\n").data(using: .utf8) else { return }
        do {
            try pipe.fileHandleForWriting.write(contentsOf: data)
        } catch {
            append("\n[input failed: \(error.localizedDescription)]\n", to: id)
        }
    }

    func sendInterrupt(to id: UUID) {
        guard let process = processes[id] else { return }
        process.interrupt()
    }

    func clearCompleted() {
        sessions.removeAll { $0.state != .running }
    }

    func clearOutput(_ id: UUID) {
        guard let index = sessions.firstIndex(where: { $0.id == id }) else { return }
        sessions[index].output = ""
    }

    @discardableResult
    private func launch(
        title: String,
        displayCommand: String,
        executable: String,
        arguments: [String],
        workingDirectory: URL?,
        risk: CommandRisk,
        environment extraEnvironment: [String: String],
        interactive: Bool
    ) -> UUID {
        let id = UUID()
        let directory = workingDirectory ?? FileManager.default.homeDirectoryForCurrentUser
        var session = ProcessSession(
            id: id,
            title: title,
            command: displayCommand,
            workingDirectory: directory.path,
            risk: risk,
            output: interactive ? "[PTY shell started in \(directory.path)]\n" : "$ \(displayCommand)\n\n",
            state: .running,
            startedAt: Date(),
            exitCode: nil,
            interactive: interactive
        )
        sessions.insert(session, at: 0)

        let process = Process()
        let outputPipe = Pipe()
        let inputPipe = Pipe()

        process.executableURL = URL(fileURLWithPath: executable)
        process.arguments = arguments
        process.currentDirectoryURL = directory
        process.environment = ProcessInfo.processInfo.environment
            .merging(["TERM": "xterm-256color", "CLICOLOR": "1"]) { _, new in new }
            .merging(extraEnvironment) { _, new in new }
        process.standardOutput = outputPipe
        process.standardError = outputPipe
        process.standardInput = inputPipe

        outputPipe.fileHandleForReading.readabilityHandler = { [weak self] handle in
            let data = handle.availableData
            guard !data.isEmpty, let text = String(data: data, encoding: .utf8) else { return }
            Task { @MainActor in self?.append(text, to: id) }
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
        return id
    }

    private func append(_ text: String, to id: UUID) {
        guard let index = sessions.firstIndex(where: { $0.id == id }) else { return }
        sessions[index].output += text
        if sessions[index].output.count > 500_000 {
            sessions[index].output = String(sessions[index].output.suffix(400_000))
        }
    }

    private func finish(id: UUID, code: Int32) {
        guard let index = sessions.firstIndex(where: { $0.id == id }) else { return }
        if sessions[index].state != .stopped {
            sessions[index].state = code == 0 ? .succeeded : .failed
        }
        sessions[index].exitCode = code
        sessions[index].output += "\n[process exited \(code)]\n"
        cleanup(id)
    }

    private func cleanup(_ id: UUID) {
        processes[id] = nil
        if let pipe = inputPipes.removeValue(forKey: id) {
            try? pipe.fileHandleForWriting.close()
        }
    }
}
