import SwiftData
import SwiftUI

struct WalkDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var confirmDelete = false
    let walk: Walk

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                WalkMapView(track: walk.track)
                    .frame(height: 320)
                    .clipShape(RoundedRectangle(cornerRadius: 16))

                WalkStats(walk: walk)

                Button(role: .destructive) {
                    confirmDelete = true
                } label: {
                    Label("Spaziergang löschen", systemImage: "trash")
                        .frame(maxWidth: .infinity, minHeight: 48)
                }
                .buttonStyle(.bordered)
                .padding(.top, 24)
            }
            .padding(16)
        }
        .navigationTitle(Format.day(walk.startDate))
        .navigationBarTitleDisplayMode(.inline)
        .confirmationDialog("Diesen Spaziergang wirklich löschen?", isPresented: $confirmDelete, titleVisibility: .visible) {
            Button("Löschen", role: .destructive) {
                modelContext.delete(walk)
                try? modelContext.save()
                dismiss()
            }
            Button("Abbrechen", role: .cancel) {}
        }
    }
}
