import SwiftUI
import SwiftData

struct SeasonalResultsView: View {
    @EnvironmentObject var seasonalResultsManager: SeasonalResultsManager
    let seasonNumber: Int

    var body: some View {
        NavigationStack {
            List {
                // Header Row
                HStack {
                    Text("Player")
                        .font(.headline)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Text("Sessions")
                        .font(.headline)
                        .frame(width: 80, alignment: .trailing)
                    Text("Avg Score")
                        .font(.headline)
                        .frame(width: 80, alignment: .trailing)
                }
                .padding(.vertical, 10)

                // For each aggregated player result.
                ForEach(seasonalResultsManager.aggregatedPlayers(forSeasonNumber: seasonNumber), id: \.player.id) { item in
                    HStack {
                        Text(item.player.name)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        Text("\(item.sessionCount)")
                            .frame(width: 80, alignment: .trailing)
                        Text(String(format: "%.1f", item.finalAverageScore))
                            .frame(width: 80, alignment: .trailing)
                    }
                    .padding(.vertical, 5)
                }
            }
            .listStyle(InsetGroupedListStyle())
            .navigationTitle("Season \(seasonNumber) Results")
        }
    }
}

#Preview {
    do {
        let schema = Schema([
            Season.self,
            Session.self,
            Player.self,
            SessionParticipant.self,
            DoublesMatch.self
        ])
        let modelConfig = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [modelConfig])
        let context = container.mainContext

        // Create Season
        let season = Season(seasonNumber: 4)
        context.insert(season)

        // Create Sessions
        let sessions = (1...2).map { Session(sessionNumber: $0, season: season) }
        sessions.forEach { context.insert($0) }

        // Create Players
        let playerNames = ["Shin", "Suan", "Chris", "CJ"]
        let players = playerNames.map { Player(name: $0) }
        players.forEach { context.insert($0) }

        // Assign Players to Sessions with teams.
        let teamsSession1: [Team] = [.Black, .Red, .Red, .Black]
        let teamsSession2: [Team] = [.Red, .Red, .Black, .Black]
        let participantsSession1 = zip(players, teamsSession1).map {
            SessionParticipant(session: sessions[0], player: $0.0, team: $0.1)
        }
        let participantsSession2 = zip(players, teamsSession2).map {
            SessionParticipant(session: sessions[1], player: $0.0, team: $0.1)
        }
        (participantsSession1 + participantsSession2).forEach { context.insert($0) }

        // Create DoublesMatches
        let matches = [
            DoublesMatch(
                session: sessions[0],
                waveNumber: 1,
                redPlayer1: players[0],
                redPlayer2: players[1],
                blackPlayer1: players[2],
                blackPlayer2: players[3],
                redTeamScoreFirstSet: 21,
                blackTeamScoreFirstSet: 15,
                redTeamScoreSecondSet: 0,
                blackTeamScoreSecondSet: 0,
                isComplete: true
            ),
            DoublesMatch(
                session: sessions[1],
                waveNumber: 1,
                redPlayer1: players[1],
                redPlayer2: players[0],
                blackPlayer1: players[2],
                blackPlayer2: players[3],
                redTeamScoreFirstSet: 0,
                blackTeamScoreFirstSet: 0,
                redTeamScoreSecondSet: 0,
                blackTeamScoreSecondSet: 0,
                isComplete: false
            ),
            DoublesMatch(
                session: sessions[0],
                waveNumber: 2,
                redPlayer1: players[1],
                redPlayer2: players[0],
                blackPlayer1: players[2],
                blackPlayer2: players[3],
                redTeamScoreFirstSet: 18,
                blackTeamScoreFirstSet: 22,
                redTeamScoreSecondSet: 0,
                blackTeamScoreSecondSet: 0,
                isComplete: true
            )
        ]
        matches.forEach { context.insert($0) }
        
        let seasonManager = SeasonSessionManager(modelContext: context)
        let playerManager = PlayerManager(modelContext: context)
        let seasonalResultsManager = SeasonalResultsManager(modelContext: context)

        return NavigationStack {
            SeasonalResultsView(seasonNumber: 4)
                .modelContainer(container)
                .environmentObject(seasonManager)
                .environmentObject(playerManager)
                .environmentObject(seasonalResultsManager)
        }
    } catch {
        fatalError("Preview setup failed: \(error)")
    }
}
