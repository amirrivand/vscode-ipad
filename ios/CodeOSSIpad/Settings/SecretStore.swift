import Foundation
import Security

@MainActor
final class SecretStore: ObservableObject {
	private let service = "com.amirrivand.codeoss.ipad.secrets"

	func apiKey(for account: String) -> String? {
		read(account: account)
	}

	func setAPIKey(_ value: String, for account: String) {
		let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
		if trimmed.isEmpty {
			delete(account: account)
		} else {
			write(trimmed, account: account)
		}
		objectWillChange.send()
	}

	func baseURL(for pluginID: String) -> String? {
		read(account: "baseURL.\(pluginID)")
	}

	func setBaseURL(_ value: String, for pluginID: String) {
		let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
		let account = "baseURL.\(pluginID)"
		if trimmed.isEmpty {
			delete(account: account)
		} else {
			write(trimmed, account: account)
		}
		objectWillChange.send()
	}

	private func write(_ value: String, account: String) {
		let data = Data(value.utf8)
		let query: [String: Any] = [
			kSecClass as String: kSecClassGenericPassword,
			kSecAttrService as String: service,
			kSecAttrAccount as String: account,
		]
		SecItemDelete(query as CFDictionary)
		var add = query
		add[kSecValueData as String] = data
		add[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
		SecItemAdd(add as CFDictionary, nil)
	}

	private func read(account: String) -> String? {
		let query: [String: Any] = [
			kSecClass as String: kSecClassGenericPassword,
			kSecAttrService as String: service,
			kSecAttrAccount as String: account,
			kSecReturnData as String: true,
			kSecMatchLimit as String: kSecMatchLimitOne,
		]
		var item: CFTypeRef?
		let status = SecItemCopyMatching(query as CFDictionary, &item)
		guard status == errSecSuccess, let data = item as? Data else { return nil }
		return String(data: data, encoding: .utf8)
	}

	private func delete(account: String) {
		let query: [String: Any] = [
			kSecClass as String: kSecClassGenericPassword,
			kSecAttrService as String: service,
			kSecAttrAccount as String: account,
		]
		SecItemDelete(query as CFDictionary)
	}
}
