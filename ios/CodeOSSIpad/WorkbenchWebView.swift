import SwiftUI
import WebKit

struct WorkbenchWebView: UIViewRepresentable {
	let url: URL
	@Binding var isLoading: Bool
	@Binding var lastError: String?

	func makeCoordinator() -> Coordinator {
		Coordinator(isLoading: $isLoading, lastError: $lastError)
	}

	func makeUIView(context: Context) -> WKWebView {
		let configuration = WKWebViewConfiguration()
		configuration.allowsInlineMediaPlayback = true
		configuration.mediaTypesRequiringUserActionForPlayback = []
		configuration.preferences.javaScriptCanOpenWindowsAutomatically = true
		configuration.defaultWebpagePreferences.allowsContentJavaScript = true

		let webView = WKWebView(frame: .zero, configuration: configuration)
		webView.navigationDelegate = context.coordinator
		webView.uiDelegate = context.coordinator
		webView.allowsBackForwardNavigationGestures = true
		webView.scrollView.keyboardDismissMode = .interactive
		webView.scrollView.contentInsetAdjustmentBehavior = .never
		#if DEBUG
		if #available(iOS 16.4, *) {
			webView.isInspectable = true
		}
		#endif

		context.coordinator.webView = webView
		webView.load(URLRequest(url: url))
		return webView
	}

	func updateUIView(_ webView: WKWebView, context: Context) {
		context.coordinator.isLoading = $isLoading
		context.coordinator.lastError = $lastError

		guard context.coordinator.loadedURL != url else {
			return
		}
		context.coordinator.loadedURL = url
		webView.load(URLRequest(url: url))
	}

	final class Coordinator: NSObject, WKNavigationDelegate, WKUIDelegate {
		var isLoading: Binding<Bool>
		var lastError: Binding<String?>
		weak var webView: WKWebView?
		var loadedURL: URL?

		init(isLoading: Binding<Bool>, lastError: Binding<String?>) {
			self.isLoading = isLoading
			self.lastError = lastError
		}

		func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
			isLoading.wrappedValue = true
			lastError.wrappedValue = nil
		}

		func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
			isLoading.wrappedValue = false
		}

		func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
			isLoading.wrappedValue = false
			lastError.wrappedValue = error.localizedDescription
		}

		func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
			isLoading.wrappedValue = false
			lastError.wrappedValue = error.localizedDescription
		}

		func webView(
			_ webView: WKWebView,
			createWebViewWith configuration: WKWebViewConfiguration,
			for navigationAction: WKNavigationAction,
			windowFeatures: WKWindowFeatures
		) -> WKWebView? {
			if navigationAction.targetFrame == nil, let url = navigationAction.request.url {
				webView.load(URLRequest(url: url))
			}
			return nil
		}

		func webView(
			_ webView: WKWebView,
			decidePolicyFor navigationAction: WKNavigationAction,
			decisionHandler: @escaping (WKNavigationActionPolicy) -> Void
		) {
			guard let url = navigationAction.request.url else {
				decisionHandler(.allow)
				return
			}

			// Keep OAuth / workbench flows inside the app; open unrelated schemes externally.
			if let scheme = url.scheme?.lowercased(),
			   scheme != "http",
			   scheme != "https",
			   scheme != "about",
			   scheme != "blob",
			   UIApplication.shared.canOpenURL(url) {
				UIApplication.shared.open(url)
				decisionHandler(.cancel)
				return
			}

			decisionHandler(.allow)
		}
	}
}
