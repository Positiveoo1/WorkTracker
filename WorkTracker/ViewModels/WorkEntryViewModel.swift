//
// WorkEntryViewModel.swift
// WorkTracker
//

import Foundation
import FirebaseAuth
import FirebaseFirestore

// MARK: - Validation Error (Top-level so it's visible to other files)
enum EntryValidationError: LocalizedError {
    case overlappingEntry(String)
    
    var errorDescription: String? {
        switch self {
        case .overlappingEntry(let title):
            return "This entry overlaps with \"\(title)\". Please adjust the start or end time."
        }
    }
}

@MainActor
final class WorkEntryViewModel: ObservableObject {
    @Published private(set) var entries: [WorkEntry] = []
    @Published private(set) var isLoading = false
    @Published private(set) var isOffline = false
    
    private let db = Firestore.firestore()
    private var listener: ListenerRegistration?
    private var authStateHandle: AuthStateDidChangeListenerHandle?
    
    init() {
        let settings = FirestoreSettings()
        settings.cacheSettings = PersistentCacheSettings()
        db.settings = settings
        
        authStateHandle = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            guard let self else { return }
            Task { @MainActor in
                if user != nil { self.setupListener() }
                else { self.tearDownListener() }
            }
        }
    }
    
    // MARK: - Listener lifecycle
    private func setupListener() {
        tearDownListener()
        guard let uid = Auth.auth().currentUser?.uid else { return }
        
        isLoading = true
        
        listener = db.collection("users")
            .document(uid)
            .collection("entries")
            .order(by: "date", descending: true)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self else { return }
                self.isLoading = false
                
                if let error {
                    let nsErr = error as NSError
                    self.isOffline = (nsErr.domain == FirestoreErrorDomain &&
                                    nsErr.code == FirestoreErrorCode.unavailable.rawValue)
                    print("Firestore error: \(error)")
                    return
                }
                
                self.isOffline = snapshot?.metadata.isFromCache ?? false
                self.entries = snapshot?.documents.compactMap {
                    WorkEntry(from: $0.data())
                } ?? []
            }
    }
    
    private func tearDownListener() {
        listener?.remove()
        listener = nil
        entries = []
        isLoading = false
        isOffline = false
    }
    
    // MARK: - Overlap Check
    func overlappingEntry(
        on date: Date,
        start: Date,
        end: Date,
        excludingId: String? = nil
    ) -> WorkEntry? {
        entries(on: date).first { existing in
            guard existing.id != excludingId else { return false }
            return start < existing.endTime && end > existing.startTime
        }
    }
    
    // MARK: - CRUD
    func addEntry(_ entry: WorkEntry) async throws {
        guard let uid = Auth.auth().currentUser?.uid else {
            throw NSError(domain: "AuthError", code: 0,
                          userInfo: [NSLocalizedDescriptionKey: "User not signed in"])
        }
        
        if let conflict = overlappingEntry(on: entry.date,
                                           start: entry.startTime,
                                           end: entry.endTime) {
            let name = conflict.title.isEmpty ? "Untitled entry" : conflict.title
            throw EntryValidationError.overlappingEntry(name)
        }
        
        let newEntry = WorkEntry(
            userId: uid,
            date: entry.date,
            startTime: entry.startTime,
            endTime: entry.endTime,
            hourlyRate: entry.hourlyRate,
            title: entry.title,
            clientId: entry.clientId,
            breakMinutes: entry.breakMinutes
        )
        
        try await db.collection("users")
            .document(uid)
            .collection("entries")
            .document(newEntry.id)
            .setData(newEntry.toDict())
    }
    
    func updateEntry(_ entry: WorkEntry) async throws {
        guard let uid = Auth.auth().currentUser?.uid else {
            throw NSError(domain: "AuthError", code: 0,
                          userInfo: [NSLocalizedDescriptionKey: "User not signed in"])
        }
        
        if let conflict = overlappingEntry(on: entry.date,
                                           start: entry.startTime,
                                           end: entry.endTime,
                                           excludingId: entry.id) {
            let name = conflict.title.isEmpty ? "Untitled entry" : conflict.title
            throw EntryValidationError.overlappingEntry(name)
        }
        
        try await db.collection("users")
            .document(uid)
            .collection("entries")
            .document(entry.id)
            .setData(entry.toDict())
    }
    
    func deleteEntry(_ entry: WorkEntry) async {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        
        try? await db.collection("users")
            .document(uid)
            .collection("entries")
            .document(entry.id)
            .delete()
    }
    
    // MARK: - Helpers
    func entries(on date: Date) -> [WorkEntry] {
        let day = Calendar.current.startOfDay(for: date)
        return entries
            .filter { Calendar.current.isDate($0.date, inSameDayAs: day) }
            .sorted { $0.startTime < $1.startTime }
    }
    
    func entries(inWeek date: Date) -> [WorkEntry] {
        let cal = Calendar.current
        guard let weekInterval = cal.dateInterval(of: .weekOfYear, for: date) else { return [] }
        return entries.filter { weekInterval.contains($0.date) }
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
        if let handle = authStateHandle {
            Auth.auth().removeStateDidChangeListener(handle)
        }
    }
}
