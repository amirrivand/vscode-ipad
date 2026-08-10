import SwiftUI

struct RootView: View {
	@State private var workbenchURL = AppConfiguration.workbenchURL
	@State private var urlDraft = AppConfiguration.workbenchURLString
	@State private var isLoading = false
	@State private var lastError: String?
	@State private var showingSettings = false
	@State private var reloadToken = UUID()

	var body: some View {
		ZStack(alignment: .top) {
			WorkbenchWebView(
				url: workbenchURL,
				isLoading: $isLoading,
				lastError: $lastError
			)
			.id(reloadToken)
			.ignoresSafeArea()

			if isLoading {
				ProgressView()
					.padding(10)
					.background(.ultraThinMaterial, in: Capsule())
					.padding(.top, 12)
			}
		}
		.overlay(alignment: .topTrailing) {
			Button {
				showingSettings = true
			} label: {
				Image(systemName: "gearshape")
					.font(.body.weight(.semibold))
					.padding(10)
					.background(.ultraThinMaterial, in: Circle())
			}
			.padding(16)
			.accessibilityLabel("Workbench settings")
		}
		.alert("Could not load workbench", isPresented: Binding(
			get: { lastError != nil },
			set: { if !$0 { lastError = nil } }
		)) {
			Button("Retry") {
				reloadToken = UUID()
			}
			Button("Settings") {
				showingSettings = true
			}
			Button("Dismiss", role: .cancel) {}
		} message: {
			Text(lastError ?? "Unknown error")
		}
		.sheet(isPresented: $showingSettings) {
			NavigationStack {
				Form {
					Section {
						TextField("https://vscode.dev", text: $urlDraft)
							.textInputAutocapitalization(.never)
							.autocorrectionDisabled()
							.keyboardType(.URL)
					} header: {
						Text("Workbench URL")
					} footer: {
						Text("Point this at vscode.dev, GitHub Codespaces, a self-hosted code-server, or your own Code - OSS web build. For App Store distribution, host your own Code - OSS web workbench and avoid Microsoft VS Code trademarks.")
					}

					Section {
						Button("Reload workbench") {
							applyURLAndReload()
						}
					}
				}
				.navigationTitle("Code OSS iPad")
				.navigationBarTitleDisplayMode(.inline)
				.toolbar {
					ToolbarItem(placement: .cancellationAction) {
						Button("Close") {
							showingSettings = false
						}
					}
					ToolbarItem(placement: .confirmationAction) {
						Button("Save") {
							applyURLAndReload()
						}
					}
				}
			}
			.presentationDetents([.medium, .large])
		}
	}

	private func applyURLAndReload() {
		guard let url = AppConfiguration.saveWorkbenchURL(urlDraft) else {
			lastError = "Enter a valid http(s) URL."
			return
		}
		workbenchURL = url
		urlDraft = url.absoluteString
		reloadToken = UUID()
		showingSettings = false
	}
}
