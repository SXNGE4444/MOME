import Foundation

enum AIProvider: String, CaseIterable, Identifiable {
    case openAI = "OpenAI"
    case deepSeek = "DeepSeek"
    case experientialLabs = "Experiential Labs"

    var id: String { rawValue }

    var keychainAccount: String {
        switch self {
        case .openAI: return "openai.apiKey"
        case .deepSeek: return "deepseek.apiKey"
        case .experientialLabs: return "experientiallabs.apiKey"
        }
    }

    var defaultModel: String {
        switch self {
        case .openAI: return "gpt-5.6"
        case .deepSeek: return "deepseek-flash"
        case .experientialLabs: return "gemini-3.7-flash"
        }
    }
}

struct AIService {
    func ask(_ prompt: String, provider: AIProvider, apiKey: String, model: String? = nil) async throws -> String {
        let resolvedModel = model ?? provider.defaultModel

        switch provider {
        case .openAI:
            return try await askOpenAI(prompt, apiKey: apiKey, model: resolvedModel)
        case .deepSeek:
            return try await askChatCompletions(
                prompt,
                apiKey: apiKey,
                model: resolvedModel,
                endpoint: "https://api.deepseek.com/chat/completions"
            )
        case .experientialLabs:
            return try await askChatCompletions(
                prompt,
                apiKey: apiKey,
                model: resolvedModel,
                endpoint: "https://api.experientiallabs.ai/v1/chat/completions"
            )
        }
    }

    private func askOpenAI(_ prompt: String, apiKey: String, model: String) async throws -> String {
        var request = URLRequest(url: URL(string: "https://api.openai.com/v1/responses")!)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 180
        request.httpBody = try JSONSerialization.data(withJSONObject: [
            "model": model,
            "input": prompt
        ])

        let data = try await perform(request)
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw AIServiceError.unreadableResponse
        }

        if let direct = json["output_text"] as? String, !direct.isEmpty { return direct }
        if let output = json["output"] as? [[String: Any]] {
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

    private func askChatCompletions(
        _ prompt: String,
        apiKey: String,
        model: String,
        endpoint: String
    ) async throws -> String {
        guard let url = URL(string: endpoint) else {
            throw AIServiceError.invalidEndpoint(endpoint)
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 180
        request.httpBody = try JSONSerialization.data(withJSONObject: [
            "model": model,
            "messages": [["role": "user", "content": prompt]],
            "stream": false
        ])

        let data = try await perform(request)
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let choices = json["choices"] as? [[String: Any]],
              let first = choices.first,
              let message = first["message"] as? [String: Any],
              let content = message["content"] as? String,
              !content.isEmpty else {
            throw AIServiceError.unreadableResponse
        }
        return content
    }

    private func perform(_ request: URLRequest) async throws -> Data {
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse,
              (200..<300).contains(http.statusCode) else {
            let message = String(data: data, encoding: .utf8) ?? "Unknown API response"
            throw AIServiceError.requestFailed(message)
        }
        return data
    }
}

enum AIServiceError: LocalizedError {
    case requestFailed(String)
    case invalidEndpoint(String)
    case unreadableResponse

    var errorDescription: String? {
        switch self {
        case .requestFailed(let message): return message
        case .invalidEndpoint(let endpoint): return "Invalid AI provider endpoint: \(endpoint)"
        case .unreadableResponse: return "The AI provider returned a response MOME could not parse."
        }
    }
}
