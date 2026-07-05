// Add this file to your iOS app target (not the Watch target).
// It listens for kick messages from the Apple Watch and writes them
// into the same localStorage key Nestly uses, via a WKWebView bridge.
//
// Usage: instantiate PhoneReceiver and hold it for the app's lifetime,
// then pass it the WKWebView that hosts index.html.

import Foundation
import WatchConnectivity
import WebKit

final class PhoneReceiver: NSObject, WCSessionDelegate, ObservableObject {
    weak var webView: WKWebView?

    override init() {
        super.init()
        guard WCSession.isSupported() else { return }
        WCSession.default.delegate = self
        WCSession.default.activate()
    }

    // Called when a kick arrives from the Watch
    func session(_ session: WCSession,
                 didReceiveMessage message: [String: Any]) {
        guard
            let ts        = message["ts"]        as? Double,
            let intensity = message["intensity"] as? String
        else { return }

        // Inject the kick into the PWA's localStorage on the main thread
        DispatchQueue.main.async { [weak self] in
            let js = """
            (function() {
              var STORAGE_KEY = 'nestly_v1';
              var todayKey = new Date().toDateString();
              var raw = localStorage.getItem(STORAGE_KEY);
              var data = raw ? JSON.parse(raw) : { v2: true, allKicks: {} };
              if (!data.allKicks) data.allKicks = {};
              if (!data.allKicks[todayKey]) data.allKicks[todayKey] = [];
              data.allKicks[todayKey].push({ ts: \(ts), intensity: '\(intensity)' });
              localStorage.setItem(STORAGE_KEY, JSON.stringify(data));
              if (typeof save === 'function') save();
              if (typeof updateStatus === 'function') updateStatus();
              if (typeof renderHistory === 'function') renderHistory();
            })();
            """
            self?.webView?.evaluateJavaScript(js, completionHandler: nil)
        }
    }

    // WCSessionDelegate stubs
    func session(_ session: WCSession,
                 activationDidCompleteWith state: WCSessionActivationState,
                 error: Error?) {}

    func sessionDidBecomeInactive(_ session: WCSession) {}
    func sessionDidDeactivate(_ session: WCSession) {
        WCSession.default.activate()
    }
}
