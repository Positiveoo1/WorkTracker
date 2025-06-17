import SwiftUI

struct EntryListView: View {
    @ObservedObject var vm: WorkEntryViewModel
    @Binding var selectedDate: Date
    @State private var showingAdd = false

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Entries for \(dayFormatter.string(from: selectedDate))")
                    .font(.headline)
                Spacer()
                Button(action: { showingAdd = true }) {
                    Image(systemName: "plus.circle")
                        .font(.title2)
                }
            }
            .padding(.horizontal)
            .padding(.top, 8)

            List {
                ForEach(vm.entries(on: selectedDate)) { entry in
                    VStack(alignment: .leading) {
                        Text("Start: \(timeFormatter.string(from: entry.startTime)), End: \(timeFormatter.string(from: entry.endTime))")
                        Text(String(format: "Hours: %.2f, Earned: %.2f PLN", entry.totalHours, entry.earnings))
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .swipeActions {
                        Button(role: .destructive) {
                            vm.deleteEntry(entry)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                }
            }
            .listStyle(PlainListStyle())
        }
        .sheet(isPresented: $showingAdd) {
            EntryDetailView(vm: vm, date: selectedDate)
        }
    }

    private var dayFormatter: DateFormatter {
        let df = DateFormatter()
        df.dateStyle = .medium
        return df
    }
    private var timeFormatter: DateFormatter {
        let df = DateFormatter()
        df.timeStyle = .short
        return df
    }
}

