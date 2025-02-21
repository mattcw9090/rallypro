import SwiftUI
import FirebaseAuth

struct RootView: View {
    @EnvironmentObject var session: SessionStore
    
    var body: some View {
        Group {
            if session.currentUser == nil {
                AuthView()
                    .environmentObject(session)
            } else {
                ContentView()
                    .environmentObject(session)
            }
        }
    }
}
