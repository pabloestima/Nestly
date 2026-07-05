import SwiftUI
import WatchKit

struct KickView: View {
    @EnvironmentObject private var store: KickStore

    @State private var intensity: String = "medium"
    @State private var buttonScale: CGFloat = 1.0
    @State private var flashOpacity: Double = 0.0
    @State private var countBump: Bool = false

    // Blush palette
    private let blush = Color(red: 0.831, green: 0.361, blue: 0.478)

    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [
                    Color(red: 0.992, green: 0.957, blue: 0.968),
                    Color(red: 0.988, green: 0.910, blue: 0.932)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            // Flash overlay on tap
            blush.opacity(flashOpacity).ignoresSafeArea()

            VStack(spacing: 0) {

                // ── Today count ──────────────────────────────
                VStack(spacing: 1) {
                    Text("TODAY")
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundStyle(blush.opacity(0.7))
                        .kerning(1.8)

                    Text("\(store.todayKicks.count)")
                        .font(.system(size: 38, weight: .bold, design: .serif))
                        .foregroundStyle(blush)
                        .scaleEffect(countBump ? 1.18 : 1.0)
                        .contentTransition(.numericText())
                }
                .padding(.top, 4)

                Spacer()

                // ── Kick button ──────────────────────────────
                Button(action: recordKick) {
                    ZStack {
                        Circle()
                            .fill(blush)
                            .shadow(color: blush.opacity(0.45), radius: 10, y: 4)

                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [.white.opacity(0.25), .clear],
                                    center: .init(x: 0.35, y: 0.3),
                                    startRadius: 0,
                                    endRadius: 32
                                )
                            )

                        Text("👶")
                            .font(.system(size: 30))
                    }
                    .frame(width: 68, height: 68)
                    .scaleEffect(buttonScale)
                }
                .buttonStyle(.plain)

                Spacer()

                // ── Last kick / prompt ────────────────────────
                Group {
                    if let last = store.lastKick {
                        Text(timeSince(last.timestamp))
                    } else {
                        Text("Tap to record a kick")
                    }
                }
                .font(.system(size: 11))
                .foregroundStyle(Color(red: 0.604, green: 0.494, blue: 0.533))
                .padding(.bottom, 4)
            }
            .padding(.horizontal, 8)
        }
    }

    // MARK: - Actions

    private func recordKick() {
        store.record(intensity: intensity)
        WKInterfaceDevice.current().play(.click)

        // Button bounce
        withAnimation(.spring(response: 0.18, dampingFraction: 0.5)) {
            buttonScale = 0.88
        }
        withAnimation(.spring(response: 0.28, dampingFraction: 0.55).delay(0.12)) {
            buttonScale = 1.0
        }

        // Count bump
        withAnimation(.spring(response: 0.2, dampingFraction: 0.4)) {
            countBump = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            withAnimation(.easeOut(duration: 0.2)) { countBump = false }
        }

        // Brief background flash
        withAnimation(.easeOut(duration: 0.08)) { flashOpacity = 0.12 }
        withAnimation(.easeOut(duration: 0.35).delay(0.08)) { flashOpacity = 0.0 }
    }

    // MARK: - Helpers

    private func timeSince(_ date: Date) -> String {
        let mins = Int(-date.timeIntervalSinceNow / 60)
        guard mins >= 1 else { return "just now" }
        guard mins >= 60 else { return "\(mins)m ago" }
        let hrs = mins / 60
        let rm  = mins % 60
        return rm == 0 ? "\(hrs)h ago" : "\(hrs)h \(rm)m ago"
    }
}

#Preview {
    KickView()
        .environmentObject(KickStore())
}
