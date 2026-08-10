import Foundation

struct AIChatMessage: Identifiable, Hashable, Codable {
	enum Role: String, Codable {
		case system
		case user
		case assistant
	}

	let id: UUID
	var role: Role
	var content: String
	var createdAt: Date

	init(id: UUID = UUID(), role: Role, content: String, createdAt: Date = Date()) {
		self.id = id
		self.role = role
		self.content = content
		self.createdAt = createdAt
	}
}

struct AICompletionRequest: Sendable {
	var model: String
	var systemPrompt: String
	var messages: [AIChatMessage]
	var temperature: Double
	var editorContext: String?
}

struct AICompletionChunk: Sendable {
	var text: String
	var isFinal: Bool
}

enum AIPluginError: LocalizedError {
	case missingAPIKey
	case invalidConfiguration(String)
	case httpStatus(Int, String)
	case decoding
	case cancelled
	case underlying(String)

	var errorDescription: String? {
		switch self {
		case .missingAPIKey:
			return "API key is missing. Add it in Settings."
		case .invalidConfiguration(let message):
			return message
		case .httpStatus(let code, let body):
			return "Provider error (\(code)): \(body)"
		case .decoding:
			return "Could not decode the provider response."
		case .cancelled:
			return "Request cancelled."
		case .underlying(let message):
			return message
		}
	}
}

protocol AIPlugin: AnyObject {
	var id: String { get }
	var displayName: String { get }
	var subtitle: String { get }
	var defaultModel: String { get }
	var availableModels: [String] { get }
	var apiKeyAccount: String { get }
	var supportsBaseURLOverride: Bool { get }
	var defaultBaseURL: URL? { get }

	func complete(
		_ request: AICompletionRequest,
		apiKey: String,
		baseURL: URL?,
		onChunk: @escaping @Sendable (AICompletionChunk) -> Void
	) async throws
}

extension AIPlugin {
	var supportsBaseURLOverride: Bool { true }
}
