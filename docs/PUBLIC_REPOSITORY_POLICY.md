# MOME public repository and intellectual-property policy

> Project policy for the community; not a substitute for advice from legal counsel.

## What open source means here

MOME source files published under the repository's Apache License 2.0 may be viewed, downloaded, copied, modified, redistributed, and used commercially subject to the license terms (including notices and applicable patent provisions). We welcome community contributions.

**No public source file can be made "visible but not pullable" through GitHub settings, CODEOWNERS or .gitignore.** If a file is in the public repository or its Git history, assume third parties can obtain it, including forks and mirrors.

## Keep these outside the public repository

- Proprietary business logic and unpublished algorithms you do not intend to license.
- Customer records, contracts, budgets, private research, commercial leads, and analytics.
- Credentials, API tokens, .env files, Apple signing identities, .p8 keys, service-account JSON, passwords, certificate bundles and recovery codes.
- Private product roadmaps, third-party assets without redistribution rights, paid fonts and licensed artwork.
- Security disclosures until a responsible fix is ready.

Keep proprietary material in a **separate private repository**, encrypted secret store or controlled service. Refer to it only through documented stable APIs where needed. Avoid using private Git submodules for something needed to build a community release; the open-source project must remain buildable without access to secret/private files.

## Source code vs. product identity

Apache-2.0 licenses the code; it does **not** license trademark rights in the MOME name, logos or commercial identity. See TRADEMARKS.md. Do not claim that open sourcing grants exclusive ownership over forks or restricts permitted use of licensed code.

Contributions to this repository are offered under Apache-2.0 unless clearly stated otherwise. Contributors retain their applicable copyright and should not submit code they lack the rights to license.

## Enforce contributions and releases

Recommended GitHub **Settings → Rules → Rulesets** for the main branch:
1. Require pull requests before merging; require at least one approval **from another authorized reviewer** (add a trusted maintainer if you are a sole maintainer).
2. Require review from CODEOWNERS, dismiss stale approvals, and require conversation resolution.
3. Require passing status checks: the existing macOS CI build job and the Website checks / validate job when it applies. Be mindful: path-filtered checks do not run on every PR; do not set a path-filtered job as unconditionally required. Consider a single always-running aggregate check.
4. Block force pushes and branch deletions; apply protections to administrators where supported.
5. Restrict who can administer, edit workflows, tag releases, and access GitHub Actions secrets.
6. Review fork pull-request workflows before granting write tokens or deploying artifacts.

CODEOWNERS requests review; it does not block changes without an enforced ruleset.

## Already public?

Changing .gitignore **does not remove tracked files** and deleting a file in a new commit does not erase its history. If a secret was committed, **revoke and rotate it first**, then follow GitHub's sensitive-data removal procedures and assess existing forks and caches. Git history rewriting alone cannot guarantee retrieval is impossible.

Enable secret scanning and push protection in Settings → Security → Code security and analysis when available. Use least-privilege credentials stored in GitHub Actions secrets, and inspect release archives before publishing.

## Company structure

Website positioning: **MOME / Last Dices** as the product and publisher; **Blanco Studio** as design and engineering collaborator. Update these attributions if legal ownership or release publishing entity changes. Commercial licensing or trademark-registration decisions should be reviewed professionally before sale or enforcement.
