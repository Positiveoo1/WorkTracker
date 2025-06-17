import SwiftUI

struct CalendarView: View {
    @Binding var selectedDate: Date
    @Binding var displayedMonth: Date
    private let calendar = Calendar.current

    private var days: [Date] {
        guard let monthInterval = calendar.dateInterval(of: .month, for: displayedMonth),
              let firstDayOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: displayedMonth))
        else { return [] }
        // Determine the start date for grid: beginning of week containing firstDayOfMonth
        let weekday = calendar.component(.weekday, from: firstDayOfMonth)
        let firstWeekday = calendar.firstWeekday // locale-based
        let offset = (weekday - firstWeekday + 7) % 7
        guard let gridStart = calendar.date(byAdding: .day, value: -offset, to: firstDayOfMonth) else { return [] }
        // 6 weeks grid (42 days)
        return (0..<42).compactMap { calendar.date(byAdding: .day, value: $0, to: gridStart) }
    }

    var body: some View {
        VStack {
            // Month header
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

            // Weekday labels
            let symbols = calendar.shortStandaloneWeekdaySymbols
            HStack {
                ForEach(symbols, id: \ .self) { sym in
                    Text(sym)
                        .frame(maxWidth: .infinity)
                        .font(.subheadline)
                }
            }

            // Days grid
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 8) {
                ForEach(days, id: \.self) { date in
                    DayCell(date: date,
                            isSelected: calendar.isDate(date, inSameDayAs: selectedDate),
                            isWithinMonth: calendar.isDate(date, equalTo: displayedMonth, toGranularity: .month))
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
    private let calendar = Calendar.current

    var body: some View {
        let day = calendar.component(.day, from: date)
        Text("\(day)")
            .frame(maxWidth: .infinity, minHeight: 40)
            .background(
                Group {
                    if isSelected {
                        Circle().fill(Color.accentColor.opacity(0.3))
                    } else {
                        Color.clear
                    }
                }
            )
            .foregroundColor(isWithinMonth ? .primary : .secondary)
    }
}
