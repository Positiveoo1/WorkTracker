import SwiftUI

struct CalendarView: View {
    @ObservedObject var vm: WorkEntryViewModel
    @Binding var selectedDate:    Date
    @Binding var displayedMonth:  Date
    var isCompact: Bool = false          // ← new

    private let calendar = Calendar.current

    private var days: [Date] {
        guard let monthStart = calendar.date(
            from: calendar.dateComponents([.year, .month], from: displayedMonth)
        ) else { return [] }
        let weekday  = calendar.component(.weekday, from: monthStart)
        let offset   = (weekday - calendar.firstWeekday + 7) % 7
        guard let gridStart = calendar.date(byAdding: .day, value: -offset, to: monthStart) else { return [] }
        return (0..<42).compactMap { calendar.date(byAdding: .day, value: $0, to: gridStart) }
    }

    private var weekdaySymbols: [String] {
        let symbols = calendar.shortStandaloneWeekdaySymbols
        let first   = calendar.firstWeekday - 1
        return Array(symbols[first...] + symbols[..<first])
    }

    // In compact mode show only the week that contains selectedDate
    private var visibleDays: [Date] {
        guard isCompact else { return days }
        guard let weekInterval = calendar.dateInterval(of: .weekOfYear, for: selectedDate) else { return days }
        return days.filter { weekInterval.contains($0) }
    }

    var body: some View {
        VStack(spacing: isCompact ? 4 : 8) {
            // Month navigator — always visible
            HStack {
                Button { changeMonth(by: -1) } label: {
                    Image(systemName: "chevron.left")
                        .frame(width: 44, height: 44)
                }
                Spacer()
                Text(DateFormatter.monthYear.string(from: displayedMonth))
                    .font(.headline)
                Spacer()
                Button { changeMonth(by: 1) } label: {
                    Image(systemName: "chevron.right")
                        .frame(width: 44, height: 44)
                }
            }
            .padding(.horizontal)

            // Weekday header
            HStack {
                ForEach(weekdaySymbols, id: \.self) {
                    Text($0)
                        .frame(maxWidth: .infinity)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, 4)

            // Day grid — full month or single week depending on isCompact
            let columns = Array(repeating: GridItem(.flexible(), spacing: 0), count: 7)

            LazyVGrid(columns: columns, spacing: isCompact ? 2 : 8) {
                ForEach(visibleDays, id: \.self) { date in
                    DayCell(
                        date:           date,
                        isSelected:     calendar.isDate(date, inSameDayAs: selectedDate),
                        isCurrentMonth: calendar.isDate(date, equalTo: displayedMonth, toGranularity: .month),
                        hasEntry:       vm.hasEntries(on: date),
                        isCompact:      isCompact            // ← passed through
                    )
                    .onTapGesture {
                        selectedDate = date
                        // Snap displayed month when tapping a day in the prev/next month
                        if !calendar.isDate(date, equalTo: displayedMonth, toGranularity: .month) {
                            displayedMonth = date
                        }
                    }
                }
            }
            .padding(.horizontal, 4)
            .animation(.easeInOut(duration: 0.25), value: isCompact)
        }
        .padding(.vertical, 8)
    }

    private func changeMonth(by offset: Int) {
        if let new = calendar.date(byAdding: .month, value: offset, to: displayedMonth) {
            displayedMonth = new
        }
    }
}

// MARK: - DayCell

struct DayCell: View {
    let date:           Date
    let isSelected:     Bool
    let isCurrentMonth: Bool
    let hasEntry:       Bool
    var isCompact:      Bool = false

    private let calendar = Calendar.current

    private var isToday: Bool {
        calendar.isDateInToday(date)
    }

    var body: some View {
        VStack(spacing: 2) {
            Text("\(calendar.component(.day, from: date))")
                .font(isCompact ? .footnote : .body)
                .fontWeight(isToday ? .bold : .regular)
                .foregroundColor(cellTextColor)
                .frame(maxWidth: .infinity, minHeight: isCompact ? 28 : 38)
                .background(cellBackground)

            // Entry dot indicator
            Circle()
                .fill(hasEntry && isCurrentMonth ? Color.accentColor : Color.clear)
                .frame(width: 4, height: 4)
        }
    }

    private var cellBackground: some View {
        Group {
            if isSelected {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.accentColor.opacity(0.25))
            } else if isToday {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.accentColor.opacity(0.08))
            } else {
                Color.clear
            }
        }
    }

    private var cellTextColor: Color {
        if isSelected         { return .accentColor }
        if !isCurrentMonth    { return .secondary.opacity(0.4) }
        if isToday            { return .accentColor }
        return .primary
    }
}
