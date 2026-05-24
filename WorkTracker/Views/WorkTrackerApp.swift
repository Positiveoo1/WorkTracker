import SwiftUI
import FirebaseCore
import GoogleSignIn

@main
struct WorkTrackerApp: App {
    @StateObject private var authVM   = AuthViewModel()
    @StateObject private var clientVM = ClientViewModel()   // ← closing ) was missing

    init() {
        FirebaseApp.configure()
    }

    var body: some Scene {
        WindowGroup {
            MainView()
                .environmentObject(authVM)
                .environmentObject(clientVM)
                .onOpenURL { url in
                    GIDSignIn.sharedInstance.handle(url)
                }
        }
    }
}

struct MainView: View {
    @EnvironmentObject var authVM: AuthViewModel

    var body: some View {
        Group {
            if authVM.isSignedIn {
                ContentView()
            } else {
                AuthView()
            }
        }
    }
}
