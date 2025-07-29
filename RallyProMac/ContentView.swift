import SwiftUI
import SwiftData

struct ContentView: View {
    enum SidebarItem: Hashable {
        case sessions, waitlist, allPlayers
    }

    @State private var selection: SidebarItem? = .sessions

    init() {
        NSApp.keyWindow?.appearance = NSAppearance(named: .aqua)
    }

    var body: some View {
        NavigationSplitView {
            sidebar
                .frame(minWidth: 220)
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [Color(.windowBackgroundColor), Color(.controlBackgroundColor)]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
        } detail: {
            detailView
                .frame(minWidth: 600, minHeight: 400)
                .background(Color(.textBackgroundColor))
        }
        .toolbar {
            ToolbarItem(placement: .navigation) {
                Button(action: toggleSidebar) {
                    Image(systemName: "sidebar.leading")
                }
                .help("Toggle Sidebar")
            }
        }
        .accentColor(Color.mint)
    }

    private var sidebar: some View {
        VStack(alignment: .leading, spacing: 16) {
            // App Title
            HStack(spacing: 8) {
                Image("AppIcon")
                    .resizable()
                    .frame(width: 28, height: 28)
                Text("RallyPro")
                    .font(.title2.weight(.bold))
            }
            .padding(.top, 12)

            // Navigation List
            List(selection: $selection) {
                sidebarItem(.sessions, label: "Sessions", icon: "list.bullet")
                sidebarItem(.waitlist, label: "Waitlist", icon: "person.fill.badge.plus")
                sidebarItem(.allPlayers, label: "All Players", icon: "person.3.fill")
            }
            .listStyle(SidebarListStyle())
            .scrollIndicators(.hidden)

            Spacer()
        }
        .padding(.horizontal)
    }

    @ViewBuilder
    private var detailView: some View {
        switch selection {
        case .sessions:
            SessionsView()
                .padding()
        case .waitlist:
            WaitlistView()
                .padding()
        case .allPlayers:
            AllPlayersView()
                .padding()
        default:
            Text("Select a view from the sidebar")
                .foregroundColor(.secondary)
                .font(.headline)
        }
    }

    private func sidebarItem(_ item: SidebarItem, label: String, icon: String) -> some View {
        Label(label, systemImage: icon)
            .tag(item)
            .font(.headline)
            .padding(.vertical, 6)
    }

    private func toggleSidebar() {
        NSApp.keyWindow?.firstResponder?.tryToPerform(#selector(NSSplitViewController.toggleSidebar(_:)), with: nil)
    }
}
