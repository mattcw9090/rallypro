import SwiftUI
import SwiftData

struct AllPlayersView: View {
    @EnvironmentObject var playerManager: PlayerManager
    @State private var showingAddPlayerSheet = false
    @State private var selectedPlayerForEditing: Player?
    @State private var searchText = ""
    @State private var showingDeleteError = false
    @State private var deleteErrorMessage = ""

    private let columns = [
        GridItem(.adaptive(minimum: 200), spacing: 16)
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 16) {
                    ForEach(playerManager.searchPlayers(searchText: searchText)) { player in
                        PlayerCardView(player: player)
                            .onTapGesture { selectedPlayerForEditing = player }
                            .contextMenu { contextMenu(for: player) }
                    }
                }
                .padding()
            }
            .alert("Error", isPresented: $showingDeleteError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(deleteErrorMessage)
            }
            .searchable(text: $searchText)
            .navigationTitle("All Players")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(action: { showingAddPlayerSheet = true }) {
                        Label("Add Player", systemImage: "plus")
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            .sheet(isPresented: $showingAddPlayerSheet) {
                AddPlayerView()
            }
            .sheet(item: $selectedPlayerForEditing) { player in
                EditPlayerView(player: player)
            }
            .onAppear { playerManager.fetchAllPlayers() }
        }
    }

    @ViewBuilder
    private func contextMenu(for player: Player) -> some View {
        if player.status == .notInSession {
            Button { playerManager.addNewPlayerToWaitlist(player) } label: {
                Label("Add to Waitlist", systemImage: "list.bullet")
            }
        }

        Button(role: .destructive) {
            do {
                try playerManager.deletePlayer(player)
            } catch {
                deleteErrorMessage = error.localizedDescription
                showingDeleteError = true
            }
        } label: {
            Label("Delete Player", systemImage: "trash")
        }
    }
}

struct PlayerCardView: View {
    let player: Player

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "person.crop.circle")
                .resizable()
                .scaledToFit()
                .frame(width: 60, height: 60)
                .foregroundColor(player.isMale ?? true ? .blue : .pink)

            Text(player.name)
                .font(.headline)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.75)

            Text(player.status.rawValue)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(.ultraThinMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(.secondary.opacity(0.2), lineWidth: 1)
        )
        .aspectRatio(1, contentMode: .fit)
    }
}
