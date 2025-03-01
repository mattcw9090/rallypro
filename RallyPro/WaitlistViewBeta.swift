import SwiftUI

struct WaitlistViewBeta: View {
    @EnvironmentObject var playerManager: PlayerManagerBeta
    @EnvironmentObject var teamsManager: TeamsManagerBeta  // Injected instance

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
                        // Existing trailing swipe action: Restore to notInSession.
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button {
                                var updatedPlayer = player
                                updatedPlayer.status = .notInSession
                                playerManager.updatePlayer(updatedPlayer)
                            } label: {
                                Label("Restore", systemImage: "arrow.uturn.left")
                            }
                            .tint(.green)
                        }
                        // New leading swipe action: Move player into the latest session.
                        .swipeActions(edge: .leading, allowsFullSwipe: false) {
                            Button {
                                // Update the player's status to "Currently Playing"
                                var updatedPlayer = player
                                updatedPlayer.status = .playing
                                playerManager.updatePlayer(updatedPlayer)
                                
                                // Now fetch the latest session from the latest season (using our new subcollection approach).
                                teamsManager.getLatestSession { latestSession in
                                    if let session = latestSession {
                                        teamsManager.addParticipant(for: session.id,
                                                                     player: updatedPlayer,
                                                                     team: nil) { error in
                                            if let error = error {
                                                print("Error adding session participant: \(error.localizedDescription)")
                                            } else {
                                                print("Player \(updatedPlayer.name) added to session \(session.sessionNumber)")
                                            }
                                        }
                                    } else {
                                        print("No latest session found. Cannot add participant.")
                                    }
                                }
                            } label: {
                                Text("Join Latest Session")
                            }
                            .tint(.blue)
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
