import Foundation
import FirebaseAuth
import GoogleSignIn
import GoogleSignInSwift   // <-- important for the new API

@MainActor
final class AuthViewModel: ObservableObject {
    @Published var isSignedIn = false
    @Published var showError = false
    @Published var errorMessage = ""

    init() {
        checkAuthState()
        // Listen to auth changes (so logout works instantly)
        Auth.auth().addStateDidChangeListener { [weak self] _, user in
            self?.isSignedIn = user != nil
        }
    }

    func checkAuthState() {
        isSignedIn = Auth.auth().currentUser != nil
    }

    func signInWithGoogle() async throws {
        guard
            let windowScene = UIApplication.shared.connectedScenes
                .compactMap({ $0 as? UIWindowScene })
                .first,
            let rootVC = windowScene.keyWindow?.rootViewController
        else {
            throw URLError(.cannotFindHost)
        }


        let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: rootVC)

        guard let idToken = result.user.idToken?.tokenString else {
            throw URLError(.userAuthenticationRequired)
        }

        let credential = GoogleAuthProvider.credential(
            withIDToken: idToken,
            accessToken: result.user.accessToken.tokenString
        )

        try await Auth.auth().signIn(with: credential)
        isSignedIn = true
    }

    func signOut() {
        try? Auth.auth().signOut()
        GIDSignIn.sharedInstance.disconnect()
        isSignedIn = false
    }

    func handleError(_ error: Error) {
        errorMessage = error.localizedDescription
        showError = true
    }
}

extension UIWindowScene {
    var keyWindow: UIWindow? {
        return self.windows.first { $0.isKeyWindow }
    }
}
