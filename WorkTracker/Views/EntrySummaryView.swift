import SwiftUI

struct EntrySummaryView: View {
    @ObservedObject var vm: WorkEntryViewModel
    let entry: WorkEntry
    @State private var showingEdit = false

    var body: some View {
        Form {
            Section("Info") {
                LabeledContent("Date", value: dateFormatter.string(from: entry.date))
                LabeledContent("Title", value: entry.title.isEmpty ? "–" : entry.title)
            }
            Section("Time") {
                LabeledContent("Start", value: timeFormatter.string(from: entry.startTime))
                LabeledContent("End", value: timeFormatter.string(from: entry.endTime))
                LabeledContent("Duration", value: String(format: "%.2f hours", entry.totalHours))
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
            EntryDetailView(vm: vm, date: entry.date, entry: entry)
        }
    }

    private var dateFormatter: DateFormatter {
        let f = DateFormatter()
        f.dateStyle = .long
        return f
    }

    private var timeFormatter: DateFormatter {
        let f = DateFormatter()
        f.timeStyle = .short
        return f
    }
}
