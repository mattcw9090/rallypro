import Foundation
import FirebaseFirestore
import FirebaseAuth

class ProfileManager: ObservableObject {
    @Published var userProfile: UserProfile?
    private var db = Firestore.firestore()
    
    func fetchUserProfile() {
        guard let uid = Auth.auth().currentUser?.uid else {
            return
        }
        db.collection("users").document(uid).getDocument { snapshot, error in
            if let error = error {
                return
            }
            if let snapshot = snapshot, snapshot.exists {
                do {
                    let profile = try snapshot.data(as: UserProfile.self)
                    DispatchQueue.main.async {
                        self.userProfile = profile
                    }
                } catch {
                }
            }
        }
    }
    
    func saveUserProfile(fullName: String, bio: String, completion: @escaping (Error?) -> Void) {
        guard let uid = Auth.auth().currentUser?.uid else {
            let error = NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "No user logged in."])
            completion(error)
            return
        }
        let profile = UserProfile(id: uid, fullName: fullName, bio: bio)
        do {
            try db.collection("users").document(uid).setData(from: profile) { error in
                if error == nil {
                    DispatchQueue.main.async {
                        self.userProfile = profile
                    }
                }
                completion(error)
            }
        } catch {
            completion(error)
        }
    }
    
    func deleteUserProfile(completion: @escaping (Error?) -> Void) {
        guard let uid = Auth.auth().currentUser?.uid else {
            let error = NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "No user logged in."])
            completion(error)
            return
        }
        db.collection("users").document(uid).delete { error in
            completion(error)
        }
    }
}
