
//
// EntryDetailView.swift
// WorkTracker
//

import SwiftUI

struct EntryDetailView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var vm: WorkEntryViewModel
    let date: Date
    let entry: WorkEntry?
    @ObservedObject var clientVM: ClientViewModel
    
    @State private var selectedClientId: String? = nil
    
    @AppStorage("lastStartHour")       private var lastStartHour       = 9
    @AppStorage("lastStartMinute")     private var lastStartMinute     = 0
    @AppStorage("lastEndHour")         private var lastEndHour         = 17
    @AppStorage("lastEndMinute")       private var lastEndMinute       = 0
    @AppStorage("lastHourlyRateText")  private var lastHourlyRateText  = ""
    
    @State private var startTime: Date
    @State private var endTime: Date
    @State private var hourlyRateText: String
    @State private var title: String
    @State private var showInvalidAlert = false
    @State private var showOverlapAlert = false
    @State private var overlapMessage = ""
    @State private var isSaving = false
    @State private var breakMinutes: Int
    
    // MARK: - Init
    init(vm: WorkEntryViewModel, clientVM: ClientViewModel, date: Date, entry: WorkEntry? = nil) {
        self.vm = vm
        self.clientVM = clientVM
        self.date = date
        self.entry = entry
        
        let cal = Calendar.current
        let dayStart = cal.startOfDay(for: date)
        
        if let entry {
            _startTime      = State(initialValue: entry.startTime)
            _endTime        = State(initialValue: entry.endTime)
            _hourlyRateText = State(initialValue: String(entry.hourlyRate))
            _title          = State(initialValue: entry.title)
            _selectedClientId = State(initialValue: entry.clientId)
            _breakMinutes   = State(initialValue: entry.breakMinutes)
        } else {
            // New entry - use saved defaults
            let savedStartHour   = UserDefaults.standard.integer(forKey: "lastStartHour")
            let savedStartMinute = UserDefaults.standard.integer(forKey: "lastStartMinute")
            let savedEndHour     = UserDefaults.standard.integer(forKey: "lastEndHour")
            let savedEndMinute   = UserDefaults.standard.integer(forKey: "lastEndMinute")
            
            let defaultStart = cal.date(bySettingHour: savedStartHour,
                                        minute: savedStartMinute,
                                        second: 0, of: dayStart)
                            ?? cal.date(byAdding: .hour, value: 9, to: dayStart)!
            
            let defaultEnd   = cal.date(bySettingHour: savedEndHour,
                                        minute: savedEndMinute,
                                        second: 0, of: dayStart)
                            ?? cal.date(byAdding: .hour, value: 17, to: dayStart)!
            
            _startTime      = State(initialValue: defaultStart)
            _endTime        = State(initialValue: defaultEnd)
            _hourlyRateText = State(initialValue: UserDefaults.standard.string(forKey: "lastHourlyRateText") ?? "")
            _title          = State(initialValue: "")
            _selectedClientId = State(initialValue: nil)
            _breakMinutes   = State(initialValue: 0)
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
                    DatePicker("End",   selection: $endTime,   displayedComponents: .hourAndMinute)
                }
                
                Section("Rate (PLN/h)") {
                    TextField("Hourly rate", text: $hourlyRateText)
                        .keyboardType(.decimalPad)
                }
                
                Section("Client (optional)") {
                    Picker("Client", selection: $selectedClientId) {
                        Text("None").tag(String?.none)
                        ForEach(clientVM.clients) { client in
                            HStack {
                                Circle()
                                    .fill(Color(hex: client.colorHex))
                                    .frame(width: 10, height: 10)
                                Text(client.name)
                            }
                            .tag(String?.some(client.id))
                        }
                    }
                }
                
                Section("Break") {
                    Stepper(breakLabel, value: $breakMinutes, in: 0...240, step: 5)
                    
                    if breakMinutes > 0 {
                        HStack {
                            Image(systemName: "info.circle")
                                .foregroundColor(.secondary)
                                .font(.footnote)
                            Text("Net hours will be reduced by \(breakMinutes) min")
                                .font(.footnote)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                // Auto-fill rate when client changes
                .onChange(of: selectedClientId) { newId in
                    if let client = clientVM.client(for: newId) {
                        hourlyRateText = String(client.hourlyRate)
                    }
                }
                
                if let rate = Double(hourlyRateText), endTime > startTime {
                    Section("Summary") {
                        let grossHours = endTime.timeIntervalSince(startTime) / 3600
                        let netHours   = max(0, grossHours - Double(breakMinutes) / 60)
                        Text(String(format: "Gross: %.2f h", grossHours))
                            .foregroundColor(.secondary)
                        Text(String(format: "Net (after break): %.2f h", netHours))
                        Text(String(format: "Earned: %.2f PLN", netHours * rate))
                            .fontWeight(.semibold)
                    }
                }
            }
            .navigationTitle(entry == nil ? "New Entry" : "Edit Entry")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        Task { await saveEntry() }
                    }
                    .disabled(isSaving)
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", role: .cancel) { dismiss() }
                }
            }
            .alert("Invalid Input", isPresented: $showInvalidAlert) {
                Button("OK") {}
            } message: {
                Text("End time must be after start time and rate must be a valid number.")
            }
            .alert("Scheduling Conflict", isPresented: $showOverlapAlert) {
                Button("OK") {}
            } message: {
                Text(overlapMessage)
            }
        }
    }
    
    // MARK: - Save
    private func saveEntry() async {
        guard let rate = Double(hourlyRateText), endTime > startTime else {
            showInvalidAlert = true
            return
        }
        
        isSaving = true
        defer { isSaving = false }
        
        do {
            if let existing = entry {
                var updated = existing
                updated.startTime = startTime
                updated.endTime = endTime
                updated.hourlyRate = rate
                updated.title = title
                updated.clientId = selectedClientId
                updated.breakMinutes = breakMinutes
                try await vm.updateEntry(updated)
            } else {
                let newEntry = WorkEntry(
                    userId: "",
                    date: date,
                    startTime: startTime,
                    endTime: endTime,
                    hourlyRate: rate,
                    title: title,
                    clientId: selectedClientId,
                    breakMinutes: breakMinutes
                )
                try await vm.addEntry(newEntry)
            }
            
            // Save last used values
            let c = Calendar.current
            lastStartHour = c.component(.hour, from: startTime)
            lastStartMinute = c.component(.minute, from: startTime)
            lastEndHour = c.component(.hour, from: endTime)
            lastEndMinute = c.component(.minute, from: endTime)
            lastHourlyRateText = hourlyRateText
            
            dismiss()
            
        } catch let error as EntryValidationError {
            overlapMessage = error.localizedDescription
            showOverlapAlert = true
        } catch {
            overlapMessage = error.localizedDescription
            showOverlapAlert = true
        }
    }
    
    private var breakLabel: String {
        breakMinutes == 0 ? "No break" : "\(breakMinutes) min break"
    }
}
