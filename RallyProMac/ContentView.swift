import SwiftUI
import SwiftData

struct ContentView: View {
    enum SidebarItem: Hashable {
        case sessions, waitlist, allPlayers
    }

    @State private var selection: SidebarItem? = .sessions

    init() {
        // Ensure consistent appearance
        NSApp.keyWindow?.appearance = NSAppearance(named: .aqua)
    }

    var body: some View {
        NavigationSplitView {
            sidebar
                .frame(minWidth: 240)
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [Color(.windowBackgroundColor), Color(.controlBackgroundColor)]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .ignoresSafeArea()
                )
        } detail: {
            detailView
                .frame(minWidth: 600, minHeight: 400)
                .background(Color(.textBackgroundColor).ignoresSafeArea())
        }
        .accentColor(.mint)
    }

    private var sidebar: some View {
        VStack(alignment: .leading, spacing: 16) {
            // App Header
            HStack(spacing: 8) {
                Image("AppIcon")
                    .resizable()
                    .frame(width: 32, height: 32)
                Text("RallyPro")
                    .font(.title2.bold())
            }
            .padding(.top, 16)

            Divider()

            // Navigation List
            List(selection: $selection) {
                sidebarItem(.sessions, label: "Sessions", icon: "list.bullet").tag(SidebarItem.sessions)
                sidebarItem(.waitlist, label: "Waitlist", icon: "person.fill.badge.plus").tag(SidebarItem.waitlist)
                sidebarItem(.allPlayers, label: "All Players", icon: "person.3.fill").tag(SidebarItem.allPlayers)
            }
            .listStyle(.sidebar)
            .scrollIndicators(.hidden)

            Spacer()
        }
        .padding(.horizontal, 12)
    }

    @ViewBuilder
    private var detailView: some View {
        Group {
            switch selection {
            case .sessions:
                SessionsView()
            case .waitlist:
                WaitlistView()
            case .allPlayers:
                AllPlayersView()
            default:
                VStack {
                    Text("Select a view from the sidebar")
                        .font(.headline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .padding()
    }

    private func sidebarItem(_ item: SidebarItem, label: String, icon: String) -> some View {
        Label {
            Text(label)
                .font(.headline)
        } icon: {
            Image(systemName: icon)
        }
        .padding(.vertical, 8)
        .contentShape(Rectangle())
    }

    private func toggleSidebar() {
        NSApp.keyWindow?.firstResponder?.tryToPerform(#selector(NSSplitViewController.toggleSidebar(_:)), with: nil)
    }
}
