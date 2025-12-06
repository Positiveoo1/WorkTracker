import SwiftUI

struct EntryDetailView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var vm: WorkEntryViewModel
    let date: Date
    let entry: WorkEntry?

    @AppStorage("lastStartHour") private var lastStartHour = 9
    @AppStorage("lastStartMinute") private var lastStartMinute = 0
    @AppStorage("lastEndHour") private var lastEndHour = 17
    @AppStorage("lastEndMinute") private var lastEndMinute = 0
    @AppStorage("lastHourlyRateText") private var lastHourlyRateText = ""

    @State private var startTime: Date
    @State private var endTime: Date
    @State private var hourlyRateText: String
    @State private var title = ""
    @State private var showAlert = false

    init(vm: WorkEntryViewModel, date: Date, entry: WorkEntry? = nil) {
        self.vm = vm
        self.date = date
        self.entry = entry

        let cal = Calendar.current
        let dayStart = cal.startOfDay(for: date)

        if let entry = entry {
            _startTime = State(initialValue: entry.startTime)
            _endTime = State(initialValue: entry.endTime)
            _hourlyRateText = State(initialValue: String(entry.hourlyRate))
            _title = State(initialValue: entry.title)
        } else {
            let defaultStart = cal.date(bySettingHour: UserDefaults.standard.integer(forKey: "lastStartHour"),
                                        minute: UserDefaults.standard.integer(forKey: "lastStartMinute"),
                                        second: 0, of: dayStart) ?? cal.date(byAdding: .hour, value: 9, to: dayStart)!

            let defaultEnd = cal.date(bySettingHour: UserDefaults.standard.integer(forKey: "lastEndHour"),
                                      minute: UserDefaults.standard.integer(forKey: "lastEndMinute"),
                                      second: 0, of: dayStart) ?? cal.date(byAdding: .hour, value: 17, to: dayStart)!

            _startTime = State(initialValue: defaultStart)
            _endTime = State(initialValue: defaultEnd)
            _hourlyRateText = State(initialValue: UserDefaults.standard.string(forKey: "lastHourlyRateText") ?? "")
        }
    }

    var body: some View {
        NavigationView {
            Form {
                Section("Title") {
                    TextField("Work title (optional)", text: $title)
                }

                Section("Time") {
                    DatePicker("Start", selection: $startTime, displayedComponents: .hourAndMinute)
                    DatePicker("End", selection: $endTime, displayedComponents: .hourAndMinute)
                }

                Section("Rate (PLN/h)") {
                    TextField("Hourly rate", text: $hourlyRateText)
                        .keyboardType(.decimalPad)
                }

                if let rate = Double(hourlyRateText), endTime > startTime {
                    Section("Summary") {
                        let hours = endTime.timeIntervalSince(startTime) / 3600
                        Text(String(format: "Hours: %.2f", hours))
                        Text(String(format: "Earned: %.2f PLN", hours * rate))
                    }
                }
            }
            .navigationTitle(entry == nil ? "New Entry" : "Edit Entry")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        Task { await saveEntry() }
                    }
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", role: .cancel) { dismiss() }
                }
            }
            .alert("Invalid input", isPresented: $showAlert) {
                Button("OK") {}
            } message: {
                Text("End time must be after start time and rate must be a valid number.")
            }
        }
    }

    private func saveEntry() async {
        guard let rate = Double(hourlyRateText), endTime > startTime else {
            showAlert = true
            return
        }

        do {
            if let existing = entry {
                // Update existing entry
                var updated = existing
                updated.startTime = startTime
                updated.endTime = endTime
                updated.hourlyRate = rate
                updated.title = title
                try await vm.updateEntry(updated)  // Now properly awaited
            } else {
                // Create new entry
                let newEntry = WorkEntry(
                    userId: "temp", // will be replaced in ViewModel
                    date: date,
                    startTime: startTime,
                    endTime: endTime,
                    hourlyRate: rate,
                    title: title
                )
                try await vm.addEntry(newEntry)  // Now properly awaited
            }

            // Save last used values
            let c = Calendar.current
            lastStartHour = c.component(.hour, from: startTime)
            lastStartMinute = c.component(.minute, from: startTime)
            lastEndHour = c.component(.hour, from: endTime)
            lastEndMinute = c.component(.minute, from: endTime)
            lastHourlyRateText = hourlyRateText

            dismiss()
        } catch {
            print("Save error: \(error)")
            showAlert = true
        }
    }
}
