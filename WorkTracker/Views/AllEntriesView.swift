import SwiftUI

struct AllEntriesView: View {
    @ObservedObject var vm: WorkEntryViewModel
    @State private var searchText      = ""
    @State private var entryToDelete:  WorkEntry? = nil
    @State private var showDeleteAlert = false

    private var filtered: [WorkEntry] {
        let all = vm.entries.sorted { $0.date > $1.date }
        if searchText.isEmpty { return all }
        return all.filter {
            $0.title.lowercased().contains(searchText.lowercased()) ||
            DateFormatter.mediumDate.string(from: $0.date)
                .lowercased().contains(searchText.lowercased())
        }
    }

    private var grouped: [String: [WorkEntry]] {
        Dictionary(grouping: filtered) {
            DateFormatter.monthYear.string(from: $0.date)
        }
    }

    var body: some View {
        Group {
            if vm.isLoading {
                VStack(spacing: 16) {
                    ProgressView()
                    Text("Loading all entries…")
                        .foregroundColor(.secondary)
                        .font(.subheadline)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            } else {
                List {
                    ForEach(grouped.keys.sorted(by: >), id: \.self) { month in
                        Section(header: Text(month)) {
                            ForEach(grouped[month] ?? []) { entry in
                                NavigationLink(
                                    destination: EntrySummaryView(vm: vm, entry: entry)
                                ) {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(entry.title.isEmpty ? "No title" : entry.title)
                                            .font(.headline)

                                        HStack {
                                            Text(DateFormatter.mediumDate.string(from: entry.date))
                                            Spacer()
                                            Text(
                                                "\(DateFormatter.shortTime.string(from: entry.startTime))–\(DateFormatter.shortTime.string(from: entry.endTime))"
                                            )
                                        }
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)

                                        HStack(spacing: 4) {
                                            Text(String(format: "%.2f h", entry.totalHours))
                                            if entry.breakMinutes > 0 {
                                                Text("(\(entry.breakMinutes)m break)")
                                                    .foregroundColor(.orange)
                                            }
                                            Text("•")
                                            Text(String(format: "%.2f PLN", entry.earnings))
                                        }
                                        .font(.caption)
                                    }
                                }
                                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                    Button(role: .destructive) {
                                        entryToDelete  = entry
                                        showDeleteAlert = true
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                            }
                        }
                    }
                }
                .searchable(text: $searchText, prompt: "Search by title or date")
            }
        }
        .navigationTitle("All Entries")
        .listStyle(.plain)
        .confirmationDialog(
            deleteDialogTitle,
            isPresented: $showDeleteAlert,
            titleVisibility: .visible
        ) {
            Button("Delete Entry", role: .destructive) {
                guard let entry = entryToDelete else { return }
                Task { await vm.deleteEntry(entry) }
                entryToDelete = nil
            }
            Button("Cancel", role: .cancel) {
                entryToDelete = nil
            }
        } message: {
            Text(deleteDialogMessage)
        }
    }

    // MARK: - Helpers

    private var deleteDialogTitle: String {
        guard let entry = entryToDelete else { return "Delete Entry" }
        return entry.title.isEmpty ? "Delete Untitled Entry" : "Delete \"\(entry.title)\""
    }

    private var deleteDialogMessage: String {
        guard let entry = entryToDelete else { return "" }
        return String(
            format: "%@ – %@  •  %.2f h  •  %.2f PLN",
            DateFormatter.shortTime.string(from: entry.startTime),
            DateFormatter.shortTime.string(from: entry.endTime),
            entry.totalHours,
            entry.earnings
        )
    }
}
