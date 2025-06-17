import Foundation

struct WorkEntry: Identifiable, Codable {
    let id: UUID
    var date: Date      // normalized to midnight for grouping
    var startTime: Date // full Date including time
    var endTime: Date
    var hourlyRate: Double // in PLN

    init(id: UUID = UUID(), date: Date, startTime: Date, endTime: Date, hourlyRate: Double) {
        self.id = id
        self.date = Calendar.current.startOfDay(for: date)
        self.startTime = startTime
        self.endTime = endTime
        self.hourlyRate = hourlyRate
    }

    var totalDuration: TimeInterval {
        max(0, endTime.timeIntervalSince(startTime))
    }
    var totalHours: Double {
        totalDuration / 3600
    }
    var earnings: Double {
        totalHours * hourlyRate
    }
}
