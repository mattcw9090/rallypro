import SwiftUI
import SwiftData

struct AllPlayersView: View {
    @EnvironmentObject var playerManager: PlayerManager
    
    @State private var showingAddPlayerSheet = false
    @State private var selectedPlayerForEditing: Player?
    @State private var searchText = ""
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(playerManager.searchPlayers(searchText: searchText)) { player in
                    PlayerRowView(player: player)
                        .swipeActions(edge: .trailing) {
                            swipeActions(for: player)
                        }
                        .onTapGesture {
                            selectedPlayerForEditing = player
                        }
                }
            }
            .navigationTitle("All Players")
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
    
    @ViewBuilder
    private func swipeActions(for player: Player) -> some View {
        if player.status == .notInSession {
            Button {
                playerManager.addNewPlayerToWaitlist(player)
            } label: {
                Label("Add to Waitlist", systemImage: "list.bullet")
            }
            .tint(.orange)
        }
    }
}

struct PlayerRowView: View {
    let player: Player
    
    var body: some View {
        HStack {
            Image(systemName: "person.circle.fill")
                .resizable()
                .frame(width: 40, height: 40)
                .foregroundColor(player.isMale ?? true ? .blue : .pink)
            
            VStack(alignment: .leading) {
                Text(player.name)
                    .font(.body)
                Text(player.status.rawValue)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
        }
        .padding(.vertical, 5)
    }
}

#Preview {
    let schema = Schema([Player.self])
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    
    do {
        let container = try ModelContainer(for: schema, configurations: config)
        let manager = PlayerManager(modelContext: container.mainContext)
        
        // Insert mock data
        let mockPlayers = [
            Player(name: "Alice", status: .playing, isMale: false),
            Player(name: "Bob", status: .onWaitlist, waitlistPosition: 2, isMale: true),
            Player(name: "Charlie", status: .notInSession, isMale: true),
            Player(name: "Denise", status: .onWaitlist, waitlistPosition: 1, isMale: false)
        ]
        mockPlayers.forEach { container.mainContext.insert($0) }
        
        return AllPlayersView()
            .environmentObject(manager)
            .modelContainer(container)
    } catch {
        fatalError("Failed to create preview container: \(error)")
    }
}
