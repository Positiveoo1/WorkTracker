//
//  StatsView.swift
//  WorkTracker
//
//  Created by Abubakrsiddik Abdurakhimov on 24/05/2026.
//

import SwiftUI
import Charts

struct StatsView: View {
    @ObservedObject var vm: WorkEntryViewModel
    @State private var selectedPeriod: StatsPeriod = .week
    @State private var referenceDate = Date()
    init(vm: WorkEntryViewModel) {
            self._vm = ObservedObject(wrappedValue: vm)
        }

    enum StatsPeriod: String, CaseIterable {
        case week  = "Week"
        case month = "Month"
    }

    // MARK: - Derived data

    private var periodEntries: [WorkEntry] {
        switch selectedPeriod {
        case .week:  return vm.entries(inWeek: referenceDate)
        case .month: return vm.entries(inMonth: referenceDate)
        }
    }

    private var totalHours: Double {
        periodEntries.reduce(0) { $0 + $1.totalHours }
    }

    private var totalEarnings: Double {
        periodEntries.reduce(0) { $0 + $1.earnings }
    }

    private var averageHoursPerDay: Double {
        let days = activeDays.count
        return days == 0 ? 0 : totalHours / Double(days)
    }

    private var activeDays: Set<String> {
        Set(periodEntries.map { DateFormatter.mediumDate.string(from: $0.date) })
    }

    private var chartData: [DaySummary] {
        switch selectedPeriod {
        case .week:  return weekChartData()
        case .month: return monthChartData()
        }
    }

    // MARK: - Body

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    periodPicker
                    periodNavigator
                    summaryCards
                    hoursChart
                    earningsChart
                }
                .padding()
            }
            .navigationTitle("Statistics")
        }
    }

    // MARK: - Subviews

    private var periodPicker: some View {
        Picker("Period", selection: $selectedPeriod) {
            ForEach(StatsPeriod.allCases, id: \.self) { period in
                Text(period.rawValue).tag(period)
            }
        }
        .pickerStyle(.segmented)
    }

    private var periodNavigator: some View {
        HStack {
            Button {
                referenceDate = offset(referenceDate, by: -1)
            } label: {
                Image(systemName: "chevron.left")
                    .frame(width: 44, height: 44)
            }

            Spacer()

            Text(periodLabel)
                .font(.headline)

            Spacer()

            Button {
                referenceDate = offset(referenceDate, by: 1)
            } label: {
                Image(systemName: "chevron.right")
                    .frame(width: 44, height: 44)
            }
            .disabled(isCurrentPeriod)
        }
    }

    private var summaryCards: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            StatCard(title: "Hours", value: String(format: "%.1f", totalHours), unit: "hrs")
            StatCard(title: "Earned", value: String(format: "%.0f", totalEarnings), unit: "PLN")
            StatCard(title: "Avg/Day", value: String(format: "%.1f", averageHoursPerDay), unit: "hrs")
        }
    }

    private var hoursChart: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Hours Worked")
                .font(.headline)

            if chartData.isEmpty {
                emptyChartPlaceholder
            } else {
                Chart(chartData) { day in
                    BarMark(
                        x: .value("Day", day.label),
                        y: .value("Hours", day.hours)
                    )
                    .foregroundStyle(Color.accentColor)
                    .cornerRadius(4)
                }
                .frame(height: 180)
                .chartYAxis {
                    AxisMarks(position: .leading)
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }

    private var earningsChart: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Earnings (PLN)")
                .font(.headline)

            if chartData.isEmpty {
                emptyChartPlaceholder
            } else {
                Chart(chartData) { day in
                    LineMark(
                        x: .value("Day", day.label),
                        y: .value("PLN", day.earnings)
                    )
                    .foregroundStyle(Color.green)
                    .symbol(Circle())

                    AreaMark(
                        x: .value("Day", day.label),
                        y: .value("PLN", day.earnings)
                    )
                    .foregroundStyle(Color.green.opacity(0.15))
                }
                .frame(height: 180)
                .chartYAxis {
                    AxisMarks(position: .leading)
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }

    private var emptyChartPlaceholder: some View {
        HStack {
            Spacer()
            VStack(spacing: 8) {
                Image(systemName: "chart.bar.xaxis")
                    .font(.largeTitle)
                    .foregroundColor(.secondary)
                Text("No data for this period")
                    .foregroundColor(.secondary)
                    .font(.subheadline)
            }
            .padding(.vertical, 40)
            Spacer()
        }
    }

    // MARK: - Helpers

    private var periodLabel: String {
        switch selectedPeriod {
        case .week:
            let cal   = Calendar.current
            guard let weekInterval = cal.dateInterval(of: .weekOfYear, for: referenceDate) else { return "" }
            let start = DateFormatter.mediumDate.string(from: weekInterval.start)
            let end   = DateFormatter.mediumDate.string(from: cal.date(byAdding: .day, value: -1, to: weekInterval.end)!)
            return "\(start) – \(end)"
        case .month:
            return DateFormatter.monthYear.string(from: referenceDate)
        }
    }

    private var isCurrentPeriod: Bool {
        let cal = Calendar.current
        switch selectedPeriod {
        case .week:  return cal.isDate(referenceDate, equalTo: Date(), toGranularity: .weekOfYear)
        case .month: return cal.isDate(referenceDate, equalTo: Date(), toGranularity: .month)
        }
    }

    private func offset(_ date: Date, by value: Int) -> Date {
        let cal       = Calendar.current
        let component: Calendar.Component = selectedPeriod == .week ? .weekOfYear : .month
        return cal.date(byAdding: component, value: value, to: date) ?? date
    }

    private func weekChartData() -> [DaySummary] {
        let cal = Calendar.current
        guard let weekInterval = cal.dateInterval(of: .weekOfYear, for: referenceDate) else { return [] }

        return (0..<7).compactMap { offset -> DaySummary? in
            guard let day = cal.date(byAdding: .day, value: offset, to: weekInterval.start) else { return nil }
            let dayEntries = vm.entries(on: day)
            let label      = shortDayFormatter.string(from: day)
            return DaySummary(
                label:    label,
                hours:    dayEntries.reduce(0) { $0 + $1.totalHours },
                earnings: dayEntries.reduce(0) { $0 + $1.earnings }
            )
        }
    }

    private func monthChartData() -> [DaySummary] {
        let cal = Calendar.current
        guard let range = cal.range(of: .day, in: .month, for: referenceDate),
              let monthStart = cal.date(from: cal.dateComponents([.year, .month], from: referenceDate))
        else { return [] }

        return range.compactMap { dayNum -> DaySummary? in
            guard let day = cal.date(byAdding: .day, value: dayNum - 1, to: monthStart) else { return nil }
            let dayEntries = vm.entries(on: day)
            guard !dayEntries.isEmpty else { return nil }   // skip empty days in month view
            return DaySummary(
                label:    "\(dayNum)",
                hours:    dayEntries.reduce(0) { $0 + $1.totalHours },
                earnings: dayEntries.reduce(0) { $0 + $1.earnings }
            )
        }
    }

    private var shortDayFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "EEE"
        return f
    }()
}

// MARK: - Supporting types

struct DaySummary: Identifiable {
    let id       = UUID()
    let label:    String
    let hours:    Double
    let earnings: Double
}

struct StatCard: View {
    let title: String
    let value: String
    let unit:  String

    var body: some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
            Text(unit)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
}
