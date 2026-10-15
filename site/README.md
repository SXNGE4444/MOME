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

## Publish with GitHub Pages

The repository includes a Pages workflow at .github/workflows/pages.yml. In **Settings → Pages → Build and deployment → Source**, select **GitHub Actions**. After the website PR is merged into main, the workflow publishes site/ to the default project URL:

https://sxnge4444.github.io/MOME/

The site uses relative asset paths to work at the /MOME/ project path. Setting the Pages source requires repository settings access and cannot be accomplished by source changes alone.

## Custom domain

If you later decide to host under Last Dices (e.g. a MOME subdomain), first add and verify the custom domain in GitHub Pages, configure the appropriate CNAME with the DNS provider, and enable HTTPS. Do **not** add a CNAME file until the actual hostname and DNS are confirmed. Blanco Studio can link to the MOME page without being the production host.

## Website QA

- Keyboard-accessible product preview tabs (arrow keys, Home/End)
- Mobile navigation
- Reduced-motion preference
- Honest description of public beta status
- No client-side secrets, trackers or external image dependencies

The site is not a source of release binaries. Only verified, signed and notarized GitHub Releases should serve downloadable builds.
