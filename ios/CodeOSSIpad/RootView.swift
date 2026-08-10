import SwiftUI

struct RootView: View {
	@EnvironmentObject private var workspace: WorkspaceStore
	@State private var columnVisibility = NavigationSplitViewVisibility.all
	@State private var showingSettings = false

	var body: some View {
		NavigationSplitView(columnVisibility: $columnVisibility) {
			FileSidebarView()
				.navigationTitle("Files")
				.toolbar {
					ToolbarItem(placement: .primaryAction) {
						Button {
							workspace.createFile()
						} label: {
							Image(systemName: "doc.badge.plus")
						}
						.accessibilityLabel("New file")
					}
				}
		} content: {
			EditorView()
				.navigationTitle(workspace.selectedFile?.name ?? "Editor")
				.navigationBarTitleDisplayMode(.inline)
				.toolbar {
					ToolbarItem(placement: .topBarTrailing) {
						Button {
							showingSettings = true
						} label: {
							Image(systemName: "gearshape")
						}
						.accessibilityLabel("Settings")
					}
				}
		} detail: {
			AIChatView()
				.navigationTitle("AI")
				.navigationBarTitleDisplayMode(.inline)
		}
		.navigationSplitViewStyle(.balanced)
		.sheet(isPresented: $showingSettings) {
			NavigationStack {
				SettingsView()
			}
			.presentationDetents([.large])
		}
	}
}
