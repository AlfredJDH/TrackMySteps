import Charts
import SwiftData
import SwiftUI

enum Period: String, CaseIterable, Identifiable {
    case week = "Woche"
    case month = "Monat"
    case year = "Jahr"

    var id: Self { self }

    /// Balken pro Tag (Woche, Monat) bzw. pro Monat (Jahr).
    var unit: Calendar.Component { self == .year ? .month : .day }

    var interval: ClosedRange<Date> {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now)
        switch self {
        case .week:
            return calendar.date(byAdding: .day, value: -6, to: today)!...calendar.date(byAdding: .day, value: 1, to: today)!
        case .month:
            return calendar.date(byAdding: .day, value: -29, to: today)!...calendar.date(byAdding: .day, value: 1, to: today)!
        case .year:
            let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: today))!
            return calendar.date(byAdding: .month, value: -11, to: monthStart)!...calendar.date(byAdding: .month, value: 1, to: monthStart)!
        }
    }

    var axisFormat: Date.FormatStyle {
        switch self {
        case .week: .dateTime.weekday(.abbreviated)
        case .month: .dateTime.day().month(.abbreviated)
        case .year: .dateTime.month(.narrow)
        }
    }

    var axisStride: Int { self == .month ? 7 : 1 }
}

struct StepBucket: Identifiable {
    let date: Date
    let steps: Int
    var id: Date { date }
}

struct DashboardView: View {
    @Query(filter: #Predicate<Walk> { $0.endDate != nil }, sort: \Walk.startDate, order: .reverse)
    private var walks: [Walk]
    @State private var period: Period = .week
    @State private var selectedDate: Date?

    private var walksInPeriod: [Walk] {
        walks.filter { period.interval.contains($0.startDate) }
    }

    private var buckets: [StepBucket] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: walksInPeriod) {
            calendar.dateInterval(of: period.unit, for: $0.startDate)!.start
        }
        return grouped
            .map { StepBucket(date: $0.key, steps: $0.value.reduce(0) { $0 + $1.steps }) }
            .sorted { $0.date < $1.date }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    Picker("Zeitraum", selection: $period) {
                        ForEach(Period.allCases) { Text($0.rawValue).tag($0) }
                    }
                    .pickerStyle(.segmented)
                    .controlSize(.large)

                    if walks.isEmpty {
                        ContentUnavailableView("Noch keine Spaziergänge",
                                               systemImage: "figure.walk",
                                               description: Text("Starte Deinen ersten Spaziergang mit dem großen grünen Knopf."))
                            .padding(.top, 40)
                    } else {
                        summary
                        chart
                        records
                        list
                    }
                }
                .padding(16)
            }
            .navigationTitle("Meine Spaziergänge")
            .navigationDestination(for: Walk.self) { WalkDetailView(walk: $0) }
        }
    }

    // MARK: Abschnitte

    private var summary: some View {
        let walks = walksInPeriod
        return Grid(horizontalSpacing: 16, verticalSpacing: 16) {
            GridRow {
                StatTile(title: "Spaziergänge", value: "\(walks.count)", systemImage: "figure.walk")
                StatTile(title: "Schritte", value: Format.steps(walks.reduce(0) { $0 + $1.steps }), systemImage: "shoeprints.fill")
            }
            GridRow {
                StatTile(title: "Strecke", value: Format.kilometers(walks.reduce(0) { $0 + $1.distance }), systemImage: "map")
                StatTile(title: "Zeit", value: Format.duration(walks.reduce(0) { $0 + $1.duration }), systemImage: "clock")
            }
        }
    }

    private var chart: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(period == .year ? "Schritte pro Monat" : "Schritte pro Tag")
                .font(.title3.bold())
            Text(selectionText)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Chart(buckets) { bucket in
                BarMark(x: .value("Datum", bucket.date, unit: period.unit),
                        y: .value("Schritte", bucket.steps))
                    .foregroundStyle(Color.accentColor)
                    .cornerRadius(4)
                    .opacity(selectedBucket == nil || selectedBucket?.date == bucket.date ? 1 : 0.4)
            }
            .chartXScale(domain: period.interval)
            .chartXAxis {
                AxisMarks(values: .stride(by: period.unit, count: period.axisStride)) {
                    AxisValueLabel(format: period.axisFormat)
                }
            }
            .chartYAxis {
                AxisMarks { _ in
                    AxisGridLine().foregroundStyle(.quaternary)
                    AxisValueLabel()
                }
            }
            .chartXSelection(value: $selectedDate)
            .frame(height: 220)
        }
    }

    private var selectedBucket: StepBucket? {
        guard let selectedDate else { return nil }
        let start = Calendar.current.dateInterval(of: period.unit, for: selectedDate)?.start
        return buckets.first { $0.date == start }
    }

    private var selectionText: String {
        guard let selectedBucket else { return "Tippe auf einen Balken für Details." }
        let date = period == .year
            ? selectedBucket.date.formatted(.dateTime.month(.wide).year())
            : Format.day(selectedBucket.date)
        return "\(date): \(Format.steps(selectedBucket.steps)) Schritte"
    }

    private var records: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Deine Rekorde")
                .font(.title3.bold())
            if let most = walks.max(by: { $0.steps < $1.steps }) {
                recordRow("Meiste Schritte", value: Format.steps(most.steps), walk: most, icon: "trophy.fill")
            }
            if let longest = walks.max(by: { $0.distance < $1.distance }) {
                recordRow("Längste Strecke", value: Format.kilometers(longest.distance), walk: longest, icon: "medal.fill")
            }
        }
    }

    private func recordRow(_ title: String, value: String, walk: Walk, icon: String) -> some View {
        NavigationLink(value: walk) {
            HStack {
                Image(systemName: icon).foregroundStyle(.yellow).font(.title2)
                VStack(alignment: .leading) {
                    Text(title).font(.headline)
                    Text(Format.day(walk.startDate)).font(.subheadline).foregroundStyle(.secondary)
                }
                Spacer()
                Text(value).font(.title3.bold()).monospacedDigit()
                Image(systemName: "chevron.right").foregroundStyle(.tertiary)
            }
            .padding(16)
            .background(.fill.tertiary, in: RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(.plain)
    }

    private var list: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Alle Spaziergänge")
                .font(.title3.bold())
            ForEach(walks) { walk in
                NavigationLink(value: walk) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(Format.day(walk.startDate)).font(.headline)
                            Text("\(Format.time(walk.startDate)) Uhr · \(Format.duration(walk.duration))")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        VStack(alignment: .trailing, spacing: 4) {
                            Text("\(Format.steps(walk.steps)) Schritte").font(.headline).monospacedDigit()
                            Text(Format.kilometers(walk.distance)).font(.subheadline).foregroundStyle(.secondary)
                        }
                        Image(systemName: "chevron.right").foregroundStyle(.tertiary)
                    }
                    .padding(16)
                    .background(.fill.tertiary, in: RoundedRectangle(cornerRadius: 16))
                }
                .buttonStyle(.plain)
            }
        }
    }
}
