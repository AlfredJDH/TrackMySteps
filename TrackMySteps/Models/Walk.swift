import CoreLocation
import Foundation
import SwiftData

/// Ein einzelner GPS-Punkt des aufgezeichneten Weges.
struct TrackPoint: Codable, Hashable {
    var latitude: Double
    var longitude: Double
    var altitude: Double
    var timestamp: Date

    init(_ location: CLLocation) {
        latitude = location.coordinate.latitude
        longitude = location.coordinate.longitude
        altitude = location.altitude
        timestamp = location.timestamp
    }

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}

@Model
final class Walk {
    var startDate: Date
    /// `nil`, solange der Spaziergang noch läuft.
    var endDate: Date?
    var steps: Int
    /// Strecke laut Schrittzähler des iPhones (Meter).
    var pedometerDistance: Double
    /// Strecke laut GPS (Meter).
    var gpsDistance: Double
    /// Die GPS-Punkte als JSON – hält das Datenmodell einfach.
    @Attribute(.externalStorage) var trackData: Data

    init(startDate: Date = .now) {
        self.startDate = startDate
        self.endDate = nil
        self.steps = 0
        self.pedometerDistance = 0
        self.gpsDistance = 0
        self.trackData = Data()
    }

    var track: [TrackPoint] {
        get { (try? JSONDecoder().decode([TrackPoint].self, from: trackData)) ?? [] }
        set { trackData = (try? JSONEncoder().encode(newValue)) ?? Data() }
    }

    var duration: TimeInterval {
        (endDate ?? .now).timeIntervalSince(startDate)
    }

    /// GPS ist beim Gehen meist genauer; ohne GPS nehmen wir die Schätzung des Schrittzählers.
    var distance: Double {
        gpsDistance > 0 ? gpsDistance : pedometerDistance
    }
}
