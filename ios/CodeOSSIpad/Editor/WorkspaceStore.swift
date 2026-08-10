import Foundation
import Combine

struct WorkspaceFile: Identifiable, Hashable, Codable {
	let id: UUID
	var name: String
	var content: String
	var languageHint: String

	init(id: UUID = UUID(), name: String, content: String, languageHint: String? = nil) {
		self.id = id
		self.name = name
		self.content = content
		self.languageHint = languageHint ?? WorkspaceFile.guessLanguage(for: name)
	}

	static func guessLanguage(for name: String) -> String {
		switch (name as NSString).pathExtension.lowercased() {
		case "swift": return "swift"
		case "ts", "tsx": return "typescript"
		case "js", "jsx": return "javascript"
		case "py": return "python"
		case "go": return "go"
		case "rs": return "rust"
		case "java": return "java"
		case "kt": return "kotlin"
		case "md": return "markdown"
		case "json": return "json"
		case "yml", "yaml": return "yaml"
		case "html": return "html"
		case "css": return "css"
		case "sh": return "shell"
		default: return "plaintext"
		}
	}
}

@MainActor
final class WorkspaceStore: ObservableObject {
	@Published var files: [WorkspaceFile] {
		didSet { scheduleSave() }
	}
	@Published var selectedFileID: UUID? {
		didSet { scheduleSave() }
	}

	private var saveTask: Task<Void, Never>?
	private let saveURL: URL

	var selectedFile: WorkspaceFile? {
		files.first { $0.id == selectedFileID }
	}

	var selectedFileIndex: Int? {
		files.firstIndex { $0.id == selectedFileID }
	}

	init() {
		let folder = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
			.appendingPathComponent("CodeOSSIpad", isDirectory: true)
		try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
		saveURL = folder.appendingPathComponent("workspace.json")

		if let data = try? Data(contentsOf: saveURL),
		   let decoded = try? JSONDecoder().decode(PersistedWorkspace.self, from: data),
		   !decoded.files.isEmpty {
			self.files = decoded.files
			self.selectedFileID = decoded.selectedFileID ?? decoded.files.first?.id
		} else {
			let starter = WorkspaceFile(
				name: "Welcome.swift",
				content: """
				import Foundation

				/// Code OSS for iPad — native editor with AI plugins.
				struct Welcome {
					func hello() -> String {
						"Hello, iPadOS"
					}
				}
				"""
			)
			self.files = [starter]
			self.selectedFileID = starter.id
		}
	}

	func select(_ id: UUID) {
		selectedFileID = id
	}

	func updateSelectedContent(_ content: String) {
		guard let index = selectedFileIndex else { return }
		files[index].content = content
	}

	func replaceSelectedContent(_ content: String) {
		updateSelectedContent(content)
	}

	func appendToSelectedContent(_ content: String) {
		guard let index = selectedFileIndex else { return }
		if files[index].content.isEmpty {
			files[index].content = content
		} else {
			files[index].content += "\n\n" + content
		}
	}

	func renameSelected(to name: String) {
		guard let index = selectedFileIndex else { return }
		let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
		guard !trimmed.isEmpty else { return }
		files[index].name = trimmed
		files[index].languageHint = WorkspaceFile.guessLanguage(for: trimmed)
	}

	func createFile(named name: String = "Untitled.swift") {
		var unique = name
		var n = 1
		while files.contains(where: { $0.name == unique }) {
			let base = (name as NSString).deletingPathExtension
			let ext = (name as NSString).pathExtension
			unique = ext.isEmpty ? "\(base)\(n)" : "\(base)\(n).\(ext)"
			n += 1
		}
		let file = WorkspaceFile(name: unique, content: "")
		files.append(file)
		selectedFileID = file.id
	}

	func deleteFile(_ id: UUID) {
		files.removeAll { $0.id == id }
		if selectedFileID == id {
			selectedFileID = files.first?.id
		}
	}

	func editorContextBlock() -> String {
		guard let file = selectedFile else {
			return "No file is open."
		}
		return """
		File: \(file.name)
		Language: \(file.languageHint)

		```\(file.languageHint)
		\(file.content)
		```
		"""
	}

	private func scheduleSave() {
		saveTask?.cancel()
		saveTask = Task {
			try? await Task.sleep(nanoseconds: 250_000_000)
			guard !Task.isCancelled else { return }
			persist()
		}
	}

	private func persist() {
		let payload = PersistedWorkspace(files: files, selectedFileID: selectedFileID)
		guard let data = try? JSONEncoder().encode(payload) else { return }
		try? data.write(to: saveURL, options: [.atomic])
	}
}

private struct PersistedWorkspace: Codable {
	var files: [WorkspaceFile]
	var selectedFileID: UUID?
}
