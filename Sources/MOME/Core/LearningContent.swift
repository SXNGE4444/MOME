import Foundation

enum GuideCategory: String, CaseIterable, Identifiable {
    case gettingStarted = "Getting Started"
    case apple = "Apple"
    case android = "Android"
    case web = "Web & Cloud"
    case engines = "3D & Game Engines"
    case source = "Git & GitHub"
    case ai = "AI"
    case release = "Release"

    var id: String { rawValue }
}

struct GuideArticle: Identifiable, Hashable {
    var id: String
    var title: String
    var category: GuideCategory
    var summary: String
    var steps: [String]
    var commandExamples: [String] = []
}

enum LearningLibrary {
    static let articles: [GuideArticle] = [
        GuideArticle(
            id: "first-project",
            title: "Add your first project",
            category: .gettingStarted,
            summary: "Turn a local folder into a MOME workspace with stack-aware actions.",
            steps: [
                "Open Projects and choose Add Project.",
                "Select the root folder that contains your source code.",
                "MOME inspects the folder for Xcode, Android, Expo, Cloudflare, Vercel, Unity, Unreal, Blender, Supabase and Git markers.",
                "Open the project and review Run / Build / Open. Only adapters that match the project are shown.",
                "For advanced release actions, add a forge.json file using the example in the repository."
            ]
        ),
        GuideArticle(
            id: "terminal",
            title: "Persistent terminal sessions",
            category: .gettingStarted,
            summary: "Use a PTY-backed login shell for interactive CLIs, prompts, dev servers and REPLs.",
            steps: [
                "Open Terminal.",
                "Choose a project or Home Directory.",
                "Select New Shell to create a persistent PTY-backed login shell.",
                "Type commands into the shell input field. The working directory stays active between commands.",
                "Use Interrupt for a running foreground command or Stop to terminate the whole shell session."
            ],
            commandExamples: ["pwd", "git status", "pnpm dev", "npx expo start"]
        ),
        GuideArticle(
            id: "ios-simulator",
            title: "Run an app in iOS Simulator",
            category: .apple,
            summary: "Boot a simulator, install a configured .app bundle and launch its bundle identifier.",
            steps: [
                "Open Devices and select the project you want to test.",
                "Choose an available iOS Simulator and press Boot.",
                "Wait for the status to change to Booted.",
                "If forge.json contains ios.appPath, choose Install App.",
                "If forge.json contains ios.bundleId, choose Launch App."
            ]
        ),
        GuideArticle(
            id: "testflight",
            title: "Archive, export and upload to TestFlight",
            category: .apple,
            summary: "Use Xcode signing, archive/export configuration and App Store Connect API credentials.",
            steps: [
                "Set ios.scheme and ios.workspace or ios.project in forge.json.",
                "Run Archive iOS from the project action surface.",
                "Set ios.exportOptionsPlist and run Export IPA.",
                "Set ios.ipaPath to the exported IPA.",
                "Open Guided Setup and save your App Store Connect Key ID and Issuer ID to Keychain.",
                "Place AuthKey_<KEYID>.p8 in an Apple-supported private_keys directory for command-line uploads.",
                "Run Upload to TestFlight and approve the RELEASE action."
            ]
        ),
        GuideArticle(
            id: "android-avd",
            title: "Use Android Virtual Devices",
            category: .android,
            summary: "Discover AVD definitions, boot emulators, stream logcat and install APKs.",
            steps: [
                "Open Devices. MOME lists running Android devices and shutdown AVD definitions.",
                "Press Start AVD on a shutdown virtual device.",
                "Rescan after the emulator finishes booting.",
                "Use Logcat to stream device logs.",
                "Configure android.apkPath and android.package in forge.json to install and launch your app."
            ]
        ),
        GuideArticle(
            id: "play-console",
            title: "Build AAB and upload to Play Console",
            category: .android,
            summary: "Build a signed Android App Bundle and upload it through fastlane supply.",
            steps: [
                "Make sure the Android release signing configuration works in Gradle.",
                "Run Build Release AAB.",
                "Install fastlane if MOME reports it missing.",
                "Configure android.package, android.aabPath, android.playJsonKey and optionally android.playTrack.",
                "Run Upload to Play Console and approve the RELEASE action."
            ]
        ),
        GuideArticle(
            id: "cloudflare",
            title: "Deploy with Cloudflare Wrangler",
            category: .web,
            summary: "Verify authentication, run locally and deploy only projects that contain Cloudflare configuration.",
            steps: [
                "Add or open a project containing wrangler.toml, wrangler.json or wrangler.jsonc.",
                "Run Cloudflare Who Am I to verify the authenticated account.",
                "Run Cloudflare Dev for local testing.",
                "Review your git changes and environment configuration.",
                "Run Deploy Cloudflare and approve the RELEASE action."
            ]
        ),
        GuideArticle(
            id: "vercel",
            title: "Deploy with Vercel",
            category: .web,
            summary: "Run local, preview and production Vercel deployments from the same project context.",
            steps: [
                "Link the project with Vercel or include vercel.json.",
                "Run Vercel Who Am I.",
                "Use Vercel Dev locally.",
                "Create a preview deployment first.",
                "Use Deploy Vercel Production only after validating the preview."
            ]
        ),
        GuideArticle(
            id: "blender",
            title: "Render Blender projects",
            category: .engines,
            summary: "Open .blend files or render frames and animations headlessly.",
            steps: [
                "Add the folder containing your .blend file.",
                "Optionally configure blender.file and blender.frame in forge.json.",
                "Use Render Frame for a single headless render.",
                "Use Render Animation for the full configured frame range.",
                "Blender's scene output settings determine where rendered files are written."
            ]
        ),
        GuideArticle(
            id: "unity",
            title: "Run Unity tests and batch builds",
            category: .engines,
            summary: "Use the installed Unity Editor in batch mode instead of automating the graphical editor.",
            steps: [
                "Add a Unity project containing Assets and ProjectSettings.",
                "Run Unity Tests for EditMode tests.",
                "Create a static build method in your Unity project.",
                "Set unity.buildMethod to its fully-qualified method name.",
                "Run Unity Batch Build."
            ]
        ),
        GuideArticle(
            id: "unreal",
            title: "Package Unreal projects",
            category: .engines,
            summary: "Run Unreal AutomationTool against a .uproject to build, cook, stage and archive.",
            steps: [
                "Add a folder containing a .uproject.",
                "MOME locates an Unreal Engine installation under /Users/Shared/Epic Games.",
                "Open Unreal Project to work in the editor.",
                "Use Package Unreal for Mac to run BuildCookRun into build/mome/unreal.",
                "Review the terminal log if AutomationTool reports missing SDKs, signing or project settings."
            ]
        ),
        GuideArticle(
            id: "github",
            title: "GitHub pull requests and Actions",
            category: .source,
            summary: "Use GitHub CLI context from each repository.",
            steps: [
                "Authenticate gh from your terminal if needed.",
                "Use GitHub PRs to list open pull requests.",
                "Use GitHub Actions to list recent workflow runs.",
                "Use Watch Latest Workflow to stream the newest CI run.",
                "Git pull remains approval-gated because it changes your working copy."
            ]
        ),
        GuideArticle(
            id: "ai",
            title: "Configure Forge AI",
            category: .ai,
            summary: "Store provider keys in macOS Keychain and analyze real build output.",
            steps: [
                "Open Forge AI.",
                "Choose OpenAI or DeepSeek.",
                "Paste the provider API key and save it to Keychain.",
                "Use Latest Build Log to place the newest terminal output into the prompt.",
                "Ask for root-cause analysis and next actions. AI suggestions do not bypass MOME's action approval gates."
            ]
        ),
        GuideArticle(
            id: "release-safety",
            title: "Understand action safety",
            category: .release,
            summary: "MOME labels commands by the level of change they can make.",
            steps: [
                "READ actions inspect state and can run immediately.",
                "SAFE actions run local development/test processes with limited side effects.",
                "WRITE actions modify local state and require approval.",
                "RELEASE actions can affect remote users or production services and require approval.",
                "DANGEROUS actions can erase/reset data and require explicit approval."
            ]
        )
    ]
}
