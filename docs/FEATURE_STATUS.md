# Feature Status — MOME 0.1.0-beta.1

This document distinguishes operational features from integrations that still require external credentials or provider-specific work.

## Operational in the native app

- Project registration and stack detection
- Project task planning
- Persistent PTY shell sessions
- One-shot command execution with streamed output
- Command risk classification and explicit approval gates
- Xcode, iOS Simulator and TestFlight command paths
- Android/ADB/AVD and Google Play command paths
- Expo/EAS actions
- Blender, Unity and Unreal command paths
- Git and GitHub CLI actions
- Supabase, Cloudflare and Vercel command paths
- OpenAI and DeepSeek API clients
- Hugging Face and open-weight model connectors
- LM Studio, Ollama, vLLM, llama.cpp, LocalAI, Jan, MLX-LM and TGI presets
- macOS Keychain secret storage
- Local Workspaces
- Unified local activity Inbox
- Local Automation Hub definitions and manual execution records
- Local AI Agent profiles
- Local Revenue Intelligence entries
- Local Community Roadmap proposals and voting
- In-app GitHub release update checks
- Guided Setup and MOME Academy content

## Requires local tools or credentials

These features are implemented as command/integration paths but only function when the user's environment is correctly installed and authenticated:

- Xcode signing and App Store Connect upload
- Google Play publishing
- GitHub CLI remote operations
- Supabase remote operations
- Cloudflare deploys
- Vercel deploys
- EAS build/submit
- Paid or authenticated AI providers

## Catalog / configuration state only

The following Nausicaa-derived service connectors are represented in MOME's native connector catalog, but MOME 0.1.0-beta.1 does **not** claim live OAuth/API connectivity for them yet:

- Gmail
- Slack
- WhatsApp Business
- HubSpot
- Salesforce
- Stripe
- Paystack
- Flutterwave
- Google Analytics
- Zapier / generic webhooks

Their UI deliberately reports local setup state rather than fabricating successful network connectivity.

## Distribution status

The repository includes:

- Apache-2.0 licensing
- contribution and security policies
- release preflight checks
- secret-pattern checks
- Swift tests
- Developer ID signing support
- hardened-runtime signing
- DMG packaging
- Apple notarization and stapling
- Gatekeeper verification
- GitHub Release automation
- dry-run release packaging

Official downloadable binaries still require the repository maintainer's Apple Developer credentials in GitHub Actions.
