# Nestly — Apple Watch Setup

## Files in this folder

| File | Target |
|---|---|
| `NestlyWatchApp.swift` | watchOS App |
| `KickView.swift` | watchOS App |
| `KickStore.swift` | watchOS App |
| `PhoneReceiver.swift` | iOS App |

---

## Xcode setup (one-time)

### 1. Create an Xcode project

Open Xcode → **File › New › Project** → choose **iOS App** (SwiftUI).  
Name it **Nestly**, Bundle ID e.g. `com.yourname.nestly`.

### 2. Add a Watch App target

**File › New › Target** → **watchOS › Watch App** → name it **Nestly Watch**.  
When prompted, choose **Same bundle ID** so it can pair with the iOS app.

### 3. Add the source files

- Drag `NestlyWatchApp.swift`, `KickView.swift`, `KickStore.swift` into the **Nestly Watch** group. ✓ membership = Watch target only.
- Drag `PhoneReceiver.swift` into the **Nestly (iOS)** group. ✓ membership = iOS target only.

### 4. Embed the PWA in the iOS app

Replace the default iOS `ContentView.swift` with a `WKWebView` that loads `index.html` from the bundle:

```swift
import SwiftUI
import WebKit

struct ContentView: View {
    @StateObject private var receiver = PhoneReceiver()

    var body: some View {
        WebView(receiver: receiver)
            .ignoresSafeArea()
    }
}

struct WebView: UIViewRepresentable {
    let receiver: PhoneReceiver

    func makeUIView(context: Context) -> WKWebView {
        let wv = WKWebView()
        receiver.webView = wv
        if let url = Bundle.main.url(forResource: "index", withExtension: "html",
                                     subdirectory: "pwa") {
            wv.loadFileURL(url, allowingReadAccessTo: url.deletingLastPathComponent())
        }
        return wv
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {}
}
```

Copy the entire `ios/` folder contents (except the `watch/` folder) into `Nestly/pwa/` inside Xcode.

### 5. WatchConnectivity entitlement

Both targets need **no extra entitlement** — WCSession works automatically when the Watch and iPhone share the same development team.

### 6. Run

- Run the iOS scheme on your iPhone (or simulator).
- Run the **Nestly Watch** scheme on a paired Apple Watch or Watch simulator.
- Tap the 👶 button on the watch — the kick appears in the iOS app instantly.

---

## Watch UI summary

The Watch app shows only what matters at a glance:

```
  TODAY
   12          ← today's kick count (large serif)

    👶          ← big tap target (fills most of the screen)

  3m ago       ← time since last kick
```

Tapping gives haptic + visual feedback. The count animates up.  
No intensity selector on the watch (keeps it one-tap simple).  
Kicks sync to the iPhone app over WatchConnectivity when in range.
