import SwiftUI

/// Erscheint direkt nach dem Beenden – mit Lob und den wichtigsten Zahlen.
struct WalkSummaryView: View {
    @Environment(\.dismiss) private var dismiss
    let walk: Walk

    var body: some View {
        VStack(spacing: 20) {
            Text("Toll gemacht! 🎉")
                .font(.largeTitle.bold())
                .padding(.top, 24)

            WalkStats(walk: walk)

            WalkMapView(track: walk.track)
                .frame(maxHeight: .infinity)
                .clipShape(RoundedRectangle(cornerRadius: 16))

            Button {
                dismiss()
            } label: {
                Text("Fertig")
                    .font(.title2.bold())
                    .frame(maxWidth: .infinity, minHeight: 64)
            }
            .buttonStyle(.borderedProminent)
            .buttonBorderShape(.roundedRectangle(radius: 16))
        }
        .padding(24)
    }
}

/// Die vier Kennzahlen eines Spaziergangs.
struct WalkStats: View {
    let walk: Walk

    var body: some View {
        Grid(horizontalSpacing: 16, verticalSpacing: 16) {
            GridRow {
                StatTile(title: "Schritte", value: Format.steps(walk.steps), systemImage: "shoeprints.fill")
                StatTile(title: "Strecke", value: Format.kilometers(walk.distance), systemImage: "map")
            }
            GridRow {
                StatTile(title: "Dauer", value: Format.duration(walk.duration), systemImage: "clock")
                StatTile(title: "Start", value: Format.time(walk.startDate) + " Uhr", systemImage: "sunrise")
            }
        }
    }
}
