import Foundation
import FirebaseFirestore
import FirebaseAuth

class ProfileManager: ObservableObject {
    @Published var userProfile: UserProfile?
    private var db = Firestore.firestore()
    
    func fetchUserProfile() {
        guard let uid = Auth.auth().currentUser?.uid else {
            print("DEBUG: No user logged in for fetching profile.")
            return
        }
        print("DEBUG: Attempting to fetch user profile for uid: \(uid)")
        db.collection("users").document(uid).getDocument { snapshot, error in
            if let error = error {
                print("DEBUG: Error fetching user profile: \(error.localizedDescription)")
                return
            }
            if let snapshot = snapshot, snapshot.exists {
                let data = snapshot.data() ?? [:]
                print("DEBUG: Found profile document for uid: \(uid). Data: \(data)")
                do {
                    let profile = try snapshot.data(as: UserProfile.self)
                    DispatchQueue.main.async {
                        self.userProfile = profile
                        print("DEBUG: User profile set successfully: \(profile)")
                    }
                } catch {
                    print("DEBUG: Error decoding profile: \(error.localizedDescription)")
                }
            } else {
                print("DEBUG: No profile document exists for uid: \(uid)")
            }
        }
    }
    
    func saveUserProfile(fullName: String, bio: String, completion: @escaping (Error?) -> Void) {
        guard let uid = Auth.auth().currentUser?.uid else {
            let error = NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "No user logged in."])
            print("DEBUG: \(error.localizedDescription)")
            completion(error)
            return
        }
        let profile = UserProfile(id: uid, fullName: fullName, bio: bio)
        print("DEBUG: Saving profile for uid: \(uid) with data: \(profile)")
        do {
            try db.collection("users").document(uid).setData(from: profile) { error in
                if let error = error {
                    print("DEBUG: Error saving profile: \(error.localizedDescription)")
                } else {
                    DispatchQueue.main.async {
                        self.userProfile = profile
                        print("DEBUG: Profile saved and userProfile updated successfully: \(profile)")
                    }
                }
                completion(error)
            }
        } catch {
            print("DEBUG: Error encoding profile: \(error.localizedDescription)")
            completion(error)
        }
    }
    
    func deleteUserProfile(completion: @escaping (Error?) -> Void) {
        guard let uid = Auth.auth().currentUser?.uid else {
            let error = NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "No user logged in."])
            print("DEBUG: \(error.localizedDescription)")
            completion(error)
            return
        }
        db.collection("users").document(uid).delete { error in
            if let error = error {
                print("DEBUG: Error deleting user profile: \(error.localizedDescription)")
            } else {
                print("DEBUG: User profile deleted successfully for uid: \(uid)")
            }
            completion(error)
        }
    }
}
