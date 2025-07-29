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
                        .contextMenu {
                            contextMenu(for: player)
                        }
                        .onTapGesture {
                            selectedPlayerForEditing = player
                        }
                }
            }
            .navigationTitle("All Players")
            .searchable(text: $searchText)
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
    private func contextMenu(for player: Player) -> some View {
        if player.status == .notInSession {
            Button {
                playerManager.addNewPlayerToWaitlist(player)
            } label: {
                Label("Add to Waitlist", systemImage: "list.bullet")
            }
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
