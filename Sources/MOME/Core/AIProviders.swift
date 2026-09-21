import Foundation

enum AIWireProtocol {
    case responses
    case chatCompletions
}

enum AIProvider: String, CaseIterable, Identifiable {
    case openAI = "OpenAI"
    case deepSeek = "DeepSeek"
    case huggingFace = "Hugging Face"
    case lmStudio = "LM Studio"
    case ollama = "Ollama"
    case vLLM = "vLLM"
    case llamaCpp = "llama.cpp"
    case localAI = "LocalAI"
    case jan = "Jan"
    case mlxLM = "MLX-LM"
    case tgi = "Hugging Face TGI"
    case custom = "Custom OpenAI-Compatible"

    var id: String { rawValue }

    var storageID: String {
        switch self {
        case .openAI: return "openai"
        case .deepSeek: return "deepseek"
        case .huggingFace: return "huggingface"
        case .lmStudio: return "lmstudio"
        case .ollama: return "ollama"
        case .vLLM: return "vllm"
        case .llamaCpp: return "llamacpp"
        case .localAI: return "localai"
        case .jan: return "jan"
        case .mlxLM: return "mlx-lm"
        case .tgi: return "tgi"
        case .custom: return "custom-openai"
        }
    }

    var keychainAccount: String {
        switch self {
        case .openAI: return "openai.apiKey"
        case .deepSeek: return "deepseek.apiKey"
        case .huggingFace: return "huggingface.apiKey"
        default: return "ai.\(storageID).apiKey"
        }
    }

    var defaultModel: String {
        switch self {
        case .openAI: return "gpt-5.6"
        case .deepSeek: return "deepseek-flash"
        case .huggingFace: return "openai/gpt-oss-20b:fastest"
        case .tgi: return "tgi"
        case .lmStudio, .ollama, .vLLM, .llamaCpp, .localAI, .jan, .mlxLM, .custom:
            return ""
        }
    }

    var defaultEndpoint: String {
        switch self {
        case .openAI:
            return "https://api.openai.com/v1/responses"
        case .deepSeek:
            return "https://api.deepseek.com/chat/completions"
        case .huggingFace:
            return "https://router.huggingface.co/v1/chat/completions"
        case .lmStudio:
            return "http://127.0.0.1:1234/v1/chat/completions"
        case .ollama:
            return "http://127.0.0.1:11434/v1/chat/completions"
        case .vLLM:
            return "http://127.0.0.1:8000/v1/chat/completions"
        case .llamaCpp:
            return "http://127.0.0.1:8080/v1/chat/completions"
        case .localAI:
            return "http://127.0.0.1:8080/v1/chat/completions"
        case .jan:
            return "http://127.0.0.1:1337/v1/chat/completions"
        case .mlxLM:
            return "http://127.0.0.1:8080/v1/chat/completions"
        case .tgi:
            return "http://127.0.0.1:3000/v1/chat/completions"
        case .custom:
            return "http://127.0.0.1:8000/v1/chat/completions"
        }
    }

    var wireProtocol: AIWireProtocol {
        self == .openAI ? .responses : .chatCompletions
    }

    var requiresAPIKey: Bool {
        switch self {
        case .openAI, .deepSeek, .huggingFace:
            return true
        case .lmStudio, .ollama, .vLLM, .llamaCpp, .localAI, .jan, .mlxLM, .tgi, .custom:
            return false
        }
    }

    var isLocalByDefault: Bool {
        switch self {
        case .lmStudio, .ollama, .vLLM, .llamaCpp, .localAI, .jan, .mlxLM, .tgi:
            return true
        default:
            return false
        }
    }

    var supportsModelDiscovery: Bool {
        switch self {
        case .huggingFace, .tgi:
            return false
        default:
            return true
        }
    }

    var detail: String {
        switch self {
        case .openAI: return "OpenAI Responses API"
        case .deepSeek: return "DeepSeek cloud API"
        case .huggingFace: return "Open-weight models through Hugging Face Inference Providers"
        case .lmStudio: return "Local models served by LM Studio"
        case .ollama: return "Local or Ollama-hosted open models"
        case .vLLM: return "High-throughput OpenAI-compatible inference server"
        case .llamaCpp: return "GGUF inference through llama-server"
        case .localAI: return "Local OpenAI-compatible multi-backend runtime"
        case .jan: return "Jan's local OpenAI-compatible server"
        case .mlxLM: return "Apple Silicon local inference with MLX"
        case .tgi: return "Hugging Face Text Generation Inference server"
        case .custom: return "Any OpenAI-compatible Chat Completions endpoint"
        }
    }
}

struct AIService {
    func ask(
        _ prompt: String,
        provider: AIProvider,
        apiKey: String,
        model: String,
        endpoint: String
    ) async throws -> String {
        let trimmedModel = model.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedModel.isEmpty else {
            throw AIServiceError.modelRequired
        }

        let trimmedEndpoint = endpoint.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let url = URL(string: trimmedEndpoint), !trimmedEndpoint.isEmpty else {
            throw AIServiceError.invalidEndpoint(trimmedEndpoint)
        }

        switch provider.wireProtocol {
        case .responses:
            return try await askResponses(
                prompt,
                apiKey: apiKey,
                model: trimmedModel,
                url: url
            )
        case .chatCompletions:
            return try await askChatCompletions(
                prompt,
                apiKey: apiKey,
                model: trimmedModel,
                url: url
            )
        }
    }

    func listModels(
        provider: AIProvider,
        apiKey: String,
        endpoint: String
    ) async throws -> [String] {
        guard provider.supportsModelDiscovery else {
            throw AIServiceError.modelDiscoveryUnsupported
        }
        guard let modelsURL = modelDiscoveryURL(from: endpoint) else {
            throw AIServiceError.invalidEndpoint(endpoint)
        }

        var request = URLRequest(url: modelsURL)
        request.httpMethod = "GET"
        request.timeoutInterval = 12
        if !apiKey.isEmpty {
            request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        }

        let data = try await perform(request)
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw AIServiceError.unreadableResponse
        }

        if let items = json["data"] as? [[String: Any]] {
            let models = items.compactMap { $0["id"] as? String }.filter { !$0.isEmpty }
            if !models.isEmpty { return models.sorted() }
        }

        if let items = json["models"] as? [[String: Any]] {
            let models = items.compactMap {
                ($0["id"] as? String) ?? ($0["name"] as? String) ?? ($0["model"] as? String)
            }.filter { !$0.isEmpty }
            if !models.isEmpty { return models.sorted() }
        }

        throw AIServiceError.unreadableModelList
    }

    private func askResponses(
        _ prompt: String,
        apiKey: String,
        model: String,
        url: URL
    ) async throws -> String {
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        if !apiKey.isEmpty {
            request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        }
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
        url: URL
    ) async throws -> String {
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        if !apiKey.isEmpty {
            request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        }
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

    private func modelDiscoveryURL(from endpoint: String) -> URL? {
        let trimmed = endpoint.trimmingCharacters(in: .whitespacesAndNewlines)
        guard var components = URLComponents(string: trimmed) else { return nil }

        if components.path.hasSuffix("/chat/completions") {
            components.path = String(components.path.dropLast("/chat/completions".count)) + "/models"
        } else if components.path.hasSuffix("/responses") {
            components.path = String(components.path.dropLast("/responses".count)) + "/models"
        } else if components.path.hasSuffix("/") {
            components.path += "models"
        } else {
            components.path += "/models"
        }
        components.query = nil
        components.fragment = nil
        return components.url
    }

    private func perform(_ request: URLRequest) async throws -> Data {
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse else {
                throw AIServiceError.unreadableResponse
            }
            guard (200..<300).contains(http.statusCode) else {
                let message = String(data: data, encoding: .utf8) ?? "Unknown API response"
                throw AIServiceError.requestFailed(status: http.statusCode, message: message)
            }
            return data
        } catch let error as AIServiceError {
            throw error
        } catch {
            throw AIServiceError.connectionFailed(error.localizedDescription)
        }
    }
}

enum AIServiceError: LocalizedError {
    case requestFailed(status: Int, message: String)
    case connectionFailed(String)
    case invalidEndpoint(String)
    case modelRequired
    case modelDiscoveryUnsupported
    case unreadableModelList
    case unreadableResponse

    var errorDescription: String? {
        switch self {
        case .requestFailed(let status, let message):
            return "AI provider returned HTTP \(status): \(message)"
        case .connectionFailed(let message):
            return "Could not connect to the AI runtime: \(message)"
        case .invalidEndpoint(let endpoint):
            return "Invalid AI endpoint: \(endpoint)"
        case .modelRequired:
            return "Choose or enter a model before sending the prompt."
        case .modelDiscoveryUnsupported:
            return "This provider does not expose model discovery through the configured endpoint."
        case .unreadableModelList:
            return "The provider responded, but MOME could not read its model list."
        case .unreadableResponse:
            return "The AI provider returned a response MOME could not parse."
        }
    }
}
