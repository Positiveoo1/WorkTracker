import SwiftUI

struct EntrySummaryView: View {
    @ObservedObject var vm: WorkEntryViewModel
    @EnvironmentObject var clientVM: ClientViewModel
    let entry: WorkEntry
    @State private var showingEdit = false

    var body: some View {
        Form {
            Section("Info") {
                LabeledContent("Date", value: DateFormatter.longDate.string(from: entry.date))
                LabeledContent("Title", value: entry.title.isEmpty ? "–" : entry.title)
            }
            Section("Time") {
                LabeledContent("Start",    value: DateFormatter.shortTime.string(from: entry.startTime))
                LabeledContent("End",      value: DateFormatter.shortTime.string(from: entry.endTime))
                LabeledContent("Gross",    value: String(format: "%.2f hours", entry.grossHours))

                if entry.breakMinutes > 0 {
                    LabeledContent("Break", value: "\(entry.breakMinutes) min")
                        .foregroundColor(.secondary)
                }

                LabeledContent("Net",      value: String(format: "%.2f hours", entry.totalHours))
                    .fontWeight(.semibold)
            }   
            Section("Earnings") {
                LabeledContent("Hourly Rate", value: String(format: "%.2f PLN", entry.hourlyRate))
                LabeledContent("Total Earned", value: String(format: "%.2f PLN", entry.earnings))
            }
        }
        .navigationTitle("Entry Details")
        .toolbar {
            Button("Edit") {
                showingEdit = true
            }
        }
        .sheet(isPresented: $showingEdit) {
            EntryDetailView(vm: vm, clientVM: clientVM, date: entry.date, entry: entry)
        }
    }

   
}
