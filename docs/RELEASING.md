# Public Release Guide

MOME uses a monthly release cadence. Public macOS binaries must be signed with Developer ID and notarized by Apple.

## One-time repository setup

Add these GitHub Actions repository secrets:

- `MACOS_CERT_P12_BASE64` — base64-encoded Developer ID Application certificate (.p12)
- `MACOS_CERT_PASSWORD` — password for the .p12
- `MACOS_KEYCHAIN_PASSWORD` — ephemeral CI keychain password
- `MACOS_SIGN_IDENTITY` — full Developer ID Application identity, for example `Developer ID Application: Example Name (TEAMID)`
- `APPLE_ID` — Apple ID used for notarization
- `APPLE_TEAM_ID` — Apple Developer team ID
- `APPLE_APP_PASSWORD` — app-specific password for notarization

Do not commit these values.

## Create a release

1. Make sure `main` is green.
2. Update `CHANGELOG.md`.
3. Create and push a semantic version tag:

```bash
git checkout main
git pull
git tag v0.1.0-beta.1
git push origin v0.1.0-beta.1
```

The `Public macOS Release` workflow will:

1. run the Swift test suite;
2. import the Developer ID certificate into an ephemeral keychain;
3. build MOME with hardened runtime;
4. sign the app;
5. create and sign a DMG;
6. submit it to Apple's notarization service with `notarytool`;
7. staple and validate the notarization ticket;
8. calculate SHA-256;
9. create a prerelease on GitHub with the DMG and checksum.

## Local development builds

```bash
bash scripts/build-app.sh
open dist/MOME.app
```

Local builds use ad-hoc signing unless `MOME_SIGN_IDENTITY` is supplied.

## Monthly cadence

- Week 1: triage issues and select scope.
- Week 2: implementation and pull-request review.
- Week 3: tests, clean-Mac validation and documentation.
- Week 4: tag, notarize and publish.
- Security patches may ship outside the monthly cadence.
