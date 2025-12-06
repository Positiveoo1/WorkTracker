import Foundation
import FirebaseFirestore 

struct WorkEntry: Identifiable, Codable {
    var id: String = UUID().uuidString
    let userId: String
    let date: Date
    var startTime: Date
    var endTime: Date
    var hourlyRate: Double
    var title: String = ""

    var totalHours: Double {
        max(0, endTime.timeIntervalSince(startTime)) / 3600
    }

    var earnings: Double {
        totalHours * hourlyRate
    }

    // Convert to Firestore dictionary
    func toDict() -> [String: Any] {
        [
            "id": id,
            "userId": userId,
            "date": Timestamp(date: date),
            "startTime": Timestamp(date: startTime),
            "endTime": Timestamp(date: endTime),
            "hourlyRate": hourlyRate,
            "title": title
        ]
    }

    // Initialize from Firestore document data
    init?(from dict: [String: Any]) {
        guard
            let id = dict["id"] as? String,
            let userId = dict["userId"] as? String,
            let dateTs = dict["date"] as? Timestamp,
            let startTs = dict["startTime"] as? Timestamp,
            let endTs = dict["endTime"] as? Timestamp,
            let rate = dict["hourlyRate"] as? Double
        else { return nil }

        self.id = id
        self.userId = userId
        self.date = dateTs.dateValue()
        self.startTime = startTs.dateValue()
        self.endTime = endTs.dateValue()
        self.hourlyRate = rate
        self.title = dict["title"] as? String ?? ""
    }

    // Convenience init for creating new entries
    init(userId: String, date: Date, startTime: Date, endTime: Date, hourlyRate: Double, title: String = "") {
        self.id = UUID().uuidString
        self.userId = userId
        self.date = Calendar.current.startOfDay(for: date)
        self.startTime = startTime
        self.endTime = endTime
        self.hourlyRate = hourlyRate
        self.title = title
    }
}
