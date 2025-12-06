import SwiftUI

struct CalendarView: View {
    @ObservedObject var vm: WorkEntryViewModel
    @Binding var selectedDate: Date
    @Binding var displayedMonth: Date
    private let calendar = Calendar.current

    private var days: [Date] {
        guard let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: displayedMonth)) else { return [] }
        let weekday = calendar.component(.weekday, from: monthStart)
        let offset = (weekday - calendar.firstWeekday + 7) % 7
        guard let gridStart = calendar.date(byAdding: .day, value: -offset, to: monthStart) else { return [] }
        return (0..<42).compactMap { calendar.date(byAdding: .day, value: $0, to: gridStart) }
    }

    private var weekdaySymbols: [String] {
        let symbols = calendar.shortStandaloneWeekdaySymbols
        let first = calendar.firstWeekday - 1
        return Array(symbols[first...] + symbols[..<first])
    }

    var body: some View {
        VStack {
            HStack {
                Button { changeMonth(by: -1) } label: { Image(systemName: "chevron.left") }
                Spacer()
                Text(monthYearFormatter.string(from: displayedMonth)).font(.headline)
                Spacer()
                Button { changeMonth(by: 1) } label: { Image(systemName: "chevron.right") }
            }
            .padding(.horizontal)

            HStack {
                ForEach(weekdaySymbols, id: \.self) { Text($0).frame(maxWidth: .infinity).font(.subheadline) }
            }

            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 8) {
                ForEach(days, id: \.self) { date in
                    DayCell(
                        date: date,
                        isSelected: calendar.isDate(date, inSameDayAs: selectedDate),
                        isCurrentMonth: calendar.isDate(date, equalTo: displayedMonth, toGranularity: .month),
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
        let f = DateFormatter()
        f.dateFormat = "LLLL yyyy"
        return f
    }
}

struct DayCell: View {
    let date: Date
    let isSelected: Bool
    let isCurrentMonth: Bool
    let hasEntry: Bool
    private let calendar = Calendar.current

    var body: some View {
        Text("\(calendar.component(.day, from: date))")
            .frame(maxWidth: .infinity, minHeight: 40)
            .background(
                Group {
                    if isSelected { Circle().fill(Color.accentColor.opacity(0.3)) }
                    else if hasEntry && isCurrentMonth { Circle().fill(Color.green.opacity(0.3)) }
                    else { Color.clear }
                }
            )
            .foregroundColor(isCurrentMonth ? .primary : .secondary)
    }
}
