import Foundation
import Combine

@MainActor
final class AIPluginRegistry: ObservableObject {
	@Published private(set) var plugins: [any AIPlugin] = []

	func bootstrap() {
		plugins = [
			OpenAIPlugin(),
			AnthropicPlugin(),
			CursorPlugin(),
			KimiPlugin(),
			OpenAICompatiblePlugin(),
		]
	}

	func plugin(id: String) -> (any AIPlugin)? {
		plugins.first { $0.id == id }
	}
}
