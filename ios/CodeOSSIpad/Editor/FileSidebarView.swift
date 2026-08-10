import SwiftUI

struct FileSidebarView: View {
	@EnvironmentObject private var workspace: WorkspaceStore
	@State private var renameText = ""
	@State private var renamingID: UUID?

	var body: some View {
		List(selection: $workspace.selectedFileID) {
			ForEach(workspace.files) { file in
				HStack {
					Image(systemName: "doc.text")
						.foregroundStyle(.secondary)
					Text(file.name)
						.lineLimit(1)
				}
				.tag(file.id)
				.contextMenu {
					Button("Rename") {
						renamingID = file.id
						renameText = file.name
					}
					Button("Delete", role: .destructive) {
						workspace.deleteFile(file.id)
					}
				}
			}
			.onDelete { indexSet in
				for index in indexSet {
					workspace.deleteFile(workspace.files[index].id)
				}
			}
		}
		.listStyle(.sidebar)
		.alert("Rename file", isPresented: Binding(
			get: { renamingID != nil },
			set: { if !$0 { renamingID = nil } }
		)) {
			TextField("File name", text: $renameText)
			Button("Save") {
				if let id = renamingID {
					workspace.select(id)
					workspace.renameSelected(to: renameText)
				}
				renamingID = nil
			}
			Button("Cancel", role: .cancel) {
				renamingID = nil
			}
		}
	}
}
