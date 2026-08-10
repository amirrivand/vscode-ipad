import SwiftUI

struct EditorView: View {
	@EnvironmentObject private var workspace: WorkspaceStore

	var body: some View {
		Group {
			if let file = workspace.selectedFile {
				VStack(spacing: 0) {
					HStack {
						Text(file.languageHint.uppercased())
							.font(.caption.weight(.semibold))
							.foregroundStyle(.secondary)
						Spacer()
						Text("\(file.content.count) chars")
							.font(.caption)
							.foregroundStyle(.tertiary)
					}
					.padding(.horizontal, 16)
					.padding(.vertical, 8)
					.background(Color(.secondarySystemBackground))

					TextEditor(text: Binding(
						get: { workspace.selectedFile?.content ?? "" },
						set: { workspace.updateSelectedContent($0) }
					))
					.font(.system(.body, design: .monospaced))
					.scrollContentBackground(.hidden)
					.padding(8)
					.background(Color(.systemBackground))
				}
			} else {
				ContentUnavailableView(
					"No File Selected",
					systemImage: "doc.text",
					description: Text("Create or select a file from the sidebar.")
				)
			}
		}
	}
}
