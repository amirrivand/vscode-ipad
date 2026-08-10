import Foundation

/// Anthropic Messages API (non-OpenAI protocol).
final class AnthropicPlugin: AIPlugin {
	static let pluginID = "anthropic"

	var id: String { Self.pluginID }
	var displayName: String { "Anthropic Claude" }
	var subtitle: String { "Claude 4 / 3.5 via api.anthropic.com" }
	var defaultModel: String { "claude-sonnet-4-20250514" }
	var availableModels: [String] {
		[
			"claude-sonnet-4-20250514",
			"claude-opus-4-20250514",
			"claude-3-5-haiku-latest",
			"claude-3-5-sonnet-latest",
		]
	}
	var apiKeyAccount: String { "anthropic.apiKey" }
	var defaultBaseURL: URL? { URL(string: "https://api.anthropic.com") }

	func complete(
		_ request: AICompletionRequest,
		apiKey: String,
		baseURL: URL?,
		onChunk: @escaping @Sendable (AICompletionChunk) -> Void
	) async throws {
		let root = baseURL ?? defaultBaseURL!
		let url = root.appendingPathComponent("v1/messages")

		var system = request.systemPrompt
		if let context = request.editorContext, !context.isEmpty {
			system += "\n\nCurrent editor context:\n\(context)"
		}

		let messages: [[String: Any]] = request.messages.compactMap { message in
			guard message.role != .system else { return nil }
			return [
				"role": message.role == .assistant ? "assistant" : "user",
				"content": message.content,
			]
		}

		let body: [String: Any] = [
			"model": request.model,
			"max_tokens": 4096,
			"temperature": request.temperature,
			"stream": true,
			"system": system,
			"messages": messages,
		]

		let headers = [
			"x-api-key": apiKey,
			"anthropic-version": "2023-06-01",
		]

		try await HTTPJSONClient.streamSSE(url: url, headers: headers, body: body) { payload in
			guard let data = payload.data(using: .utf8),
				  let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
				return
			}
			let type = object["type"] as? String
			if type == "content_block_delta",
			   let delta = object["delta"] as? [String: Any],
			   let text = delta["text"] as? String {
				onChunk(AICompletionChunk(text: text, isFinal: false))
			}
		}
		onChunk(AICompletionChunk(text: "", isFinal: true))
	}
}
