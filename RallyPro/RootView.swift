import SwiftUI
import FirebaseAuth

struct RootView: View {
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var profileManager: ProfileManager
    
    var body: some View {
        Group {
            if authManager.currentUser == nil {
                AuthView()
            } else if profileManager.userProfile == nil {
                ProfileSetupView()
            } else {
                ContentView()
            }
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                if let user = authManager.currentUser {
                    profileManager.fetchUserProfile()
                }
            }
        }
        .onChange(of: authManager.currentUser) { newUser in
            if newUser != nil {
                profileManager.fetchUserProfile()
            }
        }
    }
}
