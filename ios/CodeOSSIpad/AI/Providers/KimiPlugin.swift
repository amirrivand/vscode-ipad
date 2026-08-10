import Foundation

/// Moonshot / Kimi OpenAI-compatible API.
final class KimiPlugin: AIPlugin {
	static let pluginID = "kimi"

	var id: String { Self.pluginID }
	var displayName: String { "Kimi (Moonshot)" }
	var subtitle: String { "Kimi models via api.moonshot.cn / api.moonshot.ai" }
	var defaultModel: String { "moonshot-v1-128k" }
	var availableModels: [String] {
		["moonshot-v1-8k", "moonshot-v1-32k", "moonshot-v1-128k", "kimi-latest"]
	}
	var apiKeyAccount: String { "kimi.apiKey" }
	var defaultBaseURL: URL? { URL(string: "https://api.moonshot.cn/v1") }

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
