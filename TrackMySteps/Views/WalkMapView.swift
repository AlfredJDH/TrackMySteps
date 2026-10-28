import MapKit
import SwiftUI

/// Karte mit dem gelaufenen Weg (grüne Linie), Start- und Zielpunkt.
struct WalkMapView: View {
    let track: [TrackPoint]
    var followsUser = false

    @State private var position: MapCameraPosition = .automatic

    var body: some View {
        let coordinates = track.map(\.coordinate)
        Map(position: $position) {
            if coordinates.count > 1 {
                MapPolyline(coordinates: coordinates)
                    .stroke(Color.accentColor, style: StrokeStyle(lineWidth: 6, lineCap: .round, lineJoin: .round))
            }
            if let first = coordinates.first {
                Annotation("Start", coordinate: first) {
                    Image(systemName: "flag.fill")
                        .padding(6)
                        .background(Circle().fill(.white))
                        .foregroundStyle(.green)
                }
            }
            if !followsUser, let last = coordinates.last, coordinates.count > 1 {
                Annotation("Ziel", coordinate: last) {
                    Image(systemName: "flag.checkered")
                        .padding(6)
                        .background(Circle().fill(.white))
                        .foregroundStyle(.black)
                }
            }
            if followsUser {
                UserAnnotation()
            }
        }
        .onAppear {
            if followsUser {
                position = .userLocation(fallback: .automatic)
            }
        }
    }
}
