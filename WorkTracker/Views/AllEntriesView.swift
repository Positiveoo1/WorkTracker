import SwiftUI

struct AllEntriesView: View {
    @ObservedObject var vm: WorkEntryViewModel
    @State private var searchText = ""

    private var filtered: [WorkEntry] {
        let all = vm.entries.sorted { $0.date > $1.date }
        if searchText.isEmpty { return all }
        return all.filter {
            $0.title.lowercased().contains(searchText.lowercased()) ||
            dateFormatter.string(from: $0.date).lowercased().contains(searchText.lowercased())
        }
    }

    private var grouped: [String: [WorkEntry]] {
        Dictionary(grouping: filtered) {
            monthFormatter.string(from: $0.date)
        }
    }

    var body: some View {
        List {
            ForEach(grouped.keys.sorted(by: >), id: \.self) { month in
                Section(header: Text(month)) {
                    ForEach(grouped[month] ?? []) { entry in
                        NavigationLink(destination: EntrySummaryView(vm: vm, entry: entry)) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(entry.title.isEmpty ? "No title" : entry.title)
                                    .font(.headline)
                                HStack {
                                    Text(dateFormatter.string(from: entry.date))
                                    Spacer()
                                    Text("\(timeFormatter.string(from: entry.startTime))–\(timeFormatter.string(from: entry.endTime))")
                                }
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                Text(String(format: "%.2f h • %.2f PLN", entry.totalHours, entry.earnings))
                                    .font(.caption)
                            }
                        }
                        .swipeActions {
                            Button(role: .destructive) {
                                Task {
                                    await vm.deleteEntry(entry)  // Fixed
                                }
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                }
            }
        }
        .searchable(text: $searchText, prompt: "Search by title or date")
        .navigationTitle("All Entries")
        .listStyle(.plain)
    }

    private var monthFormatter: DateFormatter {
        let f = DateFormatter()
        f.dateFormat = "LLLL yyyy"
        return f
    }

    private var dateFormatter: DateFormatter {
        let f = DateFormatter()
        f.dateStyle = .medium
        return f
    }

    private var timeFormatter: DateFormatter {
        let f = DateFormatter()
        f.timeStyle = .short
        return f
    }
}
