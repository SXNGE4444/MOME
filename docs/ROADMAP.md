# MOME Roadmap

## Release 0.1 — Local Command Center

Implemented foundation:

- native SwiftUI macOS shell;
- local project/workspace registry;
- `forge.json` project metadata;
- tool discovery for Xcode, VS Code, Android Studio, Blender, Unity, Unreal, Git/GitHub CLI, Node, pnpm, Python, Wrangler, Vercel, ADB, Podman and Docker;
- local process execution with streamed logs and stop controls;
- iOS Simulator and Android connected-device discovery;
- project action adapters;
- Cloudflare and Vercel deployment actions with risk gating;
- product/content/engineering/release planning board;
- Keychain credential storage;
- OpenAI and DeepSeek response adapters;
- command palette.

## Release 0.2 — Build Intelligence

- PTY-backed persistent terminal sessions;
- port/PID supervisor and kill/restart controls;
- richer Git branch/diff/commit views;
- Expo/EAS adapter;
- structured build-error parser;
- AI context bundles from logs + project metadata + selected files;
- reusable pipeline definitions;
- environment-variable inspector with secret redaction.

## Release 0.3 — Apple + Android Shipping

- xcodebuild scheme/configuration discovery;
- simulator boot/install/launch/screenshot/log actions;
- archive/export pipeline;
- App Store Connect API integration;
- TestFlight build/status/tester surfaces;
- Android AVD discovery/boot;
- APK/AAB output discovery;
- Play Console release integration.

## Release 0.4 — 3D / Game Production

- `.blend` project discovery and headless render queues;
- Blender Python task runner;
- Unity project/version detection and batch builds;
- Unreal `.uproject` discovery;
- UnrealBuildTool / AutomationTool packaging;
- render/build artifact browser.

## Release 0.5 — Team / Remote

- SSH execution targets;
- remote build agents;
- GitHub pull request/check surfaces;
- shared project templates;
- signed MOME plugins/adapters;
- team activity and approval policies.

## Production hardening

Before public distribution:

- replace pipe terminal with audited PTY implementation;
- add command allow/deny policy and shell escaping tests;
- add unit/integration tests around destructive-command gating;
- code-sign helper/runtime components;
- Hardened Runtime validation;
- notarized DMG packaging;
- automatic update mechanism;
- crash reporting/privacy controls;
- accessibility/keyboard QA;
- macOS 14/15/16 regression testing.
