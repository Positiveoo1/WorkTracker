import SwiftUI

struct ContentView: View {
    @StateObject private var vm = WorkEntryViewModel()
    @State private var selectedDate = Date()
    @State private var displayedMonth = Date()
    private let calendar = Calendar.current

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                CalendarView(selectedDate: $selectedDate, displayedMonth: $displayedMonth)
                    .frame(maxHeight: 350)
                Divider()
                EntryListView(vm: vm, selectedDate: $selectedDate)
                Divider()
                VStack(alignment: .leading) {
                    // Totals for displayed month
                    let monthHours = vm.totalHours(inMonth: displayedMonth)
                    let monthEarnings = vm.totalEarnings(inMonth: displayedMonth)
                    Text(String(format: "Month Total Hours: %.2f", monthHours))
                    Text(String(format: "Month Total Earned: %.2f PLN", monthEarnings))
                        .padding(.bottom, 8)
                    // Optionally, show overall total as well:
                    // Text(String(format: "All-time Total Hours: %.2f", vm.totalHoursAll()))
                    // Text(String(format: "All-time Total Earned: %.2f PLN", vm.totalEarningsAll()))
                }
                .padding(.horizontal)
            }
            .navigationTitle("Work Tracker")
        }
    }
}

#Preview {
    ContentView()
}
