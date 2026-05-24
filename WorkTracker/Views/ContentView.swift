import SwiftUI
import FirebaseAuth

struct ContentView: View {
    @StateObject private var vm = WorkEntryViewModel()
    @EnvironmentObject var authVM:   AuthViewModel
    @EnvironmentObject var clientVM: ClientViewModel

    @State private var selectedDate      = Date()
    @State private var displayedMonth    = Date()
    @State private var showingAllEntries = false
    @State private var showingExport     = false
    @State private var showingReminders  = false
    @State private var calendarExpanded  = true      // ← new

    var body: some View {
        TabView {

            // ── Tab 1: Home ──
            NavigationView {
                GeometryReader { geo in                 // ← new
                    ZStack(alignment: .top) {
                        VStack(spacing: 0) {

                            // Offline banner
                            if vm.isOffline {
                                OfflineBanner()
                                    .animation(.easeInOut, value: vm.isOffline)
                            }

                            // Calendar — height is proportional to screen, not fixed
                            CalendarView(
                                vm:             vm,
                                selectedDate:   $selectedDate,
                                displayedMonth: $displayedMonth,
                                isCompact:      !calendarExpanded    // ← new
                            )
                            .frame(height: calendarHeight(for: geo.size))
                            .animation(.easeInOut(duration: 0.3), value: calendarExpanded)

                            // Collapse / expand handle
                            collapseHandle

                            Divider()

                            EntryListView(
                                vm:           vm,
                                clientVM:     clientVM,
                                selectedDate: $selectedDate
                            )

                            Divider()

                            monthSummary
                        }

                        if vm.isLoading {
                            loadingOverlay
                        }
                    }
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
                            Button {
                                showingExport = true
                            } label: {
                                Label("Export CSV", systemImage: "square.and.arrow.up")
                            }
                            Button {
                                showingReminders = true
                            } label: {
                                Label("Reminders", systemImage: "bell")
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
            .tabItem { Label("Home", systemImage: "calendar") }

            // ── Tab 2: Stats ──
            StatsView(vm: vm)
                .tabItem { Label("Stats", systemImage: "chart.bar.fill") }

            // ── Tab 3: Clients ──
            ClientListView(clientVM: clientVM)
                .tabItem { Label("Clients", systemImage: "person.2.fill") }
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
        .sheet(isPresented: $showingExport) {
            ExportView(vm: vm)
        }
        .sheet(isPresented: $showingReminders) {
            RemindersView()
        }
    }

    // MARK: - Subviews

    private var collapseHandle: some View {
        Button {
            withAnimation(.easeInOut(duration: 0.3)) {
                calendarExpanded.toggle()
            }
        } label: {
            HStack(spacing: 4) {
                Image(systemName: calendarExpanded ? "chevron.up" : "chevron.down")
                    .font(.caption)
                Text(calendarExpanded ? "Collapse" : "Expand Calendar")
                    .font(.caption)
            }
            .foregroundColor(.secondary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 6)
        }
        .buttonStyle(.plain)
    }

    private var monthSummary: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                let hours    = vm.totalHours(inMonth: displayedMonth)
                let earnings = vm.totalEarnings(inMonth: displayedMonth)
                Text(String(format: "Month Total: %.2f hours", hours))
                    .font(.subheadline)
                Text(String(format: "Earned: %.2f PLN", earnings))
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            Spacer()
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }

    private var loadingOverlay: some View {
        ZStack {
            Color(.systemBackground).ignoresSafeArea()
            VStack(spacing: 16) {
                ProgressView().scaleEffect(1.4)
                Text("Loading entries…")
                    .foregroundColor(.secondary)
                    .font(.subheadline)
            }
        }
        .transition(.opacity)
        .animation(.easeInOut(duration: 0.25), value: vm.isLoading)
    }

    // MARK: - Helpers

    /// Sizes the calendar as a fraction of screen height so it feels right
    /// on every device — SE (568pt) through Pro Max (932pt).
    private func calendarHeight(for size: CGSize) -> CGFloat {
        if calendarExpanded {
            // ~40% of screen height, clamped between 280 and 380
            return min(max(size.height * 0.40, 280), 380)
        } else {
            // Compact = single week row + header (~100pt)
            return 100
        }
    }
}
