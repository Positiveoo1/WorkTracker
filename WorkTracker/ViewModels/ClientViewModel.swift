//
//  ClientViewModel.swift
//  WorkTracker
//
//  Created by Abubakrsiddik Abdurakhimov on 24/05/2026.
//

import Foundation
import FirebaseAuth
import FirebaseFirestore

@MainActor
final class ClientViewModel: ObservableObject {
    @Published private(set) var clients: [Client] = []

    private let db = Firestore.firestore()
    private var listener: ListenerRegistration?
    private var authStateHandle: AuthStateDidChangeListenerHandle?

    init() {
        authStateHandle = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            guard let self else { return }
            Task { @MainActor in
                if user != nil { self.setupListener() }
                else           { self.tearDown() }
            }
        }
    }

    private func setupListener() {
        tearDown()
        guard let uid = Auth.auth().currentUser?.uid else { return }

        listener = db.collection("users")
            .document(uid)
            .collection("clients")
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self else { return }
                if let error { print("Client listener error: \(error)"); return }
                self.clients = snapshot?.documents.compactMap { Client(from: $0.data()) } ?? []
            }
    }

    private func tearDown() {
        listener?.remove()
        listener = nil
        clients  = []
    }

    // MARK: - CRUD

    func addClient(_ client: Client) async throws {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        try await db.collection("users").document(uid)
            .collection("clients").document(client.id)
            .setData(client.toDict())
    }

    func updateClient(_ client: Client) async throws {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        try await db.collection("users").document(uid)
            .collection("clients").document(client.id)
            .setData(client.toDict())
    }

    func deleteClient(_ client: Client) async {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        try? await db.collection("users").document(uid)
            .collection("clients").document(client.id)
            .delete()
    }

    // MARK: - Helpers

    func client(for id: String?) -> Client? {
        guard let id else { return nil }
        return clients.first { $0.id == id }
    }

    deinit {
        listener?.remove()
        if let handle = authStateHandle {
            Auth.auth().removeStateDidChangeListener(handle)
        }
    }
}
