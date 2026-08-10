import Foundation

enum HTTPJSONClient {
	static func postJSON(
		url: URL,
		headers: [String: String],
		body: [String: Any]
	) async throws -> (Data, HTTPURLResponse) {
		var request = URLRequest(url: url)
		request.httpMethod = "POST"
		request.setValue("application/json", forHTTPHeaderField: "Content-Type")
		for (key, value) in headers {
			request.setValue(value, forHTTPHeaderField: key)
		}
		request.httpBody = try JSONSerialization.data(withJSONObject: body, options: [])

		let (data, response) = try await URLSession.shared.data(for: request)
		guard let http = response as? HTTPURLResponse else {
			throw AIPluginError.underlying("Invalid HTTP response.")
		}
		return (data, http)
	}

	static func streamSSE(
		url: URL,
		headers: [String: String],
		body: [String: Any],
		onEvent: @escaping @Sendable (String) -> Void
	) async throws {
		var request = URLRequest(url: url)
		request.httpMethod = "POST"
		request.setValue("application/json", forHTTPHeaderField: "Content-Type")
		request.setValue("text/event-stream", forHTTPHeaderField: "Accept")
		for (key, value) in headers {
			request.setValue(value, forHTTPHeaderField: key)
		}
		request.httpBody = try JSONSerialization.data(withJSONObject: body, options: [])

		let (bytes, response) = try await URLSession.shared.bytes(for: request)
		guard let http = response as? HTTPURLResponse else {
			throw AIPluginError.underlying("Invalid HTTP response.")
		}
		guard (200..<300).contains(http.statusCode) else {
			var errorData = Data()
			for try await byte in bytes {
				errorData.append(byte)
				if errorData.count > 8_192 { break }
			}
			let message = String(data: errorData, encoding: .utf8) ?? "Unknown error"
			throw AIPluginError.httpStatus(http.statusCode, message)
		}

		var buffer = ""
		for try await line in bytes.lines {
			if Task.isCancelled { throw CancellationError() }
			if line.hasPrefix("data:") {
				let payload = line.dropFirst(5).trimmingCharacters(in: .whitespaces)
				if payload == "[DONE]" {
					return
				}
				onEvent(payload)
			} else if line.isEmpty {
				buffer = ""
			} else {
				buffer += line
			}
		}
	}
}

enum OpenAICompatPayload {
	static func messages(from request: AICompletionRequest) -> [[String: String]] {
		var result: [[String: String]] = []
		var system = request.systemPrompt
		if let context = request.editorContext, !context.isEmpty {
			system += "\n\nCurrent editor context:\n\(context)"
		}
		if !system.isEmpty {
			result.append(["role": "system", "content": system])
		}
		for message in request.messages where message.role != .system {
			result.append(["role": message.role.rawValue, "content": message.content])
		}
		return result
	}

	static func extractDeltaContent(from jsonLine: String) -> String? {
		guard let data = jsonLine.data(using: .utf8),
			  let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
			  let choices = object["choices"] as? [[String: Any]],
			  let first = choices.first else {
			return nil
		}
		if let delta = first["delta"] as? [String: Any], let content = delta["content"] as? String {
			return content
		}
		if let message = first["message"] as? [String: Any], let content = message["content"] as? String {
			return content
		}
		return nil
	}
}
