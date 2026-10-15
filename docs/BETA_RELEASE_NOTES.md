# MOME v0.1.0-beta.1 — Open-source developer preview

**Release type: SOURCE-ONLY PRERELEASE. No signed or notarized macOS installer is included.**

MOME is a native SwiftUI developer command center for macOS 14+. It brings developer projects, terminal workflows, tool detection, Forge AI provider integration, local simulator and creative-tool workflows, and approval-gated actions into one workspace.

## Included

- Native SwiftUI MOME app source and automated Swift build/test preflight.
- Project and workspace management; CLI tool scanning and environment status.
- Forge AI / hosted and local AI-provider integration.
- Native dashboard, automation, terminal and device views.
- Explicit human approval for commands that change state, deploy or create releases.
- Apache-2.0 code licensing and community contribution guidelines.
- Product overview: https://www.lastdicesptyltd.co.za/mome

## Build from source (macOS 14+ with Xcode Command Line Tools)

~~~bash
git clone https://github.com/SXNGE4444/MOME.git
cd MOME
git checkout v0.1.0-beta.1
swift build
swift test
bash scripts/build-app.sh
open dist/MOME.app
~~~

The locally built .app is **ad-hoc signed**, intended for developers using their own machines; it is not a Developer ID signed, Apple notarized distribution. Do not redistribute a local test build as an official installer.

**No downloadable DMG is attached** to this GitHub Release. A signed/notarized DMG will only be published after the required Apple Developer signing credentials are configured and Gatekeeper verification succeeds. See [Public Release Guide](https://github.com/SXNGE4444/MOME/blob/main/docs/RELEASING.md).

## Status

- Beta / evaluation use, not warranted production software.
- Permission boundaries remain enforced; don't grant untrusted repositories access to secrets.
- To contribute, see CONTRIBUTING.md and SECURITY.md.
