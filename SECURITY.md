# Security Policy

## Supported versions

MOME is currently distributed as a public beta. Security fixes are applied to the latest tagged release and the `main` branch.

## Reporting a vulnerability

Please do **not** open a public issue for a vulnerability that could expose credentials, execute commands without approval, or compromise a developer workstation.

Report the issue privately through GitHub's security advisory flow when available. If private reporting is unavailable, contact the repository owner through their GitHub profile and request a private channel before sharing exploit details.

Include:
- affected MOME version or commit;
- macOS version and architecture;
- reproduction steps;
- expected and actual behavior;
- whether credentials, filesystem data, command execution, or remote services are affected.

## Security model

MOME can execute local developer commands. Actions are classified by risk:
- READ and SAFE may run without confirmation;
- WRITE, RELEASE and DANGEROUS actions require explicit user approval;
- custom commands supplied by a project's `forge.json` are treated as WRITE actions and require approval;
- secrets should remain in macOS Keychain or local files excluded from source control.

MOME does not consider AI-generated output authoritative and does not allow AI responses to bypass action approval gates.
