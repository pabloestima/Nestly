import SwiftUI

@main
struct NestlyWatchApp: App {
    @StateObject private var store = KickStore()

    var body: some Scene {
        WindowGroup {
            KickView()
                .environmentObject(store)
        }
    }
}
