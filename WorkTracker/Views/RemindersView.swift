//
//  RemindersView.swift
//  WorkTracker
//
//  Created by Abubakrsiddik Abdurakhimov on 24/05/2026.
//

import SwiftUI

struct RemindersView: View {
    @ObservedObject private var nm = NotificationManager.shared
    @Environment(\.dismiss) var dismiss
    @State private var reminderTime: Date = NotificationManager.shared.reminderTimeDate

    // Weekday labels — index matches UNCalendarNotificationTrigger weekday (1=Sun)
    private let weekdays: [(Int, String)] = [
        (2, "Mon"), (3, "Tue"), (4, "Wed"),
        (5, "Thu"), (6, "Fri"), (7, "Sat"), (1, "Sun")
    ]

    var body: some View {
        NavigationView {
            Form {
                // Permission banner
                if nm.isDenied {
                    Section {
                        HStack(spacing: 12) {
                            Image(systemName: "bell.slash.fill")
                                .foregroundColor(.orange)
                                .font(.title2)
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Notifications Blocked")
                                    .font(.headline)
                                Text("Enable notifications in Settings to use reminders.")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        Button("Open Settings") {
                            if let url = URL(string: UIApplication.openSettingsURLString) {
                                UIApplication.shared.open(url)
                            }
                        }
                    }
                }

                // Main toggle
                Section {
                    Toggle("Daily Reminder", isOn: $nm.reminderEnabled)
                        .onChange(of: nm.reminderEnabled) { enabled in
                            Task {
                                if enabled {
                                    if !nm.isAuthorized {
                                        await nm.requestAuthorization()
                                    } else {
                                        await nm.scheduleReminders()
                                    }
                                } else {
                                    nm.cancelReminders()
                                }
                                nm.saveSettings()
                            }
                        }
                } footer: {
                    Text("You'll get a notification on selected days to log your hours.")
                }

                // Time and day pickers — only shown when enabled
                if nm.reminderEnabled {
                    Section("Reminder Time") {
                        DatePicker(
                            "Time",
                            selection: $reminderTime,
                            displayedComponents: .hourAndMinute
                        )
                        .datePickerStyle(.wheel)
                        .labelsHidden()
                        .onChange(of: reminderTime) { newTime in
                            nm.reminderTimeDate = newTime
                            Task {
                                await nm.scheduleReminders()
                                nm.saveSettings()
                            }
                        }
                    }

                    Section("Repeat On") {
                        LazyVGrid(
                            columns: Array(repeating: GridItem(.flexible()), count: 7),
                            spacing: 8
                        ) {
                            ForEach(weekdays, id: \.0) { (num, label) in
                                let isOn = nm.activeDays.contains(num)
                                Text(label)
                                    .font(.caption)
                                    .fontWeight(isOn ? .bold : .regular)
                                    .frame(maxWidth: .infinity, minHeight: 36)
                                    .background(
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(isOn ? Color.accentColor : Color(.secondarySystemBackground))
                                    )
                                    .foregroundColor(isOn ? .white : .primary)
                                    .onTapGesture {
                                        if isOn {
                                            // Prevent deselecting all days
                                            if nm.activeDays.count > 1 {
                                                nm.activeDays.remove(num)
                                            }
                                        } else {
                                            nm.activeDays.insert(num)
                                        }
                                        Task {
                                            await nm.scheduleReminders()
                                            nm.saveSettings()
                                        }
                                    }
                            }
                        }
                        .padding(.vertical, 4)
                    }

                    Section("Next Scheduled") {
                        if nm.activeDays.isEmpty {
                            Text("No days selected")
                                .foregroundColor(.secondary)
                        } else {
                            ForEach(weekdays.filter { nm.activeDays.contains($0.0) }, id: \.0) { (_, label) in
                                HStack {
                                    Image(systemName: "bell.fill")
                                        .foregroundColor(.accentColor)
                                        .font(.footnote)
                                    Text("\(label) at \(formattedTime)")
                                        .font(.subheadline)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Reminders")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .task {
                await nm.refreshAuthorizationStatus()
            }
        }
    }

    private var formattedTime: String {
        DateFormatter.shortTime.string(from: reminderTime)
    }
}
