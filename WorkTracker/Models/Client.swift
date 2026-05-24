//
//  Client.swift
//  WorkTracker
//
//  Created by Abubakrsiddik Abdurakhimov on 24/05/2026.
//

import Foundation
import FirebaseFirestore

struct Client: Identifiable, Codable, Hashable {
    var id:          String = UUID().uuidString
    var name:        String
    var hourlyRate:  Double
    var colorHex:    String

    func toDict() -> [String: Any] {
        ["id": id, "name": name, "hourlyRate": hourlyRate, "colorHex": colorHex]
    }

    init?(from dict: [String: Any]) {
        guard
            let id   = dict["id"]          as? String,
            let name = dict["name"]        as? String,
            let rate = dict["hourlyRate"]  as? Double,
            let hex  = dict["colorHex"]    as? String
        else { return nil }

        self.id          = id
        self.name        = name
        self.hourlyRate  = rate
        self.colorHex    = hex
    }

    init(name: String, hourlyRate: Double, colorHex: String = "#6B7FF0") {
        self.id          = UUID().uuidString
        self.name        = name
        self.hourlyRate  = hourlyRate
        self.colorHex    = colorHex
    }
}

// MARK: - Color helper
import SwiftUI

extension Color {
    init(hex: String) {
        let hex     = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int:     UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r = Double((int >> 16) & 0xFF) / 255
        let g = Double((int >> 8)  & 0xFF) / 255
        let b = Double( int        & 0xFF) / 255
        self.init(red: r, green: g, blue: b)
    }
}
