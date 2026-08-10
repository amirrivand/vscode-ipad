# Code OSS for iPadOS

Native **iPad-only** shell that hosts the Code - OSS / VS Code **web workbench** in `WKWebView`. This is the App Store–oriented packaging surface for this fork: open the Xcode project on a Mac, sign it, and archive for TestFlight / App Store Connect.

> Electron cannot run on iPadOS. This app does **not** embed the desktop IDE. It wraps a remote (or self-hosted) web workbench.

## Requirements

- macOS with **Xcode 15+**
- Apple Developer Program membership (for device installs and App Store)
- An iPad or iPad Simulator (deployment target **iPadOS 17**)

## Open and run

```bash
open ios/CodeOSSIpad.xcodeproj
```

1. Select the **CodeOSSIpad** target.
2. Set your **Team** under Signing & Capabilities (`DEVELOPMENT_TEAM` is empty in the project on purpose).
3. Confirm **Bundle Identifier** `com.amirrivand.codeoss.ipad` (change if needed for your Apple ID).
4. Choose an **iPad** run destination (device family is `2` — iPad only).
5. Run.

Default workbench URL is `https://vscode.dev` (overridable in `Info.plist` key `WorkbenchURL`, or at runtime via the in-app gear).

## Point at your own workbench

For a product you control (recommended before App Store review):

1. Build the web workbench from this repo (`npm run compile-web` / gulp web targets — see upstream VS Code docs).
2. Host it (static CDN, Codespaces, code-server, etc.).
3. Set `WorkbenchURL` in [`CodeOSSIpad/Info.plist`](CodeOSSIpad/Info.plist) or enter the URL in the app settings sheet.

Local HTTP hosts are allowed via `NSAllowsLocalNetworking` for development.

## App Store checklist

| Item | Notes |
|------|--------|
| Device | iPad only (`TARGETED_DEVICE_FAMILY = 2`) |
| Icons | Add a 1024×1024 marketing icon in `Assets.xcassets/AppIcon.appiconset` |
| Privacy | `PrivacyInfo.xcprivacy` ships with UserDefaults reason `CA92.1` |
| Encryption | `ITSAppUsesNonExemptEncryption = false` (export compliance); revisit if you add custom crypto |
| Branding | Use **Code OSS** (or your own name). Do **not** use Microsoft “Visual Studio Code” / “VS Code” trademarks in the store listing without permission |
| Review risk | Thin web wrappers are often rejected. Prefer hosting **your own** workbench, add meaningful native value (auth, keyboard, offline cache, file providers), and explain the developer-tools use case in Review Notes |
| Screenshots | Capture on iPad Pro sizes required by App Store Connect |

### Archive & upload (on a Mac)

1. Product → Archive  
2. Distribute App → App Store Connect  
3. Complete listing, privacy nutrition labels, and review notes in App Store Connect  

## Project layout

```
ios/
  CodeOSSIpad.xcodeproj/     Xcode project (iPadOS)
  CodeOSSIpad/
    CodeOSSIpadApp.swift     App entry
    RootView.swift           Chrome + settings
    WorkbenchWebView.swift   WKWebView host
    Configuration.swift      URL resolution
    Info.plist               iPad orientations, WorkbenchURL
    PrivacyInfo.xcprivacy    Privacy manifest
    Assets.xcassets          App icon / accent
```

## Limits

- No local Node extension host, integrated terminal backend, or Electron native modules on-device.
- Full IDE features still depend on the remote/web workbench you load.
- This Linux CI environment cannot compile or sign the `.ipa`; use Xcode on macOS.
