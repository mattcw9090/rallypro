import SwiftUI
import FirebaseCore
import FirebaseAuth
import GoogleSignIn

struct AuthView: View {
    @State private var email = ""
    @State private var password = ""
    @State private var errorMessage: String?
    @State private var isSignUpMode = false

    var body: some View {
        VStack(spacing: 20) {
            Text("Welcome to RallyPro")
                .font(.largeTitle)
                .bold()
            
            TextField("Email", text: $email)
                .keyboardType(.emailAddress)
                .autocapitalization(.none)
                .padding()
                .background(Color(UIColor.secondarySystemBackground))
                .cornerRadius(5)
            
            SecureField("Password", text: $password)
                .padding()
                .background(Color(UIColor.secondarySystemBackground))
                .cornerRadius(5)
            
            if let errorMessage = errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
            }
            
            Button(action: {
                authenticate()
            }) {
                Text(isSignUpMode ? "Sign Up" : "Sign In")
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                    .cornerRadius(5)
            }
            
            Button(action: {
                isSignUpMode.toggle()
            }) {
                Text(isSignUpMode ? "Already have an account? Sign In" : "Don't have an account? Sign Up")
                    .foregroundColor(.blue)
            }
            
            // New Google Sign-In button
            Button(action: {
                signInWithGoogle()
            }) {
                HStack {
                    Image(systemName: "g.circle.fill")
                        .font(.title)
                    Text("Sign in with Google")
                        .fontWeight(.semibold)
                }
                .foregroundColor(.white)
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.red)
                .cornerRadius(5)
            }
        }
        .padding()
    }
    
    private func authenticate() {
        errorMessage = nil
        if isSignUpMode {
            Auth.auth().createUser(withEmail: email, password: password) { result, error in
                if let error = error {
                    self.errorMessage = error.localizedDescription
                    return
                }
                // Successful sign-up; Firebase will trigger an auth state change.
            }
        } else {
            Auth.auth().signIn(withEmail: email, password: password) { result, error in
                if let error = error {
                    self.errorMessage = error.localizedDescription
                    return
                }
                // Successful sign-in; Firebase will trigger an auth state change.
            }
        }
    }
    
    // MARK: - Google Sign-In Functionality
    private func signInWithGoogle() {
        // Ensure the Firebase client ID is available.
        guard let clientID = FirebaseApp.app()?.options.clientID else {
            errorMessage = "Missing client ID."
            return
        }
        
        // Create a configuration object with the client ID.
        let config = GIDConfiguration(clientID: clientID)
        GIDSignIn.sharedInstance.configuration = config
        
        // Retrieve the presenting view controller.
        let rootViewController = self.getRootViewController()
        
        // Start the Google Sign-In process.
        GIDSignIn.sharedInstance.signIn(withPresenting: rootViewController) { signInResult, error in
            if let error = error {
                self.errorMessage = error.localizedDescription
                return
            }
            
            // Ensure we have a valid user.
            guard let user = signInResult?.user else {
                self.errorMessage = "Google Sign-In failed: No user information."
                return
            }
            
            // Safely unwrap the ID token.
            guard let idToken = user.idToken?.tokenString else {
                self.errorMessage = "Google Sign-In failed: Missing ID token."
                return
            }
            
            // The access token is non-optional.
            let accessToken = user.accessToken.tokenString
            
            // Create a Firebase credential using the tokens.
            let credential = GoogleAuthProvider.credential(withIDToken: idToken, accessToken: accessToken)
            
            // Sign in with Firebase using the Google credential.
            Auth.auth().signIn(with: credential) { authResult, error in
                if let error = error {
                    self.errorMessage = error.localizedDescription
                } else if let authResult = authResult {
                    print("User signed in with Google: \(authResult.user.uid)")
                    self.errorMessage = nil
                }
            }
        }
    }

}

// MARK: - Helper Extension to Retrieve the Root View Controller
extension View {
    func getRootViewController() -> UIViewController {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let root = windowScene.windows.first?.rootViewController else {
            return UIViewController()
        }
        return root
    }
}
