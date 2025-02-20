import FirebaseAuth
import Combine

class SessionStore: ObservableObject {
    @Published var currentUser: User?
    private var handle: AuthStateDidChangeListenerHandle?

    init() {
        listen()
    }

    func listen() {
        handle = Auth.auth().addStateDidChangeListener { auth, user in
            self.currentUser = user
        }
    }

    deinit {
        if let handle = handle {
            Auth.auth().removeStateDidChangeListener(handle)
        }
    }
    
    func signOut() {
        do {
            try Auth.auth().signOut()
        } catch {
            print("Error signing out: \(error.localizedDescription)")
        }
    }
}
