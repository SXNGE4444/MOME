# MOME Architecture

## Product definition

MOME is a native macOS orchestration layer between a developer's projects and the tools used to ship them. It does not attempt to replace Xcode, Android Studio, VS Code, Blender, Unity or Unreal Engine. It discovers those tools, understands registered projects, runs explicit commands in project context, captures logs, connects build output to AI analysis, and gates privileged actions.

## Design system

The UI follows **Technical Minimalist × Modern Obsidian × Reality-First**:

- information density without decorative dashboards;
- system-native macOS typography/materials;
- status only when backed by actual local detection or command output;
- explicit command/risk visibility before execution;
- project context remains visible across build, device and deployment workflows.

## Runtime layers

```text
SwiftUI / AppKit
       │
       ▼
AppModel + WorkspaceStore
       │
       ├── ToolScanner
       ├── DeviceScanner
       ├── ProcessSupervisor
       ├── KeychainVault
       ├── AIService
       └── AdapterRegistry
              │
              ├── Xcode / simctl
              ├── Android Studio / adb / Gradle
              ├── VS Code / Git
              ├── Blender / Unity / Unreal
              ├── Cloudflare Wrangler
              └── Vercel CLI
```

## Project configuration

A project can declare a `forge.json` in its root. MOME reads this file when the project is imported.

```json
{
  "name": "Example",
  "type": "web",
  "repository": "git@github.com:owner/repo.git",
  "commands": {
    "dev": "pnpm dev",
    "test": "pnpm test"
  },
  "editors": ["vscode"],
  "deployment": {
    "web": "vercel"
  }
}
```

Secrets are deliberately excluded. Credentials belong in macOS Keychain.

## Safety model

Every tool action has a risk class:

- `read`: inspect status, logs, metadata, or open an application.
- `safe`: builds, tests and local development processes.
- `write`: source/environment-changing operations.
- `release`: production deployment, TestFlight/App Store or equivalent shipping action.
- `dangerous`: destructive operations such as database resets or irreversible deletion.

`write`, `release` and `dangerous` commands require approval. AI output is advisory; the AI layer does not bypass the command gate.

## Process execution

The MVP uses `Process` with streamed stdout/stderr through pipes. A PTY-backed terminal is the next runtime milestone for full interactive shell fidelity, terminal resizing and advanced TUI applications.

## Distribution direction

The intended production path is direct macOS distribution with Developer ID signing, Hardened Runtime and Apple notarization. MOME needs broad local process/tool access that is intentionally more capable than a typical Mac App Store sandboxed utility.
