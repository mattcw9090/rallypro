import SwiftUI
import SwiftData

struct ContentView: View {
    enum SidebarItem: Hashable {
        case sessions, waitlist, allPlayers
        var displayName: String {
            switch self {
            case .sessions:  return "Sessions"
            case .waitlist:  return "Waitlist"
            case .allPlayers:return "All Players"
            }
        }
        var icon: String {
            switch self {
            case .sessions:  return "list.bullet"
            case .waitlist:  return "person.fill.badge.plus"
            case .allPlayers:return "person.3.fill"
            }
        }
    }

    @State private var sidebarSelection: SidebarItem? = .sessions
    @State private var selectedSession: Session?
    @EnvironmentObject var seasonManager: SeasonSessionManager

    init() {
        NSApp.keyWindow?.appearance = NSAppearance(named: .aqua)
    }

    var body: some View {
        NavigationStack {
            NavigationSplitView {
                // Sidebar
                List(selection: $sidebarSelection) {
                    ForEach([SidebarItem.sessions, .waitlist, .allPlayers], id: \.self) { item in
                        Label(item.displayName, systemImage: item.icon)
                            .tag(item)
                    }
                }
                .navigationTitle("RallyPro")
                .toolbar {
                    ToolbarItem(placement: .navigation) {
                        Button { toggleSidebar() } label: {
                            Image(systemName: "sidebar.leading")
                        }
                    }
                }
            } content: {
                // Second column
                switch sidebarSelection {
                case .sessions:
                    SessionsView(selectedSession: $selectedSession)
                        .environmentObject(seasonManager)
                case .waitlist:
                    WaitlistView()
                case .allPlayers:
                    AllPlayersView()
                default:
                    Text("Select a view")
                        .foregroundColor(.secondary)
                }
            } detail: {
                // Detail pane
                if let session = selectedSession {
                    SessionDetailView(session: session)
                } else {
                    Text("Select a session")
                        .foregroundColor(.secondary)
                }
            }
            .navigationDestination(for: Session.self) { session in
                SessionDetailView(session: session)
            }
        }
        .accentColor(.mint)
    }

    private func toggleSidebar() {
        NSApp.keyWindow?.firstResponder?
            .tryToPerform(#selector(NSSplitViewController.toggleSidebar(_:)), with: nil)
    }
}
