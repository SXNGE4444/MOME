# MOME product website

Static, dependency-free marketing website for MOME (native macOS command center).

**Brand positioning:** MOME is presented as a Last Dices project, with design and engineering credit to Blanco Studio. Change these footer links and brand attributions if your publishing entity changes.

## Preview locally

From the repository root:

~~~bash
python3 -m http.server 8080 --directory site
~~~

Open http://localhost:8080.

No API keys or build step are needed. The dashboard is a **deliberately labeled illustrative UI** for marketing. It does not execute macOS actions. Actual functionality lives in the SwiftUI application.

## Official publication on Last Dices

The official product website is **https://www.lastdicesptyltd.co.za/mome**. It is implemented as a scoped Next.js route in the separate, private Last Dices website repository, rather than using GitHub Pages. This directory preserves the original standalone marketing design concept for reference and experimentation. It is **not** the production website.

Do not configure a GitHub Pages custom domain for MOME, and do not point the apex or www DNS to this repository. Publishing the official /mome path belongs to the existing Last Dices Vercel project.

## Website QA

- Keyboard-accessible product preview tabs (arrow keys, Home/End)
- Mobile navigation
- Reduced-motion preference
- Honest description of public beta status
- No client-side secrets, trackers or external image dependencies

The site is not a source of release binaries. Only verified, signed and notarized GitHub Releases should serve downloadable builds.
