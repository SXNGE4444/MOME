# Contributing to MOME

Thanks for helping improve MOME.

## Development setup

Requirements:
- macOS 14 or later
- Xcode 16+ / Swift toolchain supported by the repository

```bash
git clone https://github.com/SXNGE4444/MOME.git
cd MOME
swift build
swift test
swift run MOME
```

## Pull requests

1. Create a focused branch.
2. Keep changes scoped and explain user-visible behavior.
3. Add or update tests for security-sensitive behavior.
4. Run `swift build` and `swift test`.
5. Never commit API keys, signing certificates, provisioning profiles or App Store Connect secrets.
6. For new command actions, choose the least permissive risk level that is accurate. Any action that can modify local or remote state must require approval.

## Architecture

Read `docs/ARCHITECTURE.md` before adding a new adapter or execution path. MOME favors native SwiftUI, local-first storage, explicit permission gates and provider-neutral interfaces.

## Monthly maintenance

The project targets one planned feature/reliability release per month. Critical security fixes may be released outside that schedule.
