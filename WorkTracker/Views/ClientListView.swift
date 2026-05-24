//
//  ClientListView.swift
//  WorkTracker
//
//  Created by Abubakrsiddik Abdurakhimov on 24/05/2026.
//

import SwiftUI

struct ClientListView: View {
    @ObservedObject var clientVM: ClientViewModel
    @State private var showingAdd = false
    @State private var editTarget: Client? = nil

    var body: some View {
        NavigationView {
            Group {
                if clientVM.clients.isEmpty {
                    emptyState
                } else {
                    List {
                        ForEach(clientVM.clients) { client in
                            ClientRow(client: client)
                                .contentShape(Rectangle())
                                .onTapGesture { editTarget = client }
                                .swipeActions {
                                    Button(role: .destructive) {
                                        Task { await clientVM.deleteClient(client) }
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Clients")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingAdd = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAdd) {
                ClientEditView(clientVM: clientVM, client: nil)
            }
            .sheet(item: $editTarget) { client in
                ClientEditView(clientVM: clientVM, client: client)
            }
        }
        .tabItem {
            Label("Clients", systemImage: "person.2.fill")
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "person.2")
                .font(.system(size: 56))
                .foregroundColor(.secondary)
            Text("No Clients Yet")
                .font(.headline)
            Text("Add a client to assign hourly rates\nand track earnings per project.")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .font(.subheadline)
            Button("Add Client") { showingAdd = true }
                .buttonStyle(.borderedProminent)
        }
        .padding()
    }
}

// MARK: - Row

struct ClientRow: View {
    let client: Client

    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(Color(hex: client.colorHex))
                .frame(width: 12, height: 12)

            VStack(alignment: .leading, spacing: 2) {
                Text(client.name)
                    .font(.headline)
                Text(String(format: "%.2f PLN/h", client.hourlyRate))
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Edit / Add sheet

struct ClientEditView: View {
    @ObservedObject var clientVM: ClientViewModel
    let client: Client?
    @Environment(\.dismiss) var dismiss

    @State private var name         = ""
    @State private var rateText     = ""
    @State private var colorHex     = "#6B7FF0"
    @State private var isSaving     = false
    @State private var showError    = false

    // Preset palette
    private let palette = [
        "#6B7FF0", "#F06B6B", "#6BF0A0", "#F0C46B",
        "#C46BF0", "#6BC4F0", "#F06BC4", "#A0F06B"
    ]

    init(clientVM: ClientViewModel, client: Client?) {
        self.clientVM = clientVM
        self.client   = client
        if let c = client {
            _name     = State(initialValue: c.name)
            _rateText = State(initialValue: String(c.hourlyRate))
            _colorHex = State(initialValue: c.colorHex)
        }
    }

    var body: some View {
        NavigationView {
            Form {
                Section("Client Name") {
                    TextField("e.g. Acme Corp", text: $name)
                }

                Section("Hourly Rate (PLN/h)") {
                    TextField("e.g. 85", text: $rateText)
                        .keyboardType(.decimalPad)
                }

                Section("Color") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 8), spacing: 12) {
                        ForEach(palette, id: \.self) { hex in
                            Circle()
                                .fill(Color(hex: hex))
                                .frame(width: 32, height: 32)
                                .overlay(
                                    Circle()
                                        .stroke(Color.primary, lineWidth: colorHex == hex ? 2 : 0)
                                        .padding(2)
                                )
                                .onTapGesture { colorHex = hex }
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
            .navigationTitle(client == nil ? "New Client" : "Edit Client")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { Task { await save() } }
                        .disabled(isSaving || name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .alert("Invalid Rate", isPresented: $showError) {
                Button("OK") {}
            } message: {
                Text("Please enter a valid hourly rate.")
            }
        }
    }

    private func save() async {
        guard let rate = Double(rateText), rate > 0 else { showError = true; return }
        isSaving = true
        defer { isSaving = false }

        if let existing = client {
            var updated          = existing
            updated.name         = name.trimmingCharacters(in: .whitespaces)
            updated.hourlyRate   = rate
            updated.colorHex     = colorHex
            try? await clientVM.updateClient(updated)
        } else {
            let newClient = Client(
                name:        name.trimmingCharacters(in: .whitespaces),
                hourlyRate:  rate,
                colorHex:    colorHex
            )
            try? await clientVM.addClient(newClient)
        }
        dismiss()
    }
}
