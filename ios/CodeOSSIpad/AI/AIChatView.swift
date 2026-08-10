import SwiftUI

struct AIChatView: View {
	@EnvironmentObject private var chat: AIChatStore
	@EnvironmentObject private var registry: AIPluginRegistry
	@EnvironmentObject private var settings: AppSettingsStore
	@EnvironmentObject private var workspace: WorkspaceStore
	@EnvironmentObject private var secrets: SecretStore

	var body: some View {
		VStack(spacing: 0) {
			providerHeader

			ScrollViewReader { proxy in
				ScrollView {
					LazyVStack(alignment: .leading, spacing: 12) {
						ForEach(chat.messages) { message in
							MessageBubble(
								message: message,
								canApply: message.role == .assistant && !message.content.isEmpty && !chat.isStreaming
							) { mode in
								applyAssistant(message.content, mode: mode)
							}
							.id(message.id)
						}
					}
					.padding(16)
				}
				.onChange(of: chat.messages.last?.content) { _, _ in
					if let id = chat.messages.last?.id {
						withAnimation {
							proxy.scrollTo(id, anchor: .bottom)
						}
					}
				}
			}

			if let error = chat.errorMessage {
				Text(error)
					.font(.footnote)
					.foregroundStyle(.red)
					.frame(maxWidth: .infinity, alignment: .leading)
					.padding(.horizontal, 16)
					.padding(.bottom, 4)
			}

			composer
		}
		.background(Color(.systemGroupedBackground))
	}

	private var providerHeader: some View {
		HStack {
			if let plugin = registry.plugin(id: settings.selectedPluginID) {
				VStack(alignment: .leading, spacing: 2) {
					Text(plugin.displayName)
						.font(.subheadline.weight(.semibold))
					Text(settings.selectedModel.isEmpty ? plugin.defaultModel : settings.selectedModel)
						.font(.caption)
						.foregroundStyle(.secondary)
				}
			}
			Spacer()
			Toggle("Context", isOn: $chat.includeEditorContext)
				.labelsHidden()
				.accessibilityLabel("Include editor context")
			Text("Context")
				.font(.caption)
				.foregroundStyle(.secondary)
			Button {
				chat.clear()
			} label: {
				Image(systemName: "trash")
			}
			.disabled(chat.messages.isEmpty || chat.isStreaming)
		}
		.padding(.horizontal, 16)
		.padding(.vertical, 10)
		.background(Color(.secondarySystemBackground))
	}

	private var composer: some View {
		VStack(spacing: 8) {
			HStack(alignment: .bottom, spacing: 8) {
				TextField("Ask about the current file…", text: $chat.draft, axis: .vertical)
					.lineLimit(1...6)
					.textFieldStyle(.roundedBorder)

				if chat.isStreaming {
					Button {
						chat.cancel()
					} label: {
						Image(systemName: "stop.circle.fill")
							.font(.title2)
					}
					.accessibilityLabel("Stop")
				} else {
					Button {
						chat.send(
							registry: registry,
							settings: settings,
							workspace: workspace,
							secrets: secrets
						)
					} label: {
						Image(systemName: "arrow.up.circle.fill")
							.font(.title2)
					}
					.disabled(chat.draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
					.accessibilityLabel("Send")
				}
			}

			HStack {
				Button("Explain") { quickPrompt("Explain the current file clearly.") }
				Button("Refactor") { quickPrompt("Refactor the current file for clarity and propose a complete improved file in one fenced code block.") }
				Button("Fix") { quickPrompt("Find bugs in the current file and propose a complete fixed file in one fenced code block.") }
				Button("Tests") { quickPrompt("Write unit tests for the current file in one fenced code block.") }
			}
			.buttonStyle(.bordered)
			.font(.caption)
			.disabled(chat.isStreaming)
		}
		.padding(12)
		.background(Color(.secondarySystemBackground))
	}

	private func quickPrompt(_ text: String) {
		chat.draft = text
		chat.send(
			registry: registry,
			settings: settings,
			workspace: workspace,
			secrets: secrets
		)
	}

	private func applyAssistant(_ content: String, mode: ApplyMode) {
		let code = Self.extractPrimaryCodeBlock(from: content) ?? content
		switch mode {
		case .replace:
			workspace.replaceSelectedContent(code)
		case .append:
			workspace.appendToSelectedContent(code)
		}
	}

	private static func extractPrimaryCodeBlock(from markdown: String) -> String? {
		guard let start = markdown.range(of: "```") else { return nil }
		var rest = markdown[start.upperBound...]
		if let newline = rest.firstIndex(of: "\n") {
			rest = rest[rest.index(after: newline)...]
		}
		guard let end = rest.range(of: "```") else { return nil }
		return String(rest[..<end.lowerBound]).trimmingCharacters(in: .whitespacesAndNewlines)
	}
}

private enum ApplyMode {
	case replace
	case append
}

private struct MessageBubble: View {
	let message: AIChatMessage
	var canApply: Bool = false
	var onApply: ((ApplyMode) -> Void)?

	var body: some View {
		VStack(alignment: .leading, spacing: 6) {
			Text(message.role == .user ? "You" : "Assistant")
				.font(.caption.weight(.semibold))
				.foregroundStyle(.secondary)
			Text(message.content.isEmpty ? "…" : message.content)
				.font(.body)
				.textSelection(.enabled)
				.frame(maxWidth: .infinity, alignment: .leading)
				.padding(12)
				.background(
					message.role == .user
						? Color.accentColor.opacity(0.12)
						: Color(.systemBackground),
					in: RoundedRectangle(cornerRadius: 12, style: .continuous)
				)

			if canApply, let onApply {
				HStack {
					Button("Replace file") { onApply(.replace) }
					Button("Append") { onApply(.append) }
				}
				.buttonStyle(.bordered)
				.font(.caption)
			}
		}
	}
}
