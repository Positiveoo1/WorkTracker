//
//  NotificationManager.swift
//  WorkTracker
//
//  Created by Abubakrsiddik Abdurakhimov on 24/05/2026.
//

import Foundation
import UserNotifications

@MainActor
final class NotificationManager: ObservableObject {
    static let shared = NotificationManager()

    @Published var isAuthorized   = false
    @Published var isDenied       = false

    // Keys for persisting reminder settings
    private let enabledKey  = "reminderEnabled"
    private let hourKey     = "reminderHour"
    private let minuteKey   = "reminderMinute"
    private let daysKey     = "reminderDays"

    // Published so RemindersView stays in sync
    @Published var reminderEnabled: Bool    = false
    @Published var reminderHour:    Int     = 17
    @Published var reminderMinute:  Int     = 0
    @Published var activeDays:      Set<Int> = [2, 3, 4, 5, 6]  // Mon–Fri (1=Sun)

    private init() {
        loadSettings()
        Task { await refreshAuthorizationStatus() }
    }

    // MARK: - Authorization

    func requestAuthorization() async {
        do {
            let granted = try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .sound, .badge])
            isAuthorized = granted
            isDenied     = !granted
            if granted && reminderEnabled {
                await scheduleReminders()
            }
        } catch {
            print("Notification auth error: \(error)")
        }
    }

    func refreshAuthorizationStatus() async {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        switch settings.authorizationStatus {
        case .authorized, .provisional:
            isAuthorized = true
            isDenied     = false
        case .denied:
            isAuthorized = false
            isDenied     = true
        default:
            isAuthorized = false
            isDenied     = false
        }
    }

    // MARK: - Schedule / cancel

    func scheduleReminders() async {
        UNUserNotificationCenter.current().removePendingNotificationRequests(
            withIdentifiers: existingIdentifiers()
        )

        guard reminderEnabled, isAuthorized else { return }

        let content        = UNMutableNotificationContent()
        content.title      = "Log Your Work Hours"
        content.body       = "Don't forget to record today's work in Work Tracker."
        content.sound      = .default

        for weekday in activeDays {
            var components        = DateComponents()
            components.weekday    = weekday
            components.hour       = reminderHour
            components.minute     = reminderMinute

            let trigger = UNCalendarNotificationTrigger(
                dateMatching: components,
                repeats: true
            )

            let request = UNNotificationRequest(
                identifier: "worktracker.reminder.\(weekday)",
                content:    content,
                trigger:    trigger
            )

            try? await UNUserNotificationCenter.current().add(request)
        }
    }

    func cancelReminders() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(
            withIdentifiers: existingIdentifiers()
        )
    }

    // MARK: - Persistence

    func saveSettings() {
        UserDefaults.standard.set(reminderEnabled,          forKey: enabledKey)
        UserDefaults.standard.set(reminderHour,             forKey: hourKey)
        UserDefaults.standard.set(reminderMinute,           forKey: minuteKey)
        UserDefaults.standard.set(Array(activeDays),        forKey: daysKey)
    }

    private func loadSettings() {
        // Only read saved values if they exist — keeps defaults on first launch
        if UserDefaults.standard.object(forKey: enabledKey) != nil {
            reminderEnabled = UserDefaults.standard.bool(forKey: enabledKey)
        }
        if UserDefaults.standard.object(forKey: hourKey) != nil {
            reminderHour    = UserDefaults.standard.integer(forKey: hourKey)
        }
        if UserDefaults.standard.object(forKey: minuteKey) != nil {
            reminderMinute  = UserDefaults.standard.integer(forKey: minuteKey)
        }
        if let days = UserDefaults.standard.array(forKey: daysKey) as? [Int] {
            activeDays      = Set(days)
        }
    }

    // MARK: - Helpers

    private func existingIdentifiers() -> [String] {
        (1...7).map { "worktracker.reminder.\($0)" }
    }

    var reminderTimeDate: Date {
        get {
            var c        = DateComponents()
            c.hour       = reminderHour
            c.minute     = reminderMinute
            return Calendar.current.date(from: c) ?? Date()
        }
        set {
            reminderHour   = Calendar.current.component(.hour,   from: newValue)
            reminderMinute = Calendar.current.component(.minute, from: newValue)
        }
    }
}
