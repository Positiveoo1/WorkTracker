import SwiftUI
import GoogleSignInSwift

struct AuthView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @State private var isSigningIn = false

    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                Spacer()

                Image(systemName: "clock.badge.checkmark")
                    .font(.system(size: 80))
                    .foregroundColor(.accentColor)

                Text("Work Tracker")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                Text("Sign in to sync your work hours across all devices")
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)

                GoogleSignInButton(style: .wide, action: handleSignIn)
                    .disabled(isSigningIn)
                    .padding(.horizontal, 40)

                Spacer()
            }
            .navigationTitle("Welcome")
            .alert("Sign-in error", isPresented: $authVM.showError) {
                Button("OK") {}
            } message: {
                Text(authVM.errorMessage)
            }
        }
    }

    private func handleSignIn() {
        isSigningIn = true
        Task {
            do {
                try await authVM.signInWithGoogle()
            } catch {
                authVM.handleError(error)
            }
            isSigningIn = false
        }
    }
}
