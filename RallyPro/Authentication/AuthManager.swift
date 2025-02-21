import FirebaseAuth
import FirebaseCore
import GoogleSignIn
import AuthenticationServices
import CryptoKit
import SwiftUI

class AuthManager: ObservableObject {
    @Published var currentUser: User?
    private var handle: AuthStateDidChangeListenerHandle?
    
    // Keep coordinator references alive.
    private var appleSignInCoordinator: AppleSignInCoordinator?
    private var appleLinkingCoordinator: AppleLinkingCoordinator?
    
    init() {
        listen()
    }
    
    private func listen() {
        handle = Auth.auth().addStateDidChangeListener { [weak self] auth, user in
            DispatchQueue.main.async {
                self?.currentUser = user
            }
        }
    }
    
    deinit {
        if let handle = handle {
            Auth.auth().removeStateDidChangeListener(handle)
        }
    }
    
    // MARK: - Email/Password Authentication
    
    func signIn(email: String, password: String, completion: @escaping (Error?) -> Void) {
        Auth.auth().signIn(withEmail: email, password: password) { result, error in
            completion(error)
        }
    }
    
    func signUp(email: String, password: String, completion: @escaping (Error?) -> Void) {
        Auth.auth().createUser(withEmail: email, password: password) { result, error in
            completion(error)
        }
    }
    
    func signOut(completion: @escaping (Error?) -> Void = { _ in }) {
        do {
            try Auth.auth().signOut()
            completion(nil)
        } catch {
            completion(error)
        }
    }
    
    // MARK: - Update Email & Password
    
    func updateEmail(newEmail: String, completion: @escaping (Error?) -> Void) {
        guard let user = Auth.auth().currentUser else {
            completion(NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "No user logged in."]))
            return
        }
        user.sendEmailVerification(beforeUpdatingEmail: newEmail) { error in
            completion(error)
        }
    }
    
    func updatePassword(newPassword: String, completion: @escaping (Error?) -> Void) {
        Auth.auth().currentUser?.updatePassword(to: newPassword) { error in
            completion(error)
        }
    }
    
    // MARK: - Link Email & Password
    
    func linkEmailPassword(email: String, password: String, completion: @escaping (Error?) -> Void) {
        guard let user = Auth.auth().currentUser else {
            completion(NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "No user logged in."]))
            return
        }
        let credential = EmailAuthProvider.credential(withEmail: email, password: password)
        user.link(with: credential) { result, error in
            completion(error)
        }
    }
    
    // MARK: - Google Sign-In & Linking
    
    func signInWithGoogle(presenting viewController: UIViewController, completion: @escaping (Error?) -> Void) {
        guard let clientID = FirebaseApp.app()?.options.clientID else {
            completion(NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "Missing client ID."]))
            return
        }
        let config = GIDConfiguration(clientID: clientID)
        GIDSignIn.sharedInstance.configuration = config
        
        GIDSignIn.sharedInstance.signIn(withPresenting: viewController) { signInResult, error in
            if let error = error {
                completion(error)
                return
            }
            guard let user = signInResult?.user,
                  let idToken = user.idToken?.tokenString else {
                completion(NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "Google Sign-In failed."]))
                return
            }
            let accessToken = user.accessToken.tokenString
            let credential = GoogleAuthProvider.credential(withIDToken: idToken, accessToken: accessToken)
            Auth.auth().signIn(with: credential) { result, error in
                completion(error)
            }
        }
    }
    
    func linkGoogleAccount(presenting viewController: UIViewController, completion: @escaping (Error?) -> Void) {
        guard let currentUser = Auth.auth().currentUser else {
            completion(NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "No user logged in."]))
            return
        }
        guard let clientID = FirebaseApp.app()?.options.clientID else {
            completion(NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "Missing client ID."]))
            return
        }
        let config = GIDConfiguration(clientID: clientID)
        GIDSignIn.sharedInstance.configuration = config
        
        GIDSignIn.sharedInstance.signIn(withPresenting: viewController) { signInResult, error in
            if let error = error {
                completion(error)
                return
            }
            guard let user = signInResult?.user,
                  let idToken = user.idToken?.tokenString else {
                completion(NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "Google linking failed."]))
                return
            }
            let accessToken = user.accessToken.tokenString
            let credential = GoogleAuthProvider.credential(withIDToken: idToken, accessToken: accessToken)
            currentUser.link(with: credential) { result, error in
                completion(error)
            }
        }
    }
    
    // MARK: - Apple Sign-In & Linking
    
    func signInWithApple(completion: @escaping (Error?) -> Void) {
        let nonce = randomNonceString()
        let hashedNonce = sha256(nonce)
        
        let appleIDProvider = ASAuthorizationAppleIDProvider()
        let request = appleIDProvider.createRequest()
        request.requestedScopes = [.fullName, .email]
        request.nonce = hashedNonce
        
        let coordinator = AppleSignInCoordinator(currentNonce: nonce) { error in
            completion(error)
            self.appleSignInCoordinator = nil
        }
        self.appleSignInCoordinator = coordinator
        
        let authorizationController = ASAuthorizationController(authorizationRequests: [request])
        authorizationController.delegate = coordinator
        authorizationController.presentationContextProvider = coordinator
        authorizationController.performRequests()
    }
    
    func linkAppleAccount(completion: @escaping (Error?) -> Void) {
        guard Auth.auth().currentUser != nil else {
            completion(NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "No user logged in."]))
            return
        }
        let nonce = randomNonceString()
        let hashedNonce = sha256(nonce)
        
        let appleIDProvider = ASAuthorizationAppleIDProvider()
        let request = appleIDProvider.createRequest()
        request.requestedScopes = [.fullName, .email]
        request.nonce = hashedNonce
        
        let coordinator = AppleLinkingCoordinator(currentNonce: nonce) { error in
            completion(error)
            self.appleLinkingCoordinator = nil
        }
        self.appleLinkingCoordinator = coordinator
        
        let authorizationController = ASAuthorizationController(authorizationRequests: [request])
        authorizationController.delegate = coordinator
        authorizationController.presentationContextProvider = coordinator
        authorizationController.performRequests()
    }
    
    // MARK: - Delete Account
    
    func deleteAccount(completion: @escaping (Error?) -> Void) {
        guard let user = Auth.auth().currentUser else {
            completion(NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "No user logged in."]))
            return
        }
        user.delete { error in
            completion(error)
        }
    }
    
    // MARK: - Nonce Helpers
    
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
            Auth.auth().signIn(with: credential) { authResult, error in
                self.onComplete?(error)
            }
        }
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        onComplete?(error)
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
