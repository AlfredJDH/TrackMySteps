import Foundation

enum Format {
    static func steps(_ value: Int) -> String {
        value.formatted(.number)
    }

    static func kilometers(_ meters: Double) -> String {
        (meters / 1000).formatted(.number.precision(.fractionLength(1...2))) + " km"
    }

    /// „1 Std., 5 Min.“
    static func duration(_ seconds: TimeInterval) -> String {
        if seconds < 60 { return "unter 1 Min." }
        return Duration.seconds(seconds).formatted(.units(allowed: [.hours, .minutes], width: .abbreviated))
    }

    /// „0:12:34“ – für die laufende Uhr.
    static func clock(_ seconds: TimeInterval) -> String {
        Duration.seconds(max(0, seconds)).formatted(.time(pattern: .hourMinuteSecond))
    }

    static func day(_ date: Date) -> String {
        date.formatted(.dateTime.weekday(.wide).day().month(.wide))
    }

    static func time(_ date: Date) -> String {
        date.formatted(date: .omitted, time: .shortened)
    }
}
