# MOME

**MOME — Developer Command Center for macOS**

A native macOS control plane for planning, building, testing, running and shipping software from one dashboard.

MOME is designed to orchestrate local developer tools rather than replace them. The first MVP targets Xcode, iOS Simulator, VS Code, Android Studio/ADB, Blender, Unity, Unreal Engine, Git, Node/pnpm, Python, Cloudflare Wrangler, Vercel, OpenAI and DeepSeek.

## Product principles

- **Local-first:** projects, tool detection and command execution live on the Mac.
- **Reality-first:** statuses come from actual installed tools/processes; no fake dashboard data.
- **Safe orchestration:** read/safe actions can run directly; write/release/dangerous actions are permission-gated.
- **Adapter architecture:** every external tool implements a common adapter contract.
- **Secrets in Keychain:** API credentials are never stored in `forge.json` or source control.

## MVP

- SwiftUI macOS application shell
- Command Center dashboard
- Workspace/project registry
- Installed-tool scanner
- Process supervisor with streaming output
- Command palette
- Project detail surface
- Device/simulator control surfaces
- Tool-adapter protocol and initial adapters
- OpenAI/DeepSeek provider abstraction
- Cloudflare/Vercel deployment command adapters
- Keychain-backed credential vault
- `forge.json` project configuration model

## Run

Requirements: macOS 14+, Xcode 16+ / Swift 6 toolchain.

```bash
git clone https://github.com/SXNGE4444/MOME.git
cd MOME
swift build
swift run MOME
```

You can also open `Package.swift` in Xcode and run the **MOME** executable target.

## Safety

MOME intentionally does **not** silently execute production deploys, destructive shell commands, database resets, or release actions. Commands have explicit risk levels and privileged operations require user approval in the UI.

## Status

This repository is being initialized as the native macOS MVP. See `docs/ARCHITECTURE.md` and `docs/ROADMAP.md` for the implementation model and release plan.
