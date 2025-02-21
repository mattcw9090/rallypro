import SwiftUI
import FirebaseAuth

struct RootView: View {
    @EnvironmentObject var authManager: AuthManager
    
    var body: some View {
        Group {
            if authManager.currentUser == nil {
                AuthView()
            } else {
                ContentView()
            }
        }
    }
}
