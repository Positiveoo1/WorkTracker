import Foundation
import FirebaseFirestore

struct WorkEntry: Identifiable, Codable {
    var id:             String = UUID().uuidString
    let userId:         String
    let date:           Date
    var startTime:      Date
    var endTime:        Date
    var hourlyRate:     Double
    var title:          String  = ""
    var clientId:       String?
    var breakMinutes:   Int     = 0       // ← new

    // Net hours after subtracting break
    var totalHours: Double {
        let raw = max(0, endTime.timeIntervalSince(startTime)) / 3600
        let breakHours = Double(breakMinutes) / 60
        return max(0, raw - breakHours)
    }

    // Gross duration (no break subtracted) — useful for display
    var grossHours: Double {
        max(0, endTime.timeIntervalSince(startTime)) / 3600
    }

    var earnings: Double {
        totalHours * hourlyRate
    }

    func toDict() -> [String: Any] {
        var d: [String: Any] = [
            "id":           id,
            "userId":       userId,
            "date":         Timestamp(date: date),
            "startTime":    Timestamp(date: startTime),
            "endTime":      Timestamp(date: endTime),
            "hourlyRate":   hourlyRate,
            "title":        title,
            "breakMinutes": breakMinutes        // ← new
        ]
        if let clientId { d["clientId"] = clientId }
        return d
    }

    init?(from dict: [String: Any]) {
        guard
            let id      = dict["id"]         as? String,
            let userId  = dict["userId"]      as? String,
            let dateTs  = dict["date"]        as? Timestamp,
            let startTs = dict["startTime"]   as? Timestamp,
            let endTs   = dict["endTime"]     as? Timestamp,
            let rate    = dict["hourlyRate"]  as? Double
        else { return nil }

        self.id           = id
        self.userId       = userId
        self.date         = dateTs.dateValue()
        self.startTime    = startTs.dateValue()
        self.endTime      = endTs.dateValue()
        self.hourlyRate   = rate
        self.title        = dict["title"]        as? String ?? ""
        self.clientId     = dict["clientId"]     as? String
        self.breakMinutes = dict["breakMinutes"] as? Int ?? 0   // ← new, defaults to 0
    }

    init(userId: String, date: Date, startTime: Date, endTime: Date,
         hourlyRate: Double, title: String = "",
         clientId: String? = nil, breakMinutes: Int = 0) {
        self.id           = UUID().uuidString
        self.userId       = userId
        self.date         = Calendar.current.startOfDay(for: date)
        self.startTime    = startTime
        self.endTime      = endTime
        self.hourlyRate   = hourlyRate
        self.title        = title
        self.clientId     = clientId
        self.breakMinutes = breakMinutes         // ← new
    }
}
