import SwiftUI

/// Hauptbildschirm: ein großer Knopf zum Starten, große Zahlen während des Spaziergangs.
struct RecordView: View {
    @Environment(WalkRecorder.self) private var recorder
    @Environment(\.scenePhase) private var scenePhase
    @State private var todaySteps: Int?
    @State private var confirmStop = false

    var body: some View {
        VStack(spacing: 24) {
            if recorder.isRecording {
                recordingContent
            } else {
                idleContent
            }
        }
        .padding(24)
        .task { await refreshTodaySteps() }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { Task { await refreshTodaySteps() } }
        }
        .onChange(of: recorder.isRecording) { _, _ in
            Task { await refreshTodaySteps() }
        }
    }

    // MARK: Bereit

    private var idleContent: some View {
        VStack(spacing: 32) {
            Spacer()
            Text("Bereit für einen\nSpaziergang?")
                .font(.largeTitle.bold())
                .multilineTextAlignment(.center)

            Button {
                recorder.start()
            } label: {
                VStack(spacing: 8) {
                    Image(systemName: "figure.walk")
                        .font(.system(size: 72, weight: .bold))
                    Text("Los geht's")
                        .font(.title.bold())
                }
                .foregroundStyle(.white)
                .frame(width: 240, height: 240)
                .background(Circle().fill(Color.accentColor.gradient))
                .shadow(color: .black.opacity(0.15), radius: 12, y: 6)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Spaziergang starten")

            if let todaySteps {
                Text("Heute schon **\(Format.steps(todaySteps))** Schritte")
                    .font(.title3)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
    }

    // MARK: Unterwegs

    private var recordingContent: some View {
        VStack(spacing: 20) {
            Text("Schön, Du bist unterwegs!")
                .font(.title2.bold())

            VStack(spacing: 0) {
                Text(Format.steps(recorder.liveSteps))
                    .font(.system(size: 88, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)
                    .contentTransition(.numericText())
                Text("Schritte")
                    .font(.title2)
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: 16) {
                TimelineView(.periodic(from: .now, by: 1)) { context in
                    StatTile(title: "Zeit",
                             value: Format.clock(context.date.timeIntervalSince(recorder.startDate ?? context.date)),
                             systemImage: "clock")
                }
                StatTile(title: "Strecke", value: Format.kilometers(recorder.liveDistance), systemImage: "map")
            }

            WalkMapView(track: recorder.track, followsUser: true)
                .frame(maxHeight: .infinity)
                .clipShape(RoundedRectangle(cornerRadius: 16))

            if let problem = recorder.permissionProblem {
                Label(problem, systemImage: "exclamationmark.triangle.fill")
                    .font(.callout)
                    .foregroundStyle(.orange)
            } else {
                Text("Du kannst das Handy jetzt in die Tasche stecken.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }

            Button {
                confirmStop = true
            } label: {
                Label("Spaziergang beenden", systemImage: "stop.fill")
                    .font(.title2.bold())
                    .frame(maxWidth: .infinity, minHeight: 64)
            }
            .buttonStyle(.borderedProminent)
            .tint(.red)
            .buttonBorderShape(.roundedRectangle(radius: 16))
            .confirmationDialog("Spaziergang wirklich beenden?", isPresented: $confirmStop, titleVisibility: .visible) {
                Button("Ja, beenden", role: .destructive) {
                    Task { await recorder.stop() }
                }
                Button("Weiter spazieren", role: .cancel) {}
            }
        }
    }

    private func refreshTodaySteps() async {
        todaySteps = await recorder.stepsToday()
    }
}

/// Eine Kachel mit Wert und Beschriftung – wird überall in der App verwendet.
struct StatTile: View {
    let title: String
    let value: String
    let systemImage: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Label(title, systemImage: systemImage)
                .font(.headline)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.system(.title, design: .rounded).bold())
                .monospacedDigit()
                .minimumScaleFactor(0.6)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(.fill.tertiary, in: RoundedRectangle(cornerRadius: 16))
        .accessibilityElement(children: .combine)
    }
}
