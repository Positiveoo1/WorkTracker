import Foundation
import FirebaseAuth
import FirebaseFirestore

@MainActor
final class WorkEntryViewModel: ObservableObject {
    @Published private(set) var entries: [WorkEntry] = []
    private let db = Firestore.firestore()
    private var listener: ListenerRegistration?

    private var userId: String? {
        Auth.auth().currentUser?.uid
    }

    init() {
        setupListener()
    }

    private func setupListener() {
        guard let uid = userId else { return }

        listener = db.collection("users")
            .document(uid)
            .collection("entries")
            .order(by: "date", descending: true)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }
                if let error = error {
                    print("Firestore error: \(error)")
                    return
                }

                self.entries = snapshot?.documents.compactMap { doc in
                    WorkEntry(from: doc.data())
                } ?? []
            }
    }

    // MARK: - CRUD (all properly awaited)
    func addEntry(_ entry: WorkEntry) async throws {
        guard let uid = userId else {
            throw NSError(domain: "AuthError", code: 0, userInfo: [NSLocalizedDescriptionKey: "User not signed in"])
        }

        var newEntry = entry
        newEntry = WorkEntry(
            userId: uid,
            date: entry.date,
            startTime: entry.startTime,
            endTime: entry.endTime,
            hourlyRate: entry.hourlyRate,
            title: entry.title
        )

        try await db.collection("users")
            .document(uid)
            .collection("entries")
            .document(newEntry.id)
            .setData(newEntry.toDict())
    }

    func updateEntry(_ entry: WorkEntry) async throws {
        guard let uid = userId else {
            throw NSError(domain: "AuthError", code: 0, userInfo: [NSLocalizedDescriptionKey: "User not signed in"])
        }

        try await db.collection("users")
            .document(uid)
            .collection("entries")
            .document(entry.id)
            .setData(entry.toDict())
    }

    func deleteEntry(_ entry: WorkEntry) async {
        guard let uid = userId else { return }

        try? await db.collection("users")
            .document(uid)
            .collection("entries")
            .document(entry.id)
            .delete()
    }

    // MARK: - Helpers
    func entries(on date: Date) -> [WorkEntry] {
        let day = Calendar.current.startOfDay(for: date)
        return entries.filter { Calendar.current.isDate($0.date, inSameDayAs: day) }
            .sorted { $0.startTime < $1.startTime }
    }

    func entries(inMonth month: Date) -> [WorkEntry] {
        guard let interval = Calendar.current.dateInterval(of: .month, for: month) else { return [] }
        return entries.filter { interval.contains($0.date) }
    }

    func totalHours(inMonth month: Date) -> Double {
        entries(inMonth: month).reduce(0) { $0 + $1.totalHours }
    }

    func totalEarnings(inMonth month: Date) -> Double {
        entries(inMonth: month).reduce(0) { $0 + $1.earnings }
    }

    func hasEntries(on date: Date) -> Bool {
        !entries(on: date).isEmpty
    }

    deinit {
        listener?.remove()
    }
}
