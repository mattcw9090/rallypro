import SwiftUI
import SwiftData

struct ContentView: View {
    @StateObject var session = SessionStore()

    var body: some View {
        ZStack {
            TabView {
                SessionsView()
                    .tabItem {
                        Label("Sessions", systemImage: "list.bullet")
                    }
                
                WaitlistView()
                    .tabItem {
                        Label("Waitlist", systemImage: "person.fill.badge.plus")
                    }
                
                AllPlayersView()
                    .tabItem {
                        Label("All Players", systemImage: "person.3.fill")
                    }
            }
        }
        .fullScreenCover(isPresented: Binding<Bool>(
            get: { session.currentUser == nil },
            set: { _ in }
        )) {
            AuthView()
        }
    }
}

#Preview {
    let schema = Schema([Player.self, Season.self, Session.self, SessionParticipant.self, DoublesMatch.self])
    let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)

    do {
        let mockContainer = try ModelContainer(for: schema, configurations: [modelConfiguration])
        return ContentView()
            .modelContainer(mockContainer)
    } catch {
        fatalError("Could not create ModelContainer: \(error)")
    }
}
