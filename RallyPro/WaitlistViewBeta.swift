import SwiftUI

struct WaitlistViewBeta: View {
    @EnvironmentObject var playerManager: PlayerManagerBeta

    // Filter players with status 'onWaitlist' and sort by waitlistPosition.
    var waitlistPlayers: [PlayerBeta] {
        playerManager.players
            .filter { $0.status == .onWaitlist }
            .sorted { ($0.waitlistPosition ?? Int.max) < ($1.waitlistPosition ?? Int.max) }
    }

    var body: some View {
        NavigationView {
            List {
                ForEach(waitlistPlayers) { player in
                    WaitlistRowViewBeta(player: player)
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button {
                                // Update the player's status to not in session.
                                var updatedPlayer = player
                                updatedPlayer.status = .notInSession
                                // updatePlayer will clear waitlistPosition and reorder the remaining waitlisted players.
                                playerManager.updatePlayer(updatedPlayer)
                            } label: {
                                Label("Restore", systemImage: "arrow.uturn.left")
                            }
                            .tint(.green)
                        }
                }
            }
            .navigationTitle("Waitlist")
        }
    }
}

struct WaitlistRowViewBeta: View {
    let player: PlayerBeta

    var body: some View {
        HStack {
            // Display the waitlist position number, if available.
            if let position = player.waitlistPosition {
                Text("\(position)")
                    .font(.headline)
                    .frame(width: 30, alignment: .center)
            } else {
                Text("-")
                    .font(.headline)
                    .frame(width: 30, alignment: .center)
            }
            
            // Display player's name.
            Text(player.name)
                .font(.body)
        }
    }
}
