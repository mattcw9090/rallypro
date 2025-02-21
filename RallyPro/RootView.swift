import SwiftUI
import FirebaseAuth

struct RootView: View {
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var profileManager: ProfileManager
    
    var body: some View {
        Group {
            if authManager.currentUser == nil {
                AuthView()
                    .onAppear {
                        print("DEBUG: No authenticated user, showing AuthView.")
                    }
            } else if profileManager.userProfile == nil {
                ProfileSetupView()
                    .onAppear {
                        print("DEBUG: Authenticated user found, but profile is nil. Showing ProfileSetupView.")
                    }
            } else {
                ContentView()
                    .onAppear {
                        print("DEBUG: Authenticated user with profile, showing ContentView.")
                    }
            }
        }
        .onAppear {
            // Delay fetching slightly to allow Firebase to restore the user.
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                if let user = authManager.currentUser {
                    print("DEBUG: onAppear - Authenticated user (\(user.uid)) detected, fetching profile.")
                    profileManager.fetchUserProfile()
                } else {
                    print("DEBUG: onAppear - No authenticated user found.")
                }
            }
        }
        .onChange(of: authManager.currentUser) { newUser in
            if let user = newUser {
                print("DEBUG: AuthManager currentUser changed to: \(user.uid), fetching profile.")
                profileManager.fetchUserProfile()
            } else {
                print("DEBUG: AuthManager currentUser changed to nil.")
            }
        }
    }
}
