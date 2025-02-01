import SwiftUI
import SwiftData

struct WaitlistView: View {
    @EnvironmentObject var playerManager: PlayerManager
    @EnvironmentObject var seasonManager: SeasonSessionManager

    @State private var showingAlert = false
    @State private var alertMessage = ""

    var body: some View {
        NavigationView {
            VStack {
                List {
                    ForEach(playerManager.waitlistPlayers) { player in
                        HStack {
                            Image(systemName: "person.circle.fill")
                                .resizable()
                                .frame(width: 40, height: 40)
                                .foregroundColor(player.isMale ?? true ? .blue : .pink)

                            VStack(alignment: .leading) {
                                Text(player.name)
                                    .font(.headline)
                                if let pos = player.waitlistPosition {
                                    Text("Position: \(pos)")
                                        .foregroundColor(.gray)
                                        .font(.caption)
                                }
                            }
                        }
                        .padding(.vertical, 5)
                        .swipeActions(edge: .trailing) {
                            Button {
                                do {
                                    try playerManager.movePlayerToCurrentSession(player, session: seasonManager.latestSession)
                                } catch {
                                    alertMessage = error.localizedDescription
                                    showingAlert = true
                                }
                            } label: {
                                Label("Move to Current Session", systemImage: "sportscourt")
                            }

                            Button {
                                do {
                                    try playerManager.movePlayerToBottom(player)
                                } catch {
                                    alertMessage = error.localizedDescription
                                    showingAlert = true
                                }
                            } label: {
                                Label("Move to Bottom", systemImage: "arrow.down")
                            }
                            .tint(.blue)
                        }
                        .swipeActions(edge: .leading) {
                            Button {
                                do {
                                    try playerManager.removeFromWaitlist(player)
                                } catch {
                                    alertMessage = error.localizedDescription
                                    showingAlert = true
                                }
                            } label: {
                                Label("Remove from Waitlist", systemImage: "minus.circle")
                            }
                        }
                    }
                }
                .listStyle(InsetGroupedListStyle())
                .navigationTitle("Waitlist")
            }
            .alert("Operation Failed", isPresented: $showingAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(alertMessage)
            }
        }
    }
}

#Preview {
    let schema = Schema([Player.self, Season.self, Session.self, SessionParticipant.self])
    let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)

    do {
        let mockContainer = try ModelContainer(for: schema, configurations: [modelConfiguration])
        let context = mockContainer.mainContext
        
        let season1 = Season(seasonNumber: 1)
        context.insert(season1)
        let season2 = Season(seasonNumber: 2)
        context.insert(season2)
        context.insert(Session(sessionNumber: 1, season: season2))
        context.insert(Session(sessionNumber: 2, season: season1))
        context.insert(Player(name: "Alice", status: .playing))
        context.insert(Player(name: "Bob", status: .onWaitlist, waitlistPosition: 2))
        context.insert(Player(name: "Charlie", status: .onWaitlist, waitlistPosition: 3))
        context.insert(Player(name: "Denise", status: .onWaitlist, waitlistPosition: 1))
        context.insert(Player(name: "Eve", status: .onWaitlist, waitlistPosition: 4))
        
        let playerManager = PlayerManager(modelContext: context)
        let seasonManager = SeasonSessionManager(modelContext: context)
        
        return WaitlistView()
            .modelContainer(mockContainer)
            .environmentObject(playerManager)
            .environmentObject(seasonManager)
    } catch {
        fatalError("Could not create ModelContainer: \(error)")
    }
}
