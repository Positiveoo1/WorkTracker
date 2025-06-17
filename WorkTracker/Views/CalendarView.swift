import SwiftUI

struct CalendarView: View {
    @ObservedObject var vm: WorkEntryViewModel
    @Binding var selectedDate: Date
    @Binding var displayedMonth: Date
    private let calendar = Calendar.current

    // Compute the 42-day grid for the month
    private var days: [Date] {
        guard let firstDayOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: displayedMonth))
        else { return [] }
        let weekday = calendar.component(.weekday, from: firstDayOfMonth)
        let firstWeekday = calendar.firstWeekday
        let offset = (weekday - firstWeekday + 7) % 7
        guard let gridStart = calendar.date(byAdding: .day, value: -offset, to: firstDayOfMonth) else { return [] }
        return (0..<42).compactMap { calendar.date(byAdding: .day, value: $0, to: gridStart) }
    }

    // Rotate weekday symbols so they start on calendar.firstWeekday
    private var weekdaySymbols: [String] {
        let symbols = calendar.shortStandaloneWeekdaySymbols  // e.g. ["Sun","Mon",...]
        let firstIndex = calendar.firstWeekday - 1             // convert 1-based to 0-based
        guard firstIndex >= 0 && firstIndex < symbols.count else { return symbols }
        return Array(symbols[firstIndex...] + symbols[..<firstIndex])
    }

    var body: some View {
        VStack {
            HStack {
                Button(action: { changeMonth(by: -1) }) {
                    Image(systemName: "chevron.left")
                }
                Spacer()
                Text(monthYearFormatter.string(from: displayedMonth))
                    .font(.headline)
                Spacer()
                Button(action: { changeMonth(by: 1) }) {
                    Image(systemName: "chevron.right")
                }
            }
            .padding(.horizontal)

            // Weekday headers, aligned to locale first weekday
            HStack {
                ForEach(weekdaySymbols, id: \.self) { sym in
                    Text(sym)
                        .frame(maxWidth: .infinity)
                        .font(.subheadline)
                }
            }

            // Day cells
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 8) {
                ForEach(days, id: \.self) { date in
                    DayCell(
                        date: date,
                        isSelected: calendar.isDate(date, inSameDayAs: selectedDate),
                        isWithinMonth: calendar.isDate(date, equalTo: displayedMonth, toGranularity: .month),
                        hasEntry: vm.hasEntries(on: date)
                    )
                    .onTapGesture { selectedDate = date }
                }
            }
        }
    }

    private func changeMonth(by offset: Int) {
        if let new = calendar.date(byAdding: .month, value: offset, to: displayedMonth) {
            displayedMonth = new
        }
    }

    private var monthYearFormatter: DateFormatter {
        let df = DateFormatter()
        df.dateFormat = "LLLL yyyy"
        return df
    }
}

struct DayCell: View {
    let date: Date
    let isSelected: Bool
    let isWithinMonth: Bool
    let hasEntry: Bool

    private let calendar = Calendar.current

    var body: some View {
        let day = calendar.component(.day, from: date)
        Text("\(day)")
            .frame(maxWidth: .infinity, minHeight: 40)
            .background(
                Group {
                    if isSelected {
                        Circle().fill(Color.accentColor.opacity(0.3))
                    } else if hasEntry && isWithinMonth {
                        Circle().fill(Color.green.opacity(0.3))
                    } else {
                        Color.clear
                    }
                }
            )
            .foregroundColor(isWithinMonth ? .primary : .secondary)
    }
}

