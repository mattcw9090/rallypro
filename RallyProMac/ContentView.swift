import SwiftUI
import SwiftData

struct ContentView: View {
    enum SidebarItem: Hashable {
        case sessions, waitlist, allPlayers
    }

    @State private var selection: SidebarItem? = .sessions

    var body: some View {
        NavigationSplitView {
            List(selection: $selection) {
                Label("Sessions", systemImage: "list.bullet")
                    .tag(SidebarItem.sessions)
                Label("Waitlist", systemImage: "person.fill.badge.plus")
                    .tag(SidebarItem.waitlist)
                Label("All Players", systemImage: "person.3.fill")
                    .tag(SidebarItem.allPlayers)
            }
            .navigationTitle("RallyPro")
        } detail: {
            switch selection {
            case .sessions:
                SessionsView()
            case .waitlist:
                WaitlistView()
            case .allPlayers:
                AllPlayersView()
            case .none:
                Text("Select a view from the sidebar")
                    .foregroundColor(.secondary)
            }
        }
    }
}
