import Foundation
import Combine

@MainActor
final class AIChatStore: ObservableObject {
	@Published var messages: [AIChatMessage] = []
	@Published var draft: String = ""
	@Published var isStreaming = false
	@Published var errorMessage: String?
	@Published var includeEditorContext = true

	private var streamTask: Task<Void, Never>?

	func clear() {
		streamTask?.cancel()
		messages.removeAll()
		errorMessage = nil
		isStreaming = false
	}

	func cancel() {
		streamTask?.cancel()
		streamTask = nil
		isStreaming = false
	}

	func send(
		registry: AIPluginRegistry,
		settings: AppSettingsStore,
		workspace: WorkspaceStore,
		secrets: SecretStore
	) {
		let trimmed = draft.trimmingCharacters(in: .whitespacesAndNewlines)
		guard !trimmed.isEmpty, !isStreaming else { return }
		guard let plugin = registry.plugin(id: settings.selectedPluginID) else {
			errorMessage = "No AI plugin selected."
			return
		}

		let apiKey = secrets.apiKey(for: plugin.apiKeyAccount) ?? ""
		guard !apiKey.isEmpty else {
			errorMessage = AIPluginError.missingAPIKey.localizedDescription
			return
		}

		let model = settings.selectedModel.isEmpty ? plugin.defaultModel : settings.selectedModel
		let baseURL = secrets.baseURL(for: plugin.id).flatMap(URL.init(string:))

		let userMessage = AIChatMessage(role: .user, content: trimmed)
		messages.append(userMessage)
		draft = ""
		errorMessage = nil
		isStreaming = true

		let assistantID = UUID()
		messages.append(AIChatMessage(id: assistantID, role: .assistant, content: ""))

		let history = messages.filter { $0.id != assistantID }
		let request = AICompletionRequest(
			model: model,
			systemPrompt: settings.systemPrompt,
			messages: history,
			temperature: settings.temperature,
			editorContext: includeEditorContext ? workspace.editorContextBlock() : nil
		)

		streamTask = Task { [weak self] in
			guard let self else { return }
			do {
				try await plugin.complete(request, apiKey: apiKey, baseURL: baseURL) { chunk in
					Task { @MainActor in
						guard let index = self.messages.firstIndex(where: { $0.id == assistantID }) else { return }
						self.messages[index].content += chunk.text
					}
				}
			} catch is CancellationError {
				self.errorMessage = nil
			} catch {
				self.errorMessage = error.localizedDescription
				if let index = self.messages.firstIndex(where: { $0.id == assistantID }),
				   self.messages[index].content.isEmpty {
					self.messages.remove(at: index)
				}
			}
			self.isStreaming = false
			self.streamTask = nil
		}
	}
}
