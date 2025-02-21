import SwiftUI
import FirebaseCore
import FirebaseAuth
import GoogleSignIn
import AuthenticationServices
import CryptoKit
import FirebaseFirestore  // <--- NEW

struct SettingsView: View {
    @EnvironmentObject var session: SessionStore
    
    @State private var newEmail = ""
    @State private var newPassword = ""
    @State private var errorMessage: String?
    @State private var successMessage: String?
    
    // New state for deletion alert and holding the Apple linking coordinator.
    @State private var showDeleteAlert = false
    @State private var appleLinkingCoordinator: AppleLinkingCoordinator?
    
    // NEW: Profile data from Firestore
    @State private var fetchedFirstName = ""
    @State private var fetchedLastName = ""
    
    var body: some View {
        NavigationView {
            Form {
                // MARK: - Account Info Section
                Section(header: sectionHeader("Account Info")) {
                    if let user = session.currentUser {
                        HStack {
                            Image(systemName: "person.crop.circle.fill")
                                .font(.title2)
                                .foregroundColor(.blue)
                            Text(user.email ?? "Unknown")
                                .font(.body)
                        }
                    } else {
                        Text("No user logged in.")
                            .foregroundColor(.secondary)
                    }
                }
                
                // MARK: - Profile Info (from Firestore)
                Section(header: sectionHeader("Profile Info")) {
                    TextField("First Name", text: $fetchedFirstName)
                        .modifier(RoundedFieldModifier())
                    TextField("Last Name", text: $fetchedLastName)
                        .modifier(RoundedFieldModifier())
                    
                    Button(action: saveUserProfile) {
                        Text("Save Profile")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(PrimaryButtonStyle())
                }
                
                // MARK: - Update Email Section
                Section(header: sectionHeader("Update Email")) {
                    TextField("New Email", text: $newEmail)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                        .modifier(RoundedFieldModifier())
                    
                    Button(action: updateEmail) {
                        Text("Update Email")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(PrimaryButtonStyle())
                }
                
                // MARK: - Update Password Section
                Section(header: sectionHeader("Update Password")) {
                    SecureField("New Password", text: $newPassword)
                        .modifier(RoundedFieldModifier())
                    
                    Button(action: updatePassword) {
                        Text("Update Password")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(PrimaryButtonStyle())
                }
                
                // MARK: - Link Accounts Section
                Section(header: sectionHeader("Link Accounts")) {
                    if !isGoogleLinked {
                        Button(action: linkGoogleAccount) {
                            Text("Link Google Account")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(PrimaryButtonStyle())
                    }
                    if !isAppleLinked {
                        Button(action: linkAppleAccount) {
                            Text("Link Apple Account")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(PrimaryButtonStyle())
                    }
                }
                
                // MARK: - Sign Out Section
                Section {
                    Button(action: { session.signOut() }) {
                        Text("Sign Out")
                            .frame(maxWidth: .infinity)
                    }
                    .foregroundColor(.red)
                    .buttonStyle(BorderlessButtonStyle())
                }
                
                // MARK: - Delete Account Section
                Section {
                    Button(action: { showDeleteAlert = true }) {
                        Text("Delete Account")
                            .frame(maxWidth: .infinity)
                    }
                    .foregroundColor(.red)
                    .buttonStyle(BorderlessButtonStyle())
                }
                .alert(isPresented: $showDeleteAlert) {
                    Alert(
                        title: Text("Delete Account"),
                        message: Text("Are you sure you want to delete your account? This action cannot be undone."),
                        primaryButton: .destructive(Text("Delete")) {
                            deleteAccount()
                        },
                        secondaryButton: .cancel()
                    )
                }
                
                // MARK: - Status Messages
                if let errorMessage = errorMessage {
                    Section {
                        Text(errorMessage)
                            .foregroundColor(.red)
                    }
                }
                
                if let successMessage = successMessage {
                    Section {
                        Text(successMessage)
                            .foregroundColor(.green)
                    }
                }
            }
            .listStyle(InsetGroupedListStyle())
            .navigationTitle("Settings")
        }
        // When the view appears, load the Firestore user profile
        .onAppear {
            loadUserProfile()
        }
    }
    
    // MARK: - Firestore Profile: Load & Save
    private func loadUserProfile() {
        guard let currentUser = session.currentUser else {
            return
        }
        
        let db = Firestore.firestore()
        let docRef = db.collection("users").document(currentUser.uid)
        
        docRef.getDocument { document, error in
            if let error = error {
                self.errorMessage = "Error loading user profile: \(error.localizedDescription)"
                return
            }
            
            guard let document = document, document.exists,
                  let data = document.data() else {
                self.errorMessage = "No profile data found."
                return
            }
            
            // Parse data
            self.fetchedFirstName = data["firstName"] as? String ?? ""
            self.fetchedLastName = data["lastName"] as? String ?? ""
        }
    }
    
    private func saveUserProfile() {
        guard let currentUser = session.currentUser else { return }
        
        let db = Firestore.firestore()
        db.collection("users").document(currentUser.uid).updateData([
            "firstName": fetchedFirstName,
            "lastName": fetchedLastName
        ]) { error in
            if let error = error {
                self.errorMessage = "Error updating profile: \(error.localizedDescription)"
            } else {
                self.successMessage = "Profile updated successfully."
            }
        }
    }
    
    // Computed properties to check if a provider is already linked.
    private var isGoogleLinked: Bool {
        session.currentUser?.providerData.contains(where: { $0.providerID == "google.com" }) ?? false
    }
    
    private var isAppleLinked: Bool {
        session.currentUser?.providerData.contains(where: { $0.providerID == "apple.com" }) ?? false
    }
    
    // MARK: - Helper Section Header
    private func sectionHeader(_ title: String) -> some View {
        HStack {
            Text(title)
                .font(.headline)
                .foregroundColor(.primary)
            Spacer()
        }
    }
    
    // MARK: - Email Update Function
    private func updateEmail() {
        guard !newEmail.isEmpty else {
            errorMessage = "Please enter a new email address."
            successMessage = nil
            return
        }
        
        guard let user = Auth.auth().currentUser else {
            errorMessage = "No user logged in."
            successMessage = nil
            return
        }
        
        user.sendEmailVerification(beforeUpdatingEmail: newEmail) { error in
            if let error = error {
                errorMessage = error.localizedDescription
                successMessage = nil
            } else {
                successMessage = "A verification email has been sent to \(newEmail). Please verify to complete the update."
                errorMessage = nil
            }
        }
    }
    
    // MARK: - Password Update Function
    private func updatePassword() {
        guard !newPassword.isEmpty else {
            errorMessage = "Please enter a new password."
            successMessage = nil
            return
        }
        
        Auth.auth().currentUser?.updatePassword(to: newPassword) { error in
            if let error = error {
                errorMessage = error.localizedDescription
                successMessage = nil
            } else {
                successMessage = "Password updated successfully."
                errorMessage = nil
            }
        }
    }
    
    // MARK: - Link Google Account Function
    private func linkGoogleAccount() {
        guard let currentUser = Auth.auth().currentUser else {
            errorMessage = "No user logged in."
            return
        }
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
                self.errorMessage = "Google linking failed: No user information."
                return
            }
            guard let idToken = user.idToken?.tokenString else {
                self.errorMessage = "Google linking failed: Missing ID token."
                return
            }
            let accessToken = user.accessToken.tokenString
            let credential = GoogleAuthProvider.credential(withIDToken: idToken, accessToken: accessToken)
            currentUser.link(with: credential) { authResult, error in
                if let error = error {
                    self.errorMessage = error.localizedDescription
                } else {
                    self.successMessage = "Google account linked successfully."
                }
            }
        }
    }
    
    // MARK: - Link Apple Account Function
    private func linkAppleAccount() {
        guard Auth.auth().currentUser != nil else {
            errorMessage = "No user logged in."
            return
        }
        let nonce = randomNonceString()
        let hashedNonce = sha256(nonce)
        
        let appleIDProvider = ASAuthorizationAppleIDProvider()
        let request = appleIDProvider.createRequest()
        request.requestedScopes = [.fullName, .email]
        request.nonce = hashedNonce
        
        let coordinator = AppleLinkingCoordinator(currentNonce: nonce) { error in
            if let error = error {
                self.errorMessage = error.localizedDescription
            } else {
                self.successMessage = "Apple account linked successfully."
            }
            self.appleLinkingCoordinator = nil
        }
        self.appleLinkingCoordinator = coordinator
        
        let authorizationController = ASAuthorizationController(authorizationRequests: [request])
        authorizationController.delegate = coordinator
        authorizationController.presentationContextProvider = coordinator
        authorizationController.performRequests()
    }
    
    // MARK: - Delete Account Function
    private func deleteAccount() {
        guard let user = Auth.auth().currentUser else {
            errorMessage = "No user logged in."
            return
        }
        user.delete { error in
            if let error = error {
                self.errorMessage = error.localizedDescription
            } else {
                self.successMessage = "Account deleted successfully."
            }
        }
    }
    
    // MARK: - Helper Function to Get the Root View Controller
    private func getRootViewController() -> UIViewController {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let root = windowScene.windows.first?.rootViewController else {
            return UIViewController()
        }
        return root
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

// MARK: - Apple Linking Coordinator
class AppleLinkingCoordinator: NSObject, ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding {
    var currentNonce: String?
    var onComplete: ((Error?) -> Void)?
    
    init(currentNonce: String?, onComplete: ((Error?) -> Void)? = nil) {
        self.currentNonce = currentNonce
        self.onComplete = onComplete
        super.init()
    }
    
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
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
            let credential = OAuthProvider.appleCredential(withIDToken: idTokenString,
                                                           rawNonce: nonce,
                                                           fullName: appleIDCredential.fullName)
            Auth.auth().currentUser?.link(with: credential) { authResult, error in
                self.onComplete?(error)
            }
        }
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        onComplete?(error)
    }
}

// MARK: - Custom Modifiers & Styles
struct RoundedFieldModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(10)
            .background(Color(UIColor.secondarySystemBackground))
            .cornerRadius(8)
    }
}

struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding()
            .background(Color.blue.opacity(configuration.isPressed ? 0.7 : 1.0))
            .foregroundColor(.white)
            .cornerRadius(8)
    }
}
