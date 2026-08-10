import Foundation

final class OpenAIPlugin: AIPlugin {
	static let pluginID = "openai"

	var id: String { Self.pluginID }
	var displayName: String { "OpenAI" }
	var subtitle: String { "GPT-4.1 / GPT-4o / o-series via api.openai.com" }
	var defaultModel: String { "gpt-4o-mini" }
	var availableModels: [String] {
		["gpt-4o-mini", "gpt-4o", "gpt-4.1", "gpt-4.1-mini", "o3-mini", "o4-mini"]
	}
	var apiKeyAccount: String { "openai.apiKey" }
	var defaultBaseURL: URL? { URL(string: "https://api.openai.com/v1") }

	func complete(
		_ request: AICompletionRequest,
		apiKey: String,
		baseURL: URL?,
		onChunk: @escaping @Sendable (AICompletionChunk) -> Void
	) async throws {
		try await OpenAICompatibleClient.streamChat(
			baseURL: baseURL ?? defaultBaseURL!,
			apiKey: apiKey,
			request: request,
			onChunk: onChunk
		)
	}
}
