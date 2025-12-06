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
                Button { showingAdd = true } label: {
                    Image(systemName: "plus.circle").font(.title2)
                }
            }
            .padding(.horizontal)
            .padding(.top, 8)

            List {
                ForEach(vm.entries(on: selectedDate)) { entry in
                    NavigationLink(destination: EntrySummaryView(vm: vm, entry: entry)) {
                        VStack(alignment: .leading) {
                            Text(entry.title.isEmpty ? "No Title" : entry.title)
                                .font(.headline)
                            Text("\(timeFormatter.string(from: entry.startTime)) – \(timeFormatter.string(from: entry.endTime))")
                            Text(String(format: "%.2f h • %.2f PLN", entry.totalHours, entry.earnings))
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                    .swipeActions {
                        Button(role: .destructive) {
                            Task {
                                await vm.deleteEntry(entry)  // Now properly awaited
                            }
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                }
            }
            .listStyle(.plain)
        }
        .sheet(isPresented: $showingAdd) {
            EntryDetailView(vm: vm, date: selectedDate)
        }
    }

    private var dayFormatter: DateFormatter {
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
