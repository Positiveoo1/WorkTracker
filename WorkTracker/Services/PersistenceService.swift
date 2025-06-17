import Foundation

class PersistenceService {
    static let shared = PersistenceService()
    private let entriesKey = "work_entries"

    // Load from UserDefaults; simple for minimal persistence
    func loadEntries() -> [WorkEntry] {
        guard let data = UserDefaults.standard.data(forKey: entriesKey) else { return [] }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        if let arr = try? decoder.decode([WorkEntry].self, from: data) {
            return arr
        }
        return []
    }

    func saveEntries(_ entries: [WorkEntry]) {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        if let data = try? encoder.encode(entries) {
            UserDefaults.standard.set(data, forKey: entriesKey)
        }
    }
}
