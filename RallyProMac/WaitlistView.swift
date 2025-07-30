import SwiftUI
import SwiftData

struct WaitlistView: View {
    @EnvironmentObject var playerManager: PlayerManager
    @EnvironmentObject var seasonManager: SeasonSessionManager

    @State private var showingAlert = false
    @State private var alertMessage = ""

    var body: some View {
        NavigationStack {
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
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .padding(.vertical, 5)
                    .contextMenu {
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

                        Divider()

                        Button(role: .destructive) {
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
        .frame(minWidth: 300, minHeight: 400)
        .alert("Operation Failed", isPresented: $showingAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(alertMessage)
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
