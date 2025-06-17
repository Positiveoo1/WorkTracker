import Foundation
import Combine

class WorkEntryViewModel: ObservableObject {
    @Published private(set) var entries: [WorkEntry] = []
    private let persistence = PersistenceService.shared
    private let calendar = Calendar.current

    init() {
        entries = persistence.loadEntries()
    }

    func addEntry(_ entry: WorkEntry) {
        entries.append(entry)
        save()
    }

    func entries(on date: Date) -> [WorkEntry] {
        let day = calendar.startOfDay(for: date)
        return entries.filter { calendar.isDate($0.date, inSameDayAs: day) }
    }

    func entries(inMonth month: Date) -> [WorkEntry] {
        guard let interval = calendar.dateInterval(of: .month, for: month) else { return [] }
        return entries.filter { entry in
            entry.date >= interval.start && entry.date <= interval.end
        }
    }

    func totalHoursAll() -> Double {
        entries.map { $0.totalHours }.reduce(0, +)
    }
    func totalEarningsAll() -> Double {
        entries.map { $0.earnings }.reduce(0, +)
    }

    func totalHours(inMonth month: Date) -> Double {
        entries(inMonth: month).map { $0.totalHours }.reduce(0, +)
    }
    func totalEarnings(inMonth month: Date) -> Double {
        entries(inMonth: month).map { $0.earnings }.reduce(0, +)
    }

    private func save() {
        persistence.saveEntries(entries)
    }
}
