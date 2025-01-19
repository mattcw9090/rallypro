import SwiftUI
import SwiftData

struct ContentView: View {
    var body: some View {
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
