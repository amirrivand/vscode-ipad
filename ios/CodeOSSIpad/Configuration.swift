import Foundation

enum AppConfiguration {
	static let workbenchURLKey = "WorkbenchURL"
	static let defaultWorkbenchURL = "https://vscode.dev"

	/// Prefer Info.plist override, then UserDefaults, then the built-in default.
	static var workbenchURL: URL {
		if let plistValue = Bundle.main.object(forInfoDictionaryKey: workbenchURLKey) as? String,
		   let url = normalizedURL(from: plistValue) {
			return url
		}

		if let saved = UserDefaults.standard.string(forKey: workbenchURLKey),
		   let url = normalizedURL(from: saved) {
			return url
		}

		return URL(string: defaultWorkbenchURL)!
	}

	static var workbenchURLString: String {
		workbenchURL.absoluteString
	}

	static func saveWorkbenchURL(_ raw: String) -> URL? {
		guard let url = normalizedURL(from: raw) else {
			return nil
		}
		UserDefaults.standard.set(url.absoluteString, forKey: workbenchURLKey)
		return url
	}

	static func normalizedURL(from raw: String) -> URL? {
		let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
		guard !trimmed.isEmpty else {
			return nil
		}

		if let url = URL(string: trimmed), url.scheme != nil, url.host != nil {
			return url
		}

		return URL(string: "https://\(trimmed)")
	}
}
