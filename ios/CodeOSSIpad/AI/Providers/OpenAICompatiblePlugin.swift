import Foundation

/// Generic OpenAI-compatible provider for Groq, Together, DeepSeek, Ollama, etc.
final class OpenAICompatiblePlugin: AIPlugin {
	static let pluginID = "openai-compatible"

	var id: String { Self.pluginID }
	var displayName: String { "OpenAI Compatible" }
	var subtitle: String { "Any /v1/chat/completions endpoint (DeepSeek, Groq, Ollama…)" }
	var defaultModel: String { "gpt-4o-mini" }
	var availableModels: [String] {
		["gpt-4o-mini", "deepseek-chat", "llama-3.3-70b", "qwen2.5-coder"]
	}
	var apiKeyAccount: String { "openaiCompatible.apiKey" }
	var defaultBaseURL: URL? { nil }

	func complete(
		_ request: AICompletionRequest,
		apiKey: String,
		baseURL: URL?,
		onChunk: @escaping @Sendable (AICompletionChunk) -> Void
	) async throws {
		guard let endpoint = baseURL else {
			throw AIPluginError.invalidConfiguration("Set a base URL for the OpenAI-compatible provider.")
		}
		try await OpenAICompatibleClient.streamChat(
			baseURL: endpoint,
			apiKey: apiKey,
			request: request,
			onChunk: onChunk
		)
	}
}

enum OpenAICompatibleClient {
	static func streamChat(
		baseURL: URL,
		apiKey: String,
		request: AICompletionRequest,
		onChunk: @escaping @Sendable (AICompletionChunk) -> Void
	) async throws {
		let root = baseURL.absoluteString.hasSuffix("/")
			? URL(string: String(baseURL.absoluteString.dropLast()))!
			: baseURL
		let url = root.appendingPathComponent("chat/completions")

		let body: [String: Any] = [
			"model": request.model,
			"temperature": request.temperature,
			"stream": true,
			"messages": OpenAICompatPayload.messages(from: request),
		]

		try await HTTPJSONClient.streamSSE(
			url: url,
			headers: ["Authorization": "Bearer \(apiKey)"],
			body: body
		) { payload in
			if let text = OpenAICompatPayload.extractDeltaContent(from: payload), !text.isEmpty {
				onChunk(AICompletionChunk(text: text, isFinal: false))
			}
		}
		onChunk(AICompletionChunk(text: "", isFinal: true))
	}
}
