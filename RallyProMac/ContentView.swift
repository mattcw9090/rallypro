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
                WaitlistPlaceholder()
            case .allPlayers:
                AllPlayersPlaceholder()
            case .none:
                Text("Select a view from the sidebar")
                    .foregroundColor(.secondary)
            }
        }
    }
}

struct WaitlistPlaceholder: View {
    var body: some View {
        Text("Waitlist View")
            .font(.largeTitle)
            .foregroundColor(.green)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct AllPlayersPlaceholder: View {
    var body: some View {
        Text("All Players View")
            .font(.largeTitle)
            .foregroundColor(.orange)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
