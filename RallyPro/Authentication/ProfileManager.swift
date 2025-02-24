import Foundation
import FirebaseFirestore
import FirebaseAuth

class ProfileManager: ObservableObject {
    @Published var userProfile: UserProfile?
    private var db = Firestore.firestore()
    
    func fetchUserProfile() {
        guard let uid = Auth.auth().currentUser?.uid else {
            print("No user logged in.")
            return
        }
        db.collection("users").document(uid).getDocument { snapshot, error in
            if error != nil {
                print("Error fetching user profile: \(error!.localizedDescription)")
                return
            }
            if let snapshot = snapshot, snapshot.exists {
                do {
                    let profile = try snapshot.data(as: UserProfile.self)
                    DispatchQueue.main.async {
                        self.userProfile = profile
                    }
                } catch {
                    print("Error decoding user profile: \(error.localizedDescription)")
                }
            }
        }
    }
    
    func saveUserProfile(fullName: String, bio: String, completion: @escaping (Error?) -> Void) {
        guard let uid = Auth.auth().currentUser?.uid else {
            let error = NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "No user logged in."])
            print("Error: No user logged in.")
            completion(error)
            return
        }
        let profile = UserProfile(id: uid, fullName: fullName, bio: bio)
        do {
            try db.collection("users").document(uid).setData(from: profile) { error in
                if error != nil {
                    print("Error saving user profile: \(error!.localizedDescription)")
                } else {
                    DispatchQueue.main.async {
                        self.userProfile = profile
                    }
                }
                completion(error)
            }
        } catch {
            print("Error encoding user profile: \(error.localizedDescription)")
            completion(error)
        }
    }
    
    func deleteUserProfile(completion: @escaping (Error?) -> Void) {
        guard let uid = Auth.auth().currentUser?.uid else {
            let error = NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "No user logged in."])
            print("Error: No user logged in.")
            completion(error)
            return
        }
        db.collection("users").document(uid).delete { error in
            if error != nil {
                print("Error deleting user profile: \(error!.localizedDescription)")
            }
            completion(error)
        }
    }
}
