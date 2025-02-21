import SwiftUI
import FirebaseCore
import FirebaseAuth
import GoogleSignIn
import AuthenticationServices
import CryptoKit
import FirebaseFirestore

struct AuthView: View {
    @State private var email = ""
    @State private var password = ""
    @State private var errorMessage: String?
    @State private var isSignUpMode = false
    
    // NEW: Additional fields for user profile
    @State private var firstName = ""
    @State private var lastName = ""
    
    // Used to hold a reference to the Apple Sign In coordinator so it stays alive until completion.
    @State private var appleSignInCoordinator: AppleSignInCoordinator?
    
    var body: some View {
        ZStack {
            // Background gradient for visual appeal.
            LinearGradient(gradient: Gradient(colors: [Color.blue.opacity(0.3), Color.purple.opacity(0.3)]),
                           startPoint: .topLeading,
                           endPoint: .bottomTrailing)
                .edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 20) {
                Text("Welcome to RallyPro")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding(.bottom, 20)
                
                VStack(spacing: 15) {
                    // Email input with icon.
                    HStack {
                        Image(systemName: "envelope.fill")
                            .foregroundColor(.gray)
                        TextField("Email", text: $email)
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                    }
                    .padding()
                    .background(Color.white)
                    .cornerRadius(8)
                    
                    // Password input with icon.
                    HStack {
                        Image(systemName: "lock.fill")
                            .foregroundColor(.gray)
                        SecureField("Password", text: $password)
                    }
                    .padding()
                    .background(Color.white)
                    .cornerRadius(8)
                    
                    // NEW: Show additional fields if sign-up
                    if isSignUpMode {
                        HStack {
                            Image(systemName: "person.fill")
                                .foregroundColor(.gray)
                            TextField("First Name", text: $firstName)
                                .autocapitalization(.words)
                        }
                        .padding()
                        .background(Color.white)
                        .cornerRadius(8)

                        HStack {
                            Image(systemName: "person.fill")
                                .foregroundColor(.gray)
                            TextField("Last Name", text: $lastName)
                                .autocapitalization(.words)
                        }
                        .padding()
                        .background(Color.white)
                        .cornerRadius(8)
                    }
                }
                .padding(.horizontal, 20)
                
                // Error message display.
                if let errorMessage = errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                }
                
                // Sign In/Sign Up button.
                Button(action: authenticate) {
                    Text(isSignUpMode ? "Sign Up" : "Sign In")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                .padding(.horizontal, 20)
                
                // Toggle authentication mode.
                Button(action: { isSignUpMode.toggle() }) {
                    Text(isSignUpMode ? "Already have an account? Sign In" : "Don't have an account? Sign Up")
                        .foregroundColor(.blue)
                }
                
                // Google Sign-In button.
                Button(action: signInWithGoogle) {
                    HStack {
                        Image(systemName: "g.circle.fill")
                            .font(.title)
                        Text("Sign in with Google")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.red)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
                .padding(.horizontal, 20)
                
                // Apple Sign-In button.
                Button(action: signInWithApple) {
                    HStack {
                        Image(systemName: "applelogo")
                            .font(.title)
                        Text("Sign in with Apple")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.black)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
                .padding(.horizontal, 20)
                
                Spacer()
            }
            .padding(.top, 50)
        }
    }
    
    // MARK: - Email/Password Authentication
    private func authenticate() {
        errorMessage = nil
        if isSignUpMode {
            Auth.auth().createUser(withEmail: email, password: password) { result, error in
                if let error = error {
                    self.errorMessage = error.localizedDescription
                    return
                }
                // If user creation was successful, store extra info in Firestore
                guard let user = result?.user else { return }
                
                let db = Firestore.firestore()
                db.collection("users").document(user.uid).setData([
                    "email": user.email ?? "",
                    "firstName": self.firstName,
                    "lastName": self.lastName,
                    "createdAt": FieldValue.serverTimestamp()
                ]) { err in
                    if let err = err {
                        self.errorMessage = "Error saving user data: \(err.localizedDescription)"
                    } else {
                        print("User profile successfully created in Firestore!")
                    }
                }
            }
        } else {
            Auth.auth().signIn(withEmail: email, password: password) { result, error in
                if let error = error {
                    self.errorMessage = error.localizedDescription
                    return
                }
                // Successful sign-in; do any post-sign-in logic if needed
            }
        }
    }
    
    // MARK: - Google Sign-In Functionality
    private func signInWithGoogle() {
        guard let clientID = FirebaseApp.app()?.options.clientID else {
            errorMessage = "Missing client ID."
            return
        }
        
        let config = GIDConfiguration(clientID: clientID)
        GIDSignIn.sharedInstance.configuration = config
        
        let rootViewController = self.getRootViewController()
        
        GIDSignIn.sharedInstance.signIn(withPresenting: rootViewController) { signInResult, error in
            if let error = error {
                self.errorMessage = error.localizedDescription
                return
            }
            
            guard let user = signInResult?.user else {
                self.errorMessage = "Google Sign-In failed: No user information."
                return
            }
            
            guard let idToken = user.idToken?.tokenString else {
                self.errorMessage = "Google Sign-In failed: Missing ID token."
                return
            }
            
            let accessToken = user.accessToken.tokenString
            let credential = GoogleAuthProvider.credential(withIDToken: idToken, accessToken: accessToken)
            
            Auth.auth().signIn(with: credential) { authResult, error in
                if let error = error {
                    self.errorMessage = error.localizedDescription
                } else {
                    print("User signed in with Google: \(authResult?.user.uid ?? "")")
                    self.errorMessage = nil
                }
            }
        }
    }
    
    // MARK: - Apple Sign-In Functionality
    private func signInWithApple() {
        let nonce = randomNonceString()
        let hashedNonce = sha256(nonce)
        
        let appleIDProvider = ASAuthorizationAppleIDProvider()
        let request = appleIDProvider.createRequest()
        request.requestedScopes = [.fullName, .email]
        request.nonce = hashedNonce
        
        // Create and hold onto the coordinator so it isn't deallocated immediately.
        let coordinator = AppleSignInCoordinator(currentNonce: nonce) { error in
            if let error = error {
                self.errorMessage = error.localizedDescription
            } else {
                self.errorMessage = nil
            }
            // Release the coordinator after completion.
            self.appleSignInCoordinator = nil
        }
        self.appleSignInCoordinator = coordinator
        
        let authorizationController = ASAuthorizationController(authorizationRequests: [request])
        authorizationController.delegate = coordinator
        authorizationController.presentationContextProvider = coordinator
        authorizationController.performRequests()
    }
    
    // MARK: - Nonce Generation Helpers
    private func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        var randomBytes = [UInt8](repeating: 0, count: length)
        let errorCode = SecRandomCopyBytes(kSecRandomDefault, randomBytes.count, &randomBytes)
        if errorCode != errSecSuccess {
            fatalError("Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(errorCode)")
        }
        let charset: [Character] = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        let nonce = randomBytes.map { byte in
            charset[Int(byte) % charset.count]
        }
        return String(nonce)
    }
    
    private func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashedData = SHA256.hash(data: inputData)
        let hashString = hashedData.compactMap { String(format: "%02x", $0) }.joined()
        return hashString
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

// MARK: - Apple Sign-In Coordinator

class AppleSignInCoordinator: NSObject, ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding {
    var currentNonce: String?
    var onComplete: ((Error?) -> Void)?
    
    init(currentNonce: String?, onComplete: ((Error?) -> Void)? = nil) {
        self.currentNonce = currentNonce
        self.onComplete = onComplete
        super.init()
    }
    
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        // Return the app’s main window.
        guard let window = UIApplication.shared.connectedScenes
                .compactMap({ $0 as? UIWindowScene })
                .first?.windows.first else {
            return ASPresentationAnchor()
        }
        return window
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
            guard let nonce = currentNonce else {
                onComplete?(NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid state: No nonce."]))
                return
            }
            guard let appleIDToken = appleIDCredential.identityToken,
                  let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
                onComplete?(NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "Unable to fetch identity token."]))
                return
            }
            // Initialize a Firebase credential.
            let credential = OAuthProvider.appleCredential(withIDToken: idTokenString,
                                                           rawNonce: nonce,
                                                           fullName: appleIDCredential.fullName)
            // Sign in with Firebase.
            Auth.auth().signIn(with: credential) { authResult, error in
                self.onComplete?(error)
            }
        }
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        onComplete?(error)
    }
}
