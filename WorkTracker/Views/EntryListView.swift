import SwiftUI

struct EntryListView: View {
    @ObservedObject var vm:       WorkEntryViewModel
    @ObservedObject var clientVM: ClientViewModel
    @Binding var selectedDate:    Date
    @State private var showingAdd       = false
    @State private var entryToDelete:   WorkEntry? = nil   // ← pending delete
    @State private var showDeleteAlert  = false

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Entries for \(DateFormatter.longDate.string(from: selectedDate))")
                    .font(.headline)
                Spacer()
                Button { showingAdd = true } label: {
                    Image(systemName: "plus.circle").font(.title2)
                }
            }
            .padding(.horizontal)
            .padding(.top, 8)

            let dayEntries = vm.entries(on: selectedDate)

            if vm.isLoading {
                VStack(spacing: 12) {
                    ForEach(0..<3, id: \.self) { _ in ShimmerRow() }
                }
                .padding()

            } else if dayEntries.isEmpty {
                emptyState

            } else {
                List {
                    ForEach(dayEntries) { entry in
                        NavigationLink(destination: EntrySummaryView(vm: vm, entry: entry)) {
                            EntryRow(entry: entry, client: clientVM.client(for: entry.clientId))
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
                .listStyle(.plain)
            }
        }
        .sheet(isPresented: $showingAdd) {
            EntryDetailView(vm: vm, clientVM: clientVM, date: selectedDate)
        }
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
    
    // MARK: - Entry row

    struct EntryRow: View {
        let entry:  WorkEntry
        let client: Client?

        var body: some View {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    if let client {
                        Circle()
                            .fill(Color(hex: client.colorHex))
                            .frame(width: 8, height: 8)
                        Text(client.name)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Text(entry.title.isEmpty ? "No Title" : entry.title)
                        .font(.headline)
                }

                Text("\(DateFormatter.shortTime.string(from: entry.startTime)) – \(DateFormatter.shortTime.string(from: entry.endTime))")
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
                .foregroundColor(.secondary)
            }
            .padding(.vertical, 2)
        }
    }

    // MARK: - Shimmer skeleton row

    struct ShimmerRow: View {
        @State private var shimmer = false

        var body: some View {
            HStack(spacing: 12) {
                RoundedRectangle(cornerRadius: 4)
                    .frame(width: 40, height: 40)
                VStack(alignment: .leading, spacing: 6) {
                    RoundedRectangle(cornerRadius: 4).frame(height: 14)
                    RoundedRectangle(cornerRadius: 4).frame(width: 120, height: 12)
                }
            }
            .foregroundColor(Color(.systemGray5))
            .opacity(shimmer ? 0.4 : 1.0)
            .animation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true), value: shimmer)
            .onAppear { shimmer = true }
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

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "clock")
                .font(.system(size: 40))
                .foregroundColor(.secondary)
            Text("No entries for this day")
                .font(.headline)
            Text("Tap + to log your work hours")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}   
