import SwiftUI
import FirebaseAuth

struct RootView: View {
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var profileManager: ProfileManager
    
    var body: some View {
        Group {
            if authManager.currentUser == nil {
                ContentView() // Use AuthView()
            } else if profileManager.userProfile == nil {
                ContentView() // Use ProfileSetupView()
            } else {
                ContentView()
            }
        }
        .onAppear {
            if authManager.currentUser != nil {
                profileManager.fetchUserProfile()
            }
        }
        .onChange(of: authManager.currentUser) { newUser in
            if newUser != nil {
                profileManager.fetchUserProfile()
            }
        }
    }
}
