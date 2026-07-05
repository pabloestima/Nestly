import Foundation
import WatchConnectivity

struct KickRecord: Codable, Identifiable {
    let id: UUID
    let timestamp: Date
    let intensity: String   // "gentle" | "medium" | "strong"

    init(intensity: String = "medium") {
        self.id        = UUID()
        self.timestamp = Date()
        self.intensity = intensity
    }
}

final class KickStore: NSObject, ObservableObject, WCSessionDelegate {
    @Published private(set) var kicks: [KickRecord] = []

    private let storageKey = "nestly_watch_kicks"

    override init() {
        super.init()
        load()
        activateWCSession()
    }

    // MARK: - Computed

    var todayKicks: [KickRecord] {
        kicks.filter { Calendar.current.isDateInToday($0.timestamp) }
    }

    var lastKick: KickRecord? { todayKicks.last }

    // MARK: - Actions

    func record(intensity: String = "medium") {
        let kick = KickRecord(intensity: intensity)
        kicks.append(kick)
        save()
        sendToPhone(kick)
    }

    // MARK: - Persistence

    private func save() {
        let cutoff = Date().addingTimeInterval(-7 * 86400)
        kicks = kicks.filter { $0.timestamp > cutoff }
        if let data = try? JSONEncoder().encode(kicks) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
    }

    private func load() {
        guard
            let data   = UserDefaults.standard.data(forKey: storageKey),
            let stored = try? JSONDecoder().decode([KickRecord].self, from: data)
        else { return }
        kicks = stored
    }

    // MARK: - WatchConnectivity (sends kick to paired iPhone)

    private func activateWCSession() {
        guard WCSession.isSupported() else { return }
        WCSession.default.delegate = self
        WCSession.default.activate()
    }

    private func sendToPhone(_ kick: KickRecord) {
        guard WCSession.default.isReachable else { return }
        let payload: [String: Any] = [
            "ts":        kick.timestamp.timeIntervalSince1970 * 1000,
            "intensity": kick.intensity
        ]
        WCSession.default.sendMessage(payload, replyHandler: nil, errorHandler: nil)
    }

    // WCSessionDelegate stubs
    func session(_ session: WCSession,
                 activationDidCompleteWith state: WCSessionActivationState,
                 error: Error?) {}
}
