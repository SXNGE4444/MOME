import Foundation

enum AIProvider: String, CaseIterable, Identifiable {
    case openAI = "OpenAI"
    case deepSeek = "DeepSeek"

    var id: String { rawValue }

    var keychainAccount: String {
        switch self {
        case .openAI: return "openai.apiKey"
        case .deepSeek: return "deepseek.apiKey"
        }
    }

    var endpoint: URL {
        switch self {
        case .openAI: return URL(string: "https://api.openai.com/v1/responses")!
        case .deepSeek: return URL(string: "https://api.deepseek.com/responses")!
        }
    }

    var defaultModel: String {
        switch self {
        case .openAI: return "gpt-5.6"
        case .deepSeek: return "deepseek-flash"
        }
    }
}

struct AIService {
    func ask(_ prompt: String, provider: AIProvider, apiKey: String, model: String? = nil) async throws -> String {
        var request = URLRequest(url: provider.endpoint)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 120

        let body: [String: Any] = [
            "model": model ?? provider.defaultModel,
            "input": prompt
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse,
              (200..<300).contains(http.statusCode) else {
            let message = String(data: data, encoding: .utf8) ?? "Unknown API response"
            throw AIServiceError.requestFailed(message)
        }

        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        if let direct = json?["output_text"] as? String, !direct.isEmpty {
            return direct
        }

        if let output = json?["output"] as? [[String: Any]] {
            let texts = output.flatMap { item -> [String] in
                guard let content = item["content"] as? [[String: Any]] else { return [] }
                return content.compactMap { part in
                    if let text = part["text"] as? String { return text }
                    if let text = part["output_text"] as? String { return text }
                    return nil
                }
            }
            if !texts.isEmpty { return texts.joined(separator: "\n") }
        }

        throw AIServiceError.unreadableResponse
    }
}

enum AIServiceError: LocalizedError {
    case requestFailed(String)
    case unreadableResponse

    var errorDescription: String? {
        switch self {
        case .requestFailed(let message): return message
        case .unreadableResponse: return "The AI provider returned a response MOME could not parse."
        }
    }
}
