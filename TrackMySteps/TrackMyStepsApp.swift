import SwiftData
import SwiftUI

@main
struct TrackMyStepsApp: App {
    private let container: ModelContainer
    @State private var recorder: WalkRecorder

    init() {
        let container: ModelContainer
        do {
            container = try ModelContainer(for: Walk.self)
        } catch {
            fatalError("Datenbank konnte nicht geöffnet werden: \(error)")
        }
        self.container = container
        _recorder = State(initialValue: WalkRecorder(modelContext: container.mainContext))
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(recorder)
                .task { await recorder.recoverUnfinishedWalks() }
        }
        .modelContainer(container)
    }
}
