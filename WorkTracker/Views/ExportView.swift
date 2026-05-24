//
//  ExportView.swift
//  WorkTracker
//
//  Created by Abubakrsiddik Abdurakhimov on 24/05/2026.
//

import SwiftUI

struct ExportView: View {
    @ObservedObject var vm: WorkEntryViewModel
    @Environment(\.dismiss) var dismiss

    @State private var selectedRange: ExportRange = .thisMonth
    @State private var customStart   = Calendar.current.date(byAdding: .month, value: -1, to: Date()) ?? Date()
    @State private var customEnd     = Date()
    @State private var isExporting   = false
    @State private var shareItem:    ShareItem? = nil
    @State private var showError     = false
    @State private var errorMessage  = ""

    enum ExportRange: String, CaseIterable {
        case thisMonth  = "This Month"
        case lastMonth  = "Last Month"
        case thisYear   = "This Year"
        case allTime    = "All Time"
        case custom     = "Custom Range"
    }

    // MARK: - Filtered entries for preview

    private var filteredEntries: [WorkEntry] {
        let interval = dateInterval(for: selectedRange)
        return vm.entries
            .filter { interval?.contains($0.date) ?? true }
            .sorted { $0.date < $1.date }
    }

    private var totalHours: Double    { filteredEntries.reduce(0) { $0 + $1.totalHours } }
    private var totalEarnings: Double { filteredEntries.reduce(0) { $0 + $1.earnings } }

    // MARK: - Body

    var body: some View {
        NavigationView {
            Form {
                // Range picker
                Section("Export Range") {
                    Picker("Range", selection: $selectedRange) {
                        ForEach(ExportRange.allCases, id: \.self) {
                            Text($0.rawValue).tag($0)
                        }
                    }
                    .pickerStyle(.menu)

                    if selectedRange == .custom {
                        DatePicker("From", selection: $customStart, displayedComponents: .date)
                        DatePicker("To",   selection: $customEnd,   in: customStart..., displayedComponents: .date)
                    }
                }

                // Preview summary
                Section("Preview") {
                    LabeledContent("Entries",  value: "\(filteredEntries.count)")
                    LabeledContent("Hours",    value: String(format: "%.2f hrs", totalHours))
                    LabeledContent("Earnings", value: String(format: "%.2f PLN", totalEarnings))
                }

                // Export button
                Section {
                    Button {
                        Task { await exportCSV() }
                    } label: {
                        HStack {
                            Spacer()
                            if isExporting {
                                ProgressView()
                                    .padding(.trailing, 8)
                            }
                            Label("Export CSV", systemImage: "square.and.arrow.up")
                                .fontWeight(.semibold)
                            Spacer()
                        }
                    }
                    .disabled(isExporting || filteredEntries.isEmpty)
                }
            }
            .navigationTitle("Export")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .sheet(item: $shareItem) { item in
                ShareSheet(url: item.url)
            }
            .alert("Export Failed", isPresented: $showError) {
                Button("OK") {}
            } message: {
                Text(errorMessage)
            }
        }
    }

    // MARK: - CSV generation

    private func exportCSV() async {
        isExporting = true
        defer { isExporting = false }

        do {
            let url = try buildCSV(entries: filteredEntries)
            shareItem = ShareItem(url: url)
        } catch {
            errorMessage = error.localizedDescription
            showError    = true
        }
    }

    private func buildCSV(entries: [WorkEntry]) throws -> URL {
        var rows: [String] = [
            "Date,Title,Start,End,Hours,Rate (PLN/h),Earnings (PLN)"
        ]

        for entry in entries {
            let date     = DateFormatter.mediumDate.string(from: entry.date)
            let title    = entry.title.isEmpty ? "–" : entry.title.replacingOccurrences(of: ",", with: ";")
            let start    = DateFormatter.shortTime.string(from: entry.startTime)
            let end      = DateFormatter.shortTime.string(from: entry.endTime)
            let hours    = String(format: "%.2f", entry.totalHours)
            let rate     = String(format: "%.2f", entry.hourlyRate)
            let earnings = String(format: "%.2f", entry.earnings)

            rows.append("\(date),\(title),\(start),\(end),\(hours),\(rate),\(earnings)")
        }

        // Summary footer
        rows.append("")
        rows.append(",,,,\(String(format: "%.2f", totalHours)),,\(String(format: "%.2f", totalEarnings))")
        rows.append(",,,,Total Hours,,Total Earnings (PLN)")

        let csv      = rows.joined(separator: "\n")
        let fileName = "WorkTracker_\(exportFileName()).csv"
        let url      = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)

        try csv.write(to: url, atomically: true, encoding: .utf8)
        return url
    }

    // MARK: - Helpers

    private func dateInterval(for range: ExportRange) -> DateInterval? {
        let cal  = Calendar.current
        let now  = Date()

        switch range {
        case .thisMonth:
            return cal.dateInterval(of: .month, for: now)

        case .lastMonth:
            guard let lastMonth = cal.date(byAdding: .month, value: -1, to: now) else { return nil }
            return cal.dateInterval(of: .month, for: lastMonth)

        case .thisYear:
            return cal.dateInterval(of: .year, for: now)

        case .allTime:
            return nil   // nil = no filter, all entries pass through

        case .custom:
            let start = cal.startOfDay(for: customStart)
            let end   = cal.date(byAdding: .day, value: 1, to: cal.startOfDay(for: customEnd)) ?? customEnd
            return DateInterval(start: start, end: end)
        }
    }

    private func exportFileName() -> String {
        let f        = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f.string(from: Date())
    }
}

// MARK: - Share sheet wrapper

struct ShareItem: Identifiable {
    let id  = UUID()
    let url: URL
}

struct ShareSheet: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: [url], applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
