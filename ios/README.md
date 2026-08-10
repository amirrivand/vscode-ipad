# Code OSS for iPadOS (native)

Native **iPad-only** SwiftUI app: file sidebar, code editor, and a streaming AI chat panel backed by an **internal AI plugin** system. No `WKWebView`, no Electron.

## Features

- iPad `NavigationSplitView` layout: **Files · Editor · AI**
- In-memory workspace (create / rename / delete files, monospace editor)
- Built-in AI plugins:
  - **OpenAI** (`api.openai.com`)
  - **Anthropic Claude** (Messages API)
  - **Cursor** (OpenAI-compatible base URL + API key)
  - **Kimi / Moonshot** (`api.moonshot.cn`)
  - **OpenAI Compatible** (DeepSeek, Groq, Ollama, Together, …)
- API keys stored in the **Keychain**
- Optional editor-context injection into prompts
- Quick actions: Explain / Refactor / Fix / Tests

## Requirements

- macOS with **Xcode 15+**
- Apple Developer Program (device + App Store)
- iPad / iPad Simulator (**iPadOS 17+**)

## Open and run

```bash
open ios/CodeOSSIpad.xcodeproj
```

1. Select **CodeOSSIpad**
2. Set your **Team** (Signing & Capabilities)
3. Run on an **iPad** destination
4. Open **Settings** → choose a plugin → paste API key → chat

## Add another AI provider

1. Create a type conforming to `AIPlugin` under `CodeOSSIpad/AI/Providers/`
2. Register it in `AIPluginRegistry.bootstrap()`
3. Add the Swift file to the Xcode target (already grouped under Providers)

```swift
protocol AIPlugin: AnyObject {
    var id: String { get }
    var displayName: String { get }
    var defaultModel: String { get }
    var availableModels: [String] { get }
    var apiKeyAccount: String { get }
    var defaultBaseURL: URL? { get }
    func complete(_ request: AICompletionRequest, apiKey: String, baseURL: URL?,
                  onChunk: @escaping @Sendable (AICompletionChunk) -> Void) async throws
}
```

## App Store notes

| Item | Notes |
|------|--------|
| Device | iPad only (`TARGETED_DEVICE_FAMILY = 2`) |
| Privacy | Keychain + UserDefaults declared in `PrivacyInfo.xcprivacy` |
| Network | App calls third-party AI HTTPS APIs you configure |
| Branding | Use **Code OSS** / your brand — not Microsoft “VS Code” trademarks |
| Review | Disclose AI providers and that user-supplied API keys leave the device |

Archive on a Mac: **Product → Archive → App Store Connect**.

## Layout

```
ios/CodeOSSIpad/
  CodeOSSIpadApp.swift
  RootView.swift
  Editor/          workspace + editor UI
  AI/              plugin protocol, chat, HTTP
  AI/Providers/    OpenAI, Anthropic, Cursor, Kimi, compatible
  Settings/        Keychain + settings UI
  Models/          app preferences
```

## Limits

- Not a port of the Electron VS Code workbench
- Workspace is in-app (not full Files app / Git yet)
- Cursor support expects an OpenAI-compatible gateway URL you configure
- This Linux environment cannot compile the `.ipa` — use Xcode on macOS
