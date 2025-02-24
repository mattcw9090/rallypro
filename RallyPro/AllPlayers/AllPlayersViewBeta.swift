import SwiftUI

struct AllPlayersViewBeta: View {
    @EnvironmentObject var playerManager: PlayerManagerBeta
    @State private var showAddPlayerSheet = false

    var body: some View {
        NavigationView {
            List(playerManager.players) { player in
                PlayerRowViewBeta(player: player)
            }
            .navigationTitle("All Players")
            .toolbar {
                Button(action: {
                    showAddPlayerSheet.toggle()
                }) {
                    Image(systemName: "plus")
                }
            }
            .sheet(isPresented: $showAddPlayerSheet) {
                AddPlayerViewBeta()
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
