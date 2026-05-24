//
//  DateFormatters.swift
//  WorkTracker
//
//  Created by Abubakrsiddik Abdurakhimov on 24/05/2026.
//

import Foundation

extension DateFormatter {
    /// "January 2025"
    static let monthYear: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "LLLL yyyy"
        return f
    }()

    /// "Jan 6, 2025"
    static let mediumDate: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .medium
        return f
    }()

    /// "January 6, 2025"
    static let longDate: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .long
        return f
    }()

    /// "9:00 AM"
    static let shortTime: DateFormatter = {
        let f = DateFormatter()
        f.timeStyle = .short
        return f
    }()
}
