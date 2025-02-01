import SwiftUI
import SwiftData

struct AllPlayersView: View {
    @EnvironmentObject var playerManager: PlayerManager
    @Environment(\.modelContext) private var modelContext

    // MARK: - State

    @State private var showingAddPlayerSheet = false
    @State private var selectedPlayerForEditing: Player?
    @State private var searchText = ""

    // MARK: - Queries
    
    private var filteredPlayers: [Player] {
        guard !searchText.isEmpty else {
            return playerManager.allPlayers
        }
        return playerManager.allPlayers.filter { player in
            player.name.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    // Latest Waitlist Position Query
    private var latestWaitlistPosition: Int? {
        playerManager.allPlayers
            .filter { $0.status == .onWaitlist }
            .compactMap { $0.waitlistPosition }
            .max()
    }
    
    // MARK: - Body

    var body: some View {
        NavigationView {
            List {
                ForEach(filteredPlayers) { player in
                    Button {
                        selectedPlayerForEditing = player
                    } label: {
                        PlayerRowView(player: player)
                    }
                    .swipeActions(edge: .trailing) {
                        if player.status == .notInSession {
                            Button {
                                addToWaitlist(player)
                            } label: {
                                Label("Add to Waitlist", systemImage: "list.bullet")
                            }
                            .tint(.orange)
                        }
                    }
                }
            }
            .navigationTitle("All Players")
            // 1. Add the .searchable modifier
            .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always))
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingAddPlayerSheet = true
                    } label: {
                        Label("Add Player", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddPlayerSheet) {
                AddPlayerView()
            }
            .sheet(item: $selectedPlayerForEditing) { player in
                EditPlayerView(player: player)
            }
            .onAppear {
                playerManager.fetchAllPlayers()
            }
        }
    }
    
    // MARK: - Methods
    
    private func addToWaitlist(_ player: Player) {
        player.status = .onWaitlist
        let nextPosition = (latestWaitlistPosition ?? 0) + 1
        player.waitlistPosition = nextPosition
        
        do {
            try modelContext.save()
        } catch {
            print("Error adding player to waitlist: \(error)")
        }
    }
}

#Preview {
    let schema = Schema([Player.self])
    let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)

    do {
        let mockContainer = try ModelContainer(for: schema, configurations: [modelConfiguration])
        let mockManager = PlayerManager(modelContext: mockContainer.mainContext)
        
        // Insert Mock Data
        let context = mockContainer.mainContext
        context.insert(Player(name: "Alice", status: .playing, isMale: false))
        context.insert(Player(name: "Bob", status: .onWaitlist, waitlistPosition: 2, isMale: true))
        context.insert(Player(name: "Charlie", status: .notInSession, isMale: true))
        context.insert(Player(name: "Denise", status: .onWaitlist, waitlistPosition: 1, isMale: false))

        return AllPlayersView()
            .environmentObject(mockManager)
            .modelContainer(mockContainer)
    } catch {
        fatalError("Could not create ModelContainer: \(error)")
    }
}
