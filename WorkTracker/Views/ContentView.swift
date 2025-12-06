import SwiftUI
import FirebaseAuth

struct ContentView: View {
    @StateObject private var vm = WorkEntryViewModel()
    @EnvironmentObject var authVM: AuthViewModel

    @State private var selectedDate = Date()
    @State private var displayedMonth = Date()
    @State private var showingAllEntries = false

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                CalendarView(vm: vm, selectedDate: $selectedDate, displayedMonth: $displayedMonth)
                    .frame(maxHeight: 350)

                Divider()
                EntryListView(vm: vm, selectedDate: $selectedDate)
                Divider()

                VStack(alignment: .leading) {
                    let hours = vm.totalHours(inMonth: displayedMonth)
                    let earnings = vm.totalEarnings(inMonth: displayedMonth)
                    Text(String(format: "Month Total: %.2f hours", hours))
                    Text(String(format: "Earned: %.2f PLN", earnings))
                }
                .padding(.horizontal)
            }
            .navigationTitle("Work Tracker")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button {
                            showingAllEntries = true
                        } label: {
                            Label("All Entries", systemImage: "list.bullet")
                        }

                        Button(role: .destructive) {
                            authVM.signOut()
                        } label: {
                            Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.right")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
        }
        .sheet(isPresented: $showingAllEntries) {
            NavigationStack {
                AllEntriesView(vm: vm)
                    .navigationTitle("All Entries")
                    .toolbar {
                        ToolbarItem(placement: .navigationBarLeading) {
                            Button("Done") { showingAllEntries = false }
                        }
                    }
            }
        }
    }
}
