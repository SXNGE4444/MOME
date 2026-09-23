import Foundation

struct UpdateNotice: Identifiable {
    let id = UUID()
    let title: String
    let message: String
    let releaseURL: URL?
}

struct GitHubRelease: Decodable {
    let tagName: String
    let htmlURL: URL
    let draft: Bool

    enum CodingKeys: String, CodingKey {
        case tagName = "tag_name"
        case htmlURL = "html_url"
        case draft
    }
}

enum ReleaseUpdateChecker {
    static func check(currentVersion: String) async throws -> UpdateNotice {
        guard let url = URL(string: "https://api.github.com/repos/SXNGE4444/MOME/releases?per_page=10") else {
            return UpdateNotice(title: "Update Check Failed", message: "The MOME releases endpoint is invalid.", releaseURL: nil)
        }

        var request = URLRequest(url: url)
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        request.setValue("MOME/(currentVersion)", forHTTPHeaderField: "User-Agent")
        request.timeoutInterval = 15

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw URLError(.badServerResponse)
        }

        let releases = try JSONDecoder().decode([GitHubRelease].self, from: data)
        guard let latest = releases.first(where: { !$0.draft }) else {
            return UpdateNotice(
                title: "No Public Releases Yet",
                message: "MOME could not find a published GitHub release.",
                releaseURL: URL(string: "https://github.com/SXNGE4444/MOME/releases")
            )
        }

        let latestVersion = latest.tagName.hasPrefix("v") ? String(latest.tagName.dropFirst()) : latest.tagName
        guard currentVersion != "development" else {
            return UpdateNotice(
                title: "Development Build",
                message: "Latest published release: (latest.tagName). Development builds are not automatically compared with release versions.",
                releaseURL: latest.htmlURL
            )
        }

        if latestVersion == currentVersion {
            return UpdateNotice(
                title: "MOME Is Up to Date",
                message: "You are running (currentVersion), the latest published release.",
                releaseURL: latest.htmlURL
            )
        }

        return UpdateNotice(
            title: "MOME (latest.tagName) Available",
            message: "You are running (currentVersion). A different published release is available on GitHub.",
            releaseURL: latest.htmlURL
        )
    }
}
