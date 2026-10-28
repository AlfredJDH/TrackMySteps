import CoreLocation
import CoreMotion
import Foundation
import Observation
import SwiftData

/// Nimmt einen Spaziergang auf: Schritte über den Bewegungssensor des iPhones (CMPedometer),
/// den Weg über GPS. Läuft auch weiter, wenn das Handy gesperrt in der Tasche steckt.
@MainActor
@Observable
final class WalkRecorder: NSObject {
    private(set) var isRecording = false
    private(set) var startDate: Date?
    private(set) var liveSteps = 0
    private(set) var track: [TrackPoint] = []
    private(set) var permissionProblem: String?
    /// Wird nach dem Beenden gesetzt, damit die Zusammenfassung angezeigt werden kann.
    var lastFinishedWalk: Walk?

    var liveDistance: Double { gpsDistance > 0 ? gpsDistance : livePedometerDistance }

    private let modelContext: ModelContext
    private let pedometer = CMPedometer()
    private let locationManager = CLLocationManager()
    private var backgroundSession: CLBackgroundActivitySession?
    private var currentWalk: Walk?
    private var lastLocation: CLLocation?
    private var gpsDistance: Double = 0
    private var livePedometerDistance: Double = 0
    private var lastSave = Date.distantPast

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        super.init()
        locationManager.delegate = self
        locationManager.activityType = .fitness
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = 5
        locationManager.pausesLocationUpdatesAutomatically = false
        locationManager.showsBackgroundLocationIndicator = true
    }

    // MARK: - Erlaubnisse

    /// Löst beide Erlaubnis-Abfragen aus (einmalig beim ersten Start).
    func requestPermissions() {
        if locationManager.authorizationStatus == .notDetermined {
            locationManager.requestWhenInUseAuthorization()
        }
        // Die erste Abfrage beim Schrittzähler löst den Bewegungs-Dialog aus.
        let now = Date.now
        pedometer.queryPedometerData(from: now.addingTimeInterval(-60), to: now) { _, _ in }
    }

    /// Schritte seit Mitternacht laut iPhone (auch ohne Spaziergang-Aufnahme).
    func stepsToday() async -> Int? {
        guard CMPedometer.isStepCountingAvailable() else { return nil }
        let result = await queryPedometer(from: Calendar.current.startOfDay(for: .now), to: .now)
        return result?.steps
    }

    // MARK: - Aufnahme

    func start() {
        guard !isRecording else { return }
        permissionProblem = nil

        let walk = Walk(startDate: .now)
        modelContext.insert(walk)
        try? modelContext.save()

        currentWalk = walk
        startDate = walk.startDate
        isRecording = true
        liveSteps = 0
        livePedometerDistance = 0
        gpsDistance = 0
        track = []
        lastLocation = nil

        startLocation()

        if CMPedometer.isStepCountingAvailable() {
            pedometer.startUpdates(from: walk.startDate) { [weak self] data, error in
                let steps = data?.numberOfSteps.intValue
                let distance = data?.distance?.doubleValue
                let notAuthorized = (error as NSError?)?.code == Int(CMErrorMotionActivityNotAuthorized.rawValue)
                Task { @MainActor in
                    guard let self else { return }
                    if let steps { self.liveSteps = steps }
                    if let distance { self.livePedometerDistance = distance }
                    if notAuthorized {
                        self.permissionProblem = "Schritte können nicht gezählt werden. Bitte in den Einstellungen unter „Datenschutz → Bewegung & Fitness“ erlauben."
                    }
                }
            }
        } else {
            permissionProblem = "Dieses iPhone kann leider keine Schritte zählen."
        }
    }

    func stop() async {
        guard let walk = currentWalk else { return }
        let end = Date.now

        pedometer.stopUpdates()
        locationManager.stopUpdatingLocation()
        backgroundSession?.invalidate()
        backgroundSession = nil

        walk.endDate = end
        walk.track = track
        walk.gpsDistance = gpsDistance
        // Die nachträgliche Abfrage ist am genauesten – sie enthält auch Schritte,
        // die während gesperrtem Bildschirm gezählt wurden.
        if let result = await queryPedometer(from: walk.startDate, to: end) {
            walk.steps = result.steps
            walk.pedometerDistance = result.distance
        } else {
            walk.steps = liveSteps
            walk.pedometerDistance = livePedometerDistance
        }
        try? modelContext.save()

        currentWalk = nil
        startDate = nil
        isRecording = false
        lastFinishedWalk = walk
    }

    /// Falls die App während eines Spaziergangs beendet wurde: den Spaziergang
    /// sauber abschließen, statt ihn zu verlieren.
    func recoverUnfinishedWalks() async {
        let descriptor = FetchDescriptor<Walk>(predicate: #Predicate { $0.endDate == nil })
        guard let unfinished = try? modelContext.fetch(descriptor) else { return }
        for walk in unfinished where walk !== currentWalk {
            let end = walk.track.last?.timestamp ?? walk.startDate
            if end.timeIntervalSince(walk.startDate) < 60 {
                modelContext.delete(walk)
                continue
            }
            walk.endDate = end
            if let result = await queryPedometer(from: walk.startDate, to: end) {
                walk.steps = result.steps
                walk.pedometerDistance = result.distance
            }
        }
        try? modelContext.save()
    }

    // MARK: - Hilfsfunktionen

    private func startLocation() {
        switch locationManager.authorizationStatus {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .denied, .restricted:
            permissionProblem = "Der Weg kann nicht aufgezeichnet werden. Bitte in den Einstellungen den Standort für „Spaziergang“ erlauben."
            return
        default:
            break
        }
        locationManager.allowsBackgroundLocationUpdates = true
        backgroundSession?.invalidate()
        backgroundSession = CLBackgroundActivitySession()
        locationManager.startUpdatingLocation()
    }

    private func queryPedometer(from start: Date, to end: Date) async -> (steps: Int, distance: Double)? {
        await withCheckedContinuation { continuation in
            pedometer.queryPedometerData(from: start, to: end) { data, _ in
                continuation.resume(returning: data.map { ($0.numberOfSteps.intValue, $0.distance?.doubleValue ?? 0) })
            }
        }
    }

    private func handle(_ locations: [CLLocation]) {
        guard isRecording, let startDate else { return }
        for location in locations {
            // Ungenaue oder veraltete Positionen verwerfen (z. B. zwischen Häusern).
            guard location.horizontalAccuracy >= 0,
                  location.horizontalAccuracy <= 25,
                  location.timestamp >= startDate.addingTimeInterval(-5) else { continue }
            if let lastLocation {
                let step = location.distance(from: lastLocation)
                guard step >= 3 else { continue } // GPS-Zittern im Stehen ignorieren
                gpsDistance += step
            }
            lastLocation = location
            track.append(TrackPoint(location))
        }
        saveProgressIfNeeded()
    }

    /// Zwischenspeichern, damit bei einem Absturz nichts verloren geht.
    private func saveProgressIfNeeded() {
        guard let walk = currentWalk, Date.now.timeIntervalSince(lastSave) > 30 else { return }
        walk.track = track
        walk.gpsDistance = gpsDistance
        walk.steps = liveSteps
        walk.pedometerDistance = livePedometerDistance
        try? modelContext.save()
        lastSave = .now
    }
}

extension WalkRecorder: CLLocationManagerDelegate {
    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        Task { @MainActor in self.handle(locations) }
    }

    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        Task { @MainActor in
            let status = self.locationManager.authorizationStatus
            if self.isRecording, status == .authorizedWhenInUse || status == .authorizedAlways {
                self.permissionProblem = nil
                self.startLocation()
            }
        }
    }
}
