import SwiftUI

struct AllPlayersViewBeta: View {
    @EnvironmentObject var playerManager: PlayerManagerBeta
    @State private var showAddPlayerSheet = false
    @State private var selectedPlayerForEdit: PlayerBeta? = nil

    var body: some View {
        NavigationView {
            List {
                ForEach(playerManager.players) { player in
                    PlayerRowViewBeta(player: player)
                        // Trailing swipe actions for Delete and Edit remain.
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            // Delete Action
                            Button(role: .destructive) {
                                if let index = playerManager.players.firstIndex(where: { $0.id == player.id }) {
                                    playerManager.deletePlayer(at: IndexSet(integer: index))
                                }
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                            
                            // Edit Action
                            Button {
                                selectedPlayerForEdit = player
                            } label: {
                                Label("Edit", systemImage: "pencil")
                            }
                            .tint(.blue)
                        }
                        // Leading swipe action only if the player is not in session.
                        .swipeActions(edge: .leading, allowsFullSwipe: false) {
                            if player.status == .notInSession {
                                Button {
                                    playerManager.movePlayerToWaitlist(player)
                                } label: {
                                    Label("Waitlist", systemImage: "list.bullet")
                                }
                                .tint(.orange)
                            }
                        }
                }
                .onDelete { offsets in
                    playerManager.deletePlayer(at: offsets)
                }
            }
            .navigationTitle("All Players")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showAddPlayerSheet.toggle()
                    }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showAddPlayerSheet) {
                AddPlayerViewBeta()
                    .environmentObject(playerManager)
            }
            // Present the edit sheet when a player is selected.
            .sheet(item: $selectedPlayerForEdit) { player in
                EditPlayerViewBeta(player: player)
                    .environmentObject(playerManager)
            }
            .onAppear {
                playerManager.fetchPlayers()
            }
        }
    }
}

struct PlayerRowViewBeta: View {
    let player: PlayerBeta
    
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
