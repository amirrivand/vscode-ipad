import Foundation

/// Cursor-compatible OpenAI-style endpoint.
/// Set a custom base URL in Settings (for example an official Cursor API gateway
/// or an OpenAI-compatible proxy you control). Defaults to api.openai.com-style `/v1`.
final class CursorPlugin: AIPlugin {
	static let pluginID = "cursor"

	var id: String { Self.pluginID }
	var displayName: String { "Cursor" }
	var subtitle: String { "OpenAI-compatible Cursor / agent endpoint" }
	var defaultModel: String { "cursor-fast" }
	var availableModels: [String] {
		["cursor-fast", "cursor-small", "gpt-4o", "claude-sonnet-4-20250514"]
	}
	var apiKeyAccount: String { "cursor.apiKey" }
	var defaultBaseURL: URL? { URL(string: "https://api.openai.com/v1") }

	func complete(
		_ request: AICompletionRequest,
		apiKey: String,
		baseURL: URL?,
		onChunk: @escaping @Sendable (AICompletionChunk) -> Void
	) async throws {
		guard let endpoint = baseURL ?? defaultBaseURL else {
			throw AIPluginError.invalidConfiguration("Set a Cursor-compatible base URL in Settings.")
		}
		try await OpenAICompatibleClient.streamChat(
			baseURL: endpoint,
			apiKey: apiKey,
			request: request,
			onChunk: onChunk
		)
	}
}
