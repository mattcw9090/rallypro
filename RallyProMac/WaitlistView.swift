import SwiftUI
import SwiftData

struct WaitlistView: View {
    @EnvironmentObject var playerManager: PlayerManager
    @EnvironmentObject var seasonManager: SeasonSessionManager

    @State private var showingAlert = false
    @State private var alertMessage = ""

    var body: some View {
        NavigationStack {
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
                                movePlayerToSession(player)
                            } label: {
                                Label("Move to Current Session", systemImage: "sportscourt")
                            }

                            Button {
                                movePlayerToBottom(player)
                            } label: {
                                Label("Move to Bottom", systemImage: "arrow.down")
                            }
                            .tint(.blue)
                        }
                        .swipeActions(edge: .leading) {
                            Button {
                                removePlayerFromWaitlist(player)
                            } label: {
                                Label("Remove from Waitlist", systemImage: "minus.circle")
                            }
                        }
                    }
                }
                .listStyle(.inset)
                .navigationTitle("Waitlist")
            }
            .alert("Operation Failed", isPresented: $showingAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(alertMessage)
            }
        }
    }

    private func movePlayerToSession(_ player: Player) {
        do {
            try playerManager.movePlayerFromWaitlistToCurrentSession(player, session: seasonManager.latestSession)
        } catch {
            alertMessage = error.localizedDescription
            showingAlert = true
        }
    }

    private func movePlayerToBottom(_ player: Player) {
        do {
            try playerManager.moveWaitlistPlayerToBottom(player)
        } catch {
            alertMessage = error.localizedDescription
            showingAlert = true
        }
    }

    private func removePlayerFromWaitlist(_ player: Player) {
        do {
            try playerManager.removeFromWaitlist(player)
        } catch {
            alertMessage = error.localizedDescription
            showingAlert = true
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
        context.insert(Player(name: "Bob", status: .onWaitlist, waitlistPosition: 2))
        context.insert(Player(name: "Charlie", status: .onWaitlist, waitlistPosition: 3))
        context.insert(Player(name: "Denise", status: .onWaitlist, waitlistPosition: 1))
        context.insert(Player(name: "Eve", status: .onWaitlist, waitlistPosition: 4))

        let playerManager = PlayerManager(modelContext: context)
        let seasonManager = SeasonSessionManager(modelContext: context)

        return NavigationStack {
            WaitlistView()
                .modelContainer(mockContainer)
                .environmentObject(playerManager)
                .environmentObject(seasonManager)
        }
    } catch {
        fatalError("Could not create ModelContainer: \(error)")
    }
}
