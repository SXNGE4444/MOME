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

## Public collaboration and ownership

MOME is licensed under Apache-2.0. By contributing, you confirm you have the right to submit your changes under this license, and you agree that your contribution is licensed on those terms. Contributors retain applicable copyright over their own work. We do not require a Contributor License Agreement for ordinary pull requests.

Before starting a large feature, open an issue to agree on scope. Fork the repository, work on a feature branch, and submit a pull request with tests, screenshots for UI changes, and an explanation of security implications. Please respect the CODE_OF_CONDUCT.md and avoid adding unlicensed fonts, graphics, copyrighted source from other projects, credentials, or private business files.

We review all merges; a public repository is not an invitation to push directly to the protected main branch. Changes to command execution, approval gates, Keychain handling, CI release workflows or credentials require additional scrutiny. Do not weaken approval gates to make a demo pass.

See [public repository policy](docs/PUBLIC_REPOSITORY_POLICY.md) and [trademark guidelines](TRADEMARKS.md). Not every issue, feature request, or PR can be accepted.
