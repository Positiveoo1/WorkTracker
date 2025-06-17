import SwiftUI

struct EntryDetailView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var vm: WorkEntryViewModel
    let date: Date

    @AppStorage("lastStartHour") private var lastStartHour: Int = 9
    @AppStorage("lastStartMinute") private var lastStartMinute: Int = 0
    @AppStorage("lastEndHour") private var lastEndHour: Int = 17
    @AppStorage("lastEndMinute") private var lastEndMinute: Int = 0
    @AppStorage("lastHourlyRateText") private var lastHourlyRateText: String = ""

    @State private var startTime: Date
    @State private var endTime: Date
    @State private var hourlyRateText: String
    @State private var showAlert = false

    init(vm: WorkEntryViewModel, date: Date) {
        self.vm = vm
        self.date = date
        let cal = Calendar.current
        let dayStart = cal.startOfDay(for: date)

        // Build startTime from AppStorage values
        var comps = DateComponents()
        comps.year = cal.component(.year, from: date)
        comps.month = cal.component(.month, from: date)
        comps.day = cal.component(.day, from: date)
        comps.hour = UserDefaults.standard.integer(forKey: "lastStartHour")
        comps.minute = UserDefaults.standard.integer(forKey: "lastStartMinute")
        let defaultStart = cal.date(from: comps) ?? cal.date(bySettingHour: 9, minute: 0, second: 0, of: dayStart)!

        // Build endTime from AppStorage values
        comps.hour = UserDefaults.standard.integer(forKey: "lastEndHour")
        comps.minute = UserDefaults.standard.integer(forKey: "lastEndMinute")
        let defaultEnd = cal.date(from: comps) ?? cal.date(bySettingHour: 17, minute: 0, second: 0, of: dayStart)!

        _startTime = State(initialValue: defaultStart)
        _endTime = State(initialValue: defaultEnd)
        let rateText = UserDefaults.standard.string(forKey: "lastHourlyRateText") ?? ""
        _hourlyRateText = State(initialValue: rateText)
    }

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Time")) {
                    DatePicker("Start", selection: $startTime, displayedComponents: .hourAndMinute)
                    DatePicker("End", selection: $endTime, displayedComponents: .hourAndMinute)
                }
                Section(header: Text("Rate (PLN)")) {
                    TextField("Hourly Rate", text: $hourlyRateText)
                        .keyboardType(.decimalPad)
                }
                Section(header: Text("Summary")) {
                    if let rate = Double(hourlyRateText), endTime > startTime {
                        let dur = endTime.timeIntervalSince(startTime)
                        let hours = dur / 3600
                        Text(String(format: "Hours: %.2f", hours))
                        Text(String(format: "Earned: %.2f PLN", hours * rate))
                    } else {
                        Text("Enter valid times and rate")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("New Entry")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        guard let rate = Double(hourlyRateText), endTime > startTime else {
                            showAlert = true
                            return
                        }
                        let entry = WorkEntry(date: date, startTime: startTime, endTime: endTime, hourlyRate: rate)
                        vm.addEntry(entry)

                        // Update AppStorage for next time
                        let cal = Calendar.current
                        let startComps = cal.dateComponents([.hour, .minute], from: startTime)
                        lastStartHour = startComps.hour ?? lastStartHour
                        lastStartMinute = startComps.minute ?? lastStartMinute
                        let endComps = cal.dateComponents([.hour, .minute], from: endTime)
                        lastEndHour = endComps.hour ?? lastEndHour
                        lastEndMinute = endComps.minute ?? lastEndMinute
                        lastHourlyRateText = hourlyRateText

                        dismiss()
                    }
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .alert(isPresented: $showAlert) {
                Alert(title: Text("Invalid Input"),
                      message: Text("Ensure end time is after start time and hourly rate is valid."),
                      dismissButton: .default(Text("OK")))
            }
        }
    }
}

