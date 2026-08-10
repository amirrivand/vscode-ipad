import Foundation
import Combine

@MainActor
final class AppSettingsStore: ObservableObject {
	@Published var selectedPluginID: String = OpenAIPlugin.pluginID
	@Published var selectedModel: String = ""
	@Published var systemPrompt: String = AppSettingsStore.defaultSystemPrompt
	@Published var temperature: Double = 0.2

	static let defaultSystemPrompt = """
	You are a coding assistant inside Code OSS for iPad. \
	Help with editing, explaining, refactoring, and generating code. \
	Prefer concise answers and fenced code blocks when proposing edits.
	"""

	private let defaults = UserDefaults.standard

	func load() {
		selectedPluginID = defaults.string(forKey: Keys.pluginID) ?? OpenAIPlugin.pluginID
		selectedModel = defaults.string(forKey: Keys.model) ?? ""
		systemPrompt = defaults.string(forKey: Keys.systemPrompt) ?? Self.defaultSystemPrompt
		temperature = defaults.object(forKey: Keys.temperature) as? Double ?? 0.2
	}

	func save() {
		defaults.set(selectedPluginID, forKey: Keys.pluginID)
		defaults.set(selectedModel, forKey: Keys.model)
		defaults.set(systemPrompt, forKey: Keys.systemPrompt)
		defaults.set(temperature, forKey: Keys.temperature)
	}

	private enum Keys {
		static let pluginID = "settings.pluginID"
		static let model = "settings.model"
		static let systemPrompt = "settings.systemPrompt"
		static let temperature = "settings.temperature"
	}
}
