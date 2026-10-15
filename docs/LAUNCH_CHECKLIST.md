# MOME Public Beta Launch Checklist

Target version: **v0.1.0-beta.1**

## Automated / repository-complete

- [x] Apache-2.0 license and NOTICE
- [x] SECURITY.md
- [x] CONTRIBUTING.md
- [x] Code of Conduct
- [x] CODEOWNERS
- [x] Bug and feature issue templates
- [x] Pull-request template
- [x] Command safety regression tests
- [x] Project-defined commands require explicit approval
- [x] Release preflight script
- [x] Common committed-secret pattern gate
- [x] Credential-file gate
- [x] macOS app icon generation
- [x] Versioned application bundle
- [x] DMG generation
- [x] Developer ID hardened-runtime signing path
- [x] Apple notarization path
- [x] Stapling and Gatekeeper verification
- [x] Tag-triggered GitHub Release workflow
- [x] Release dry-run workflow
- [x] In-app release update check
- [x] Nausicaa feature surfaces migrated natively
- [x] Feature-status documentation

## One-time maintainer account setup

These actions cannot be represented by source code alone.

- [x] Change GitHub repository visibility from **Private** to **Public**
- [ ] Add a short repository description: `Open-source macOS developer command center for projects, terminals, AI, tools and releases`
- [ ] Add topics: `macos`, `swift`, `swiftui`, `developer-tools`, `ai`, `ollama`, `open-source`
- [ ] Add Apple release secrets listed in `docs/RELEASING.md`
- [ ] Confirm the Developer ID Application certificate is valid
- [ ] Confirm the Apple Team ID and app-specific notarization password
- [ ] Optionally enable GitHub Discussions after the repository is public

## Website and community protections

- [x] Static MOME product website under site/ (illustrative demo only).
- [x] GitHub Pages deployment workflow and website-validation workflow in source.
- [x] CODEOWNERS expanded to the site, workflows and policy files.
- [x] Public repository/IP policy and brand/trademark guidelines.
- [ ] Merge the website PR into main after checks pass.
- [ ] Enable GitHub Pages under Settings → Pages → Source: GitHub Actions.
- [ ] Create/enforce a main branch ruleset (PR required, reviews, checks, no force pushes, no deletion).
- [ ] Enable secret scanning and push protection when available.
- [ ] Verify website at https://sxnge4444.github.io/MOME/ after deployment.
- [ ] Verify a clean macOS build, tests and signed/notarized release from a fresh machine.
- [ ] Verify Last Dices publishing entity and Blanco Studio attribution with rights holders.

## First drop

After the account setup above:

```bash
git checkout main
git pull
bash scripts/preflight.sh
git tag v0.1.0-beta.1
git push origin v0.1.0-beta.1
```

Do not publish a downloadable binary manually if the signed/notarized release workflow fails. Fix the failure and retag with the next prerelease identifier if necessary.

## Post-launch

- Verify the public README renders correctly.
- Download the DMG from GitHub Releases on a separate Mac/user account.
- Verify Gatekeeper opens MOME without bypass instructions.
- Open a test issue using each issue template.
- Confirm `Check for Updates…` can reach the public Releases page.
- Triage feedback monthly; ship critical security fixes outside the monthly cadence.
