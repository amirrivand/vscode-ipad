import SwiftUI

struct SettingsView: View {
	@EnvironmentObject private var registry: AIPluginRegistry
	@EnvironmentObject private var settings: AppSettingsStore
	@EnvironmentObject private var secrets: SecretStore
	@Environment(\.dismiss) private var dismiss

	@State private var apiKeyDrafts: [String: String] = [:]
	@State private var baseURLDrafts: [String: String] = [:]

	var body: some View {
		Form {
			Section {
				Picker("Provider plugin", selection: $settings.selectedPluginID) {
					ForEach(registry.plugins, id: \.id) { plugin in
						Text(plugin.displayName).tag(plugin.id)
					}
				}
				.onChange(of: settings.selectedPluginID) { _, newValue in
					if let plugin = registry.plugin(id: newValue) {
						settings.selectedModel = plugin.defaultModel
					}
					settings.save()
				}

				if let plugin = registry.plugin(id: settings.selectedPluginID) {
					Picker("Model", selection: $settings.selectedModel) {
						ForEach(plugin.availableModels, id: \.self) { model in
							Text(model).tag(model)
						}
					}
					.onChange(of: settings.selectedModel) { _, _ in
						settings.save()
					}

					Text(plugin.subtitle)
						.font(.footnote)
						.foregroundStyle(.secondary)
				}
			} header: {
				Text("AI plugin")
			}

			if let plugin = registry.plugin(id: settings.selectedPluginID) {
				Section {
					SecureField("API key", text: bindingAPIKey(for: plugin))
						.textInputAutocapitalization(.never)
						.autocorrectionDisabled()

					if plugin.supportsBaseURLOverride {
						TextField(
							plugin.defaultBaseURL?.absoluteString ?? "https://api.example.com/v1",
							text: bindingBaseURL(for: plugin)
						)
						.textInputAutocapitalization(.never)
						.autocorrectionDisabled()
						.keyboardType(.URL)
					}
				} header: {
					Text("Credentials")
				} footer: {
					Text("Keys are stored in the iOS Keychain on this device. They are never committed to the repo.")
				}
			}

			Section("Assistant") {
				TextField("System prompt", text: $settings.systemPrompt, axis: .vertical)
					.lineLimit(3...8)
					.onChange(of: settings.systemPrompt) { _, _ in settings.save() }

				HStack {
					Text("Temperature")
					Slider(value: $settings.temperature, in: 0...1, step: 0.05) {
						Text("Temperature")
					}
					.onChange(of: settings.temperature) { _, _ in settings.save() }
					Text(settings.temperature, format: .number.precision(.fractionLength(2)))
						.font(.caption.monospacedDigit())
						.foregroundStyle(.secondary)
				}
			}

			Section("Built-in plugins") {
				ForEach(registry.plugins, id: \.id) { plugin in
					VStack(alignment: .leading, spacing: 2) {
						Text(plugin.displayName).font(.body.weight(.medium))
						Text(plugin.subtitle).font(.caption).foregroundStyle(.secondary)
					}
					.padding(.vertical, 2)
				}
			}
		}
		.navigationTitle("Settings")
		.navigationBarTitleDisplayMode(.inline)
		.toolbar {
			ToolbarItem(placement: .confirmationAction) {
				Button("Done") {
					persistSecrets()
					settings.save()
					dismiss()
				}
			}
		}
		.onAppear {
			loadDrafts()
			if settings.selectedModel.isEmpty,
			   let plugin = registry.plugin(id: settings.selectedPluginID) {
				settings.selectedModel = plugin.defaultModel
			}
		}
	}

	private func bindingAPIKey(for plugin: any AIPlugin) -> Binding<String> {
		Binding(
			get: { apiKeyDrafts[plugin.apiKeyAccount] ?? secrets.apiKey(for: plugin.apiKeyAccount) ?? "" },
			set: { apiKeyDrafts[plugin.apiKeyAccount] = $0 }
		)
	}

	private func bindingBaseURL(for plugin: any AIPlugin) -> Binding<String> {
		Binding(
			get: {
				baseURLDrafts[plugin.id]
					?? secrets.baseURL(for: plugin.id)
					?? plugin.defaultBaseURL?.absoluteString
					?? ""
			},
			set: { baseURLDrafts[plugin.id] = $0 }
		)
	}

	private func loadDrafts() {
		for plugin in registry.plugins {
			apiKeyDrafts[plugin.apiKeyAccount] = secrets.apiKey(for: plugin.apiKeyAccount) ?? ""
			baseURLDrafts[plugin.id] = secrets.baseURL(for: plugin.id)
				?? plugin.defaultBaseURL?.absoluteString
				?? ""
		}
	}

	private func persistSecrets() {
		for plugin in registry.plugins {
			if let key = apiKeyDrafts[plugin.apiKeyAccount] {
				secrets.setAPIKey(key, for: plugin.apiKeyAccount)
			}
			if plugin.supportsBaseURLOverride, let url = baseURLDrafts[plugin.id] {
				secrets.setBaseURL(url, for: plugin.id)
			}
		}
	}
}
