import SwiftUI

@main
struct CodeOSSIpadApp: App {
	@StateObject private var workspace = WorkspaceStore()
	@StateObject private var pluginRegistry = AIPluginRegistry()
	@StateObject private var chatStore = AIChatStore()
	@StateObject private var settings = AppSettingsStore()
	@StateObject private var secrets = SecretStore()

	var body: some Scene {
		WindowGroup {
			RootView()
				.environmentObject(workspace)
				.environmentObject(pluginRegistry)
				.environmentObject(chatStore)
				.environmentObject(settings)
				.environmentObject(secrets)
				.onAppear {
					pluginRegistry.bootstrap()
					settings.load()
				}
		}
	}
}
