import SwiftUI

struct ContentView: View {
    @Environment(WalkRecorder.self) private var recorder
    @AppStorage("hatWillkommenGesehen") private var hasSeenWelcome = false

    var body: some View {
        @Bindable var recorder = recorder
        TabView {
            RecordView()
                .tabItem { Label("Spazieren", systemImage: "figure.walk") }
            DashboardView()
                .tabItem { Label("Meine Spaziergänge", systemImage: "chart.bar.fill") }
        }
        .fullScreenCover(isPresented: Binding(get: { !hasSeenWelcome }, set: { hasSeenWelcome = !$0 })) {
            WelcomeView { hasSeenWelcome = true }
        }
        .sheet(item: $recorder.lastFinishedWalk) { walk in
            WalkSummaryView(walk: walk)
        }
    }
}

/// Einmaliger Willkommens-Bildschirm, der die beiden Erlaubnisse erklärt.
struct WelcomeView: View {
    @Environment(WalkRecorder.self) private var recorder
    let onDone: () -> Void

    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            Image(systemName: "figure.walk.circle.fill")
                .font(.system(size: 120))
                .foregroundStyle(.tint)
            Text("Willkommen!")
                .font(.largeTitle.bold())
            Text("Diese App zählt Deine Schritte und zeichnet Deinen Weg auf.\n\nGleich fragt das iPhone zweimal um Erlaubnis. Bitte beide Male auf **„Erlauben“** tippen.")
                .font(.title3)
                .multilineTextAlignment(.center)
            Spacer()
            Button {
                recorder.requestPermissions()
                onDone()
            } label: {
                Text("Weiter")
                    .font(.title2.bold())
                    .frame(maxWidth: .infinity, minHeight: 64)
            }
            .buttonStyle(.borderedProminent)
            .buttonBorderShape(.roundedRectangle(radius: 16))
        }
        .padding(24)
    }
}
