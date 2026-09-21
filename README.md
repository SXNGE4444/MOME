# MOME

**MOME — Developer Command Center for macOS**

MOME is a native macOS control plane for planning, building, testing, running and shipping software from one dashboard. It orchestrates real local CLIs, applications, simulators, emulators, cloud tools and AI providers rather than replacing them.

## Current operational surface

- Native SwiftUI macOS application
- Stack-aware project registry and `forge.json` configuration
- PTY-backed persistent shell sessions plus one-shot build/deploy jobs
- Live stdout/stderr, process stop, interrupt and input
- Xcode project inspection, build/test, archive and IPA export
- iOS Simulator discovery, boot, boot-status wait, shutdown, erase, app install and launch
- TestFlight upload path using App Store Connect API credentials
- Android Studio/Gradle APK and AAB builds
- Android ADB devices, AVD discovery/start/stop, logcat, APK install and package launch
- Google Play upload path through `fastlane supply`
- Expo local/iOS/Android actions plus EAS build/submit
- Blender open, headless frame render and animation render
- Unity batch EditMode tests and configurable batch build methods
- Unreal AutomationTool macOS packaging
- Git status/fetch/pull and GitHub CLI pull-request/Actions inspection
- Supabase local stack, Functions, DB push and guarded local reset
- Cloudflare Wrangler auth/dev/deploy
- Vercel auth/dev/preview/production
- OpenAI Responses API integration
- DeepSeek Chat Completions integration
- Experiential Labs Chat Completions integration (default model: `gemini-3.7-flash`)
- macOS Keychain credential vault
- Guided first-run setup and MOME Academy walkthroughs
- READ / SAFE / WRITE / RELEASE / DANGEROUS action gates

## Build and run

Requirements: macOS 14+, Xcode 16+ / Swift 6 toolchain.

```bash
git clone https://github.com/SXNGE4444/MOME.git
cd MOME
swift build
swift run MOME
```

Or open `Package.swift` in Xcode and run the **MOME** executable target.

## Build `MOME.app`

```bash
bash scripts/build-app.sh
open dist/MOME.app
```

The local development bundle is ad-hoc signed. Public distribution should use Developer ID signing, hardened runtime and Apple notarization.

## First run

MOME opens **Guided Setup** on first launch. It:

1. scans the Mac for supported tools;
2. lets you store OpenAI, DeepSeek, Experiential Labs and App Store Connect identifiers in Keychain;
3. helps you register project folders;
4. points you to the in-app Learn section.

You can reopen it from **MOME → Guided Setup**.

## Project configuration

Basic actions are detected automatically from files such as `ios/`, `android/`, `package.json`, `eas.json`, `wrangler.toml`, `vercel.json`, `supabase/`, `.blend`, `.uproject`, `Assets/ProjectSettings` and `.git`.

Release workflows need explicit values. Copy `forge.example.json` to a project's root as `forge.json`, remove settings that do not apply, and replace example values with real project values.

Useful settings include:

- `ios.workspace`, `ios.project`, `ios.scheme`, `ios.destination`
- `ios.bundleId`, `ios.appPath`
- `ios.archivePath`, `ios.exportOptionsPlist`, `ios.exportPath`, `ios.ipaPath`
- `android.package`, `android.activity`, `android.apkPath`, `android.aabPath`
- `android.playTrack`, `android.playJsonKey`
- `blender.file`, `blender.frame`
- `unity.buildMethod`
- `unreal.project`

## TestFlight credentials

MOME stores the App Store Connect **Key ID** and **Issuer ID** in Keychain. The `.p8` private key stays as a local file and must be placed where Apple's command-line upload tooling can resolve `AuthKey_<KEYID>.p8`. Never commit the key to Git.

## Google Play credentials

MOME's Play Console action uses `fastlane supply`. `android.playJsonKey` should point to a local Google Play service-account JSON file. Do not commit that credential to the repository.

## Safety model

- **READ** — inspect state
- **SAFE** — local development/test processes
- **WRITE** — changes local state; requires approval
- **RELEASE** — affects remote/production distribution; requires approval
- **DANGEROUS** — destructive/reset actions; requires approval

MOME does not allow AI responses to bypass these action gates.

## Important limitation

MOME can only execute integrations that are correctly installed, authenticated and configured on the Mac. A green MOME control does not manufacture missing Apple signing identities, App Store Connect access, Google Play service accounts, engine licenses, cloud permissions or project-specific build scripts. Failed commands stream their real output into Terminal and can be passed directly to Forge AI for diagnosis.
