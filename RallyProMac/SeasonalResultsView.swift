import SwiftUI
import SwiftData
import AppKit

struct SeasonalResultsView: View {
    @EnvironmentObject var seasonalResultsManager: SeasonalResultsManager
    let seasonNumber: Int
    
    // Track hidden players by their IDs.
    @State private var hiddenPlayerIDs: Set<UUID> = []
    
    // Base aggregated results from the manager.
    private var aggregatedResults: [(player: Player, sessionCount: Int, matchCount: Int, finalAverageScore: Double)] {
        seasonalResultsManager.aggregatedPlayers(forSeasonNumber: seasonNumber)
    }
    
    // Filter out any players that have been hidden.
    private var filteredResults: [(player: Player, sessionCount: Int, matchCount: Int, finalAverageScore: Double)] {
        aggregatedResults.filter { !hiddenPlayerIDs.contains($0.player.id) }
    }
    
    // ----------------------------------------------------
    // displayContent: The interactive view using a List.
    // ----------------------------------------------------
    private var displayContent: some View {
        // Pre-compute the filtered results and determine min/max scores.
        let results = filteredResults
        let scores = results.map { $0.finalAverageScore }
        let minScore = scores.min() ?? 0
        let maxScore = scores.max() ?? 1
        
        return List {
            // Header Row.
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
            
            // Aggregated player results with a swipe-to-hide action.
            ForEach(results, id: \.player.id) { item in
                // Normalize finalAverageScore to a fraction between 0 (red) and 1 (green).
                let fraction: Double = (maxScore > minScore)
                    ? (item.finalAverageScore - minScore) / (maxScore - minScore)
                    : 0.5
                let rowColor = Color(red: 1 - fraction, green: fraction, blue: 0).opacity(0.3)
                
                HStack {
                    Text(item.player.name)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Text("\(item.sessionCount)")
                        .frame(width: 80, alignment: .trailing)
                    Text(String(format: "%.1f", item.finalAverageScore))
                        .frame(width: 80, alignment: .trailing)
                }
                .padding(.vertical, 5)
                .listRowBackground(rowColor)
                .contextMenu {
                    Button(role: .destructive) {
                        // Hide this player.
                        hiddenPlayerIDs.insert(item.player.id)
                    } label: {
                        Label("Hide", systemImage: "eye.slash")
                    }
                }
            }
        }
        .listStyle(.inset)
    }
    
    // ----------------------------------------------------
    // Main Body
    // ----------------------------------------------------
    var body: some View {
        NavigationStack {
            displayContent
                .navigationTitle("Season \(seasonNumber) Results")
                .toolbar {
                    if !hiddenPlayerIDs.isEmpty {
                        Button("Show All") {
                            hiddenPlayerIDs.removeAll()
                        }
                    }
                }
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

        // Create Season.
        let season = Season(seasonNumber: 4)
        context.insert(season)

        // Create Sessions.
        let sessions = (1...2).map { Session(sessionNumber: $0, season: season) }
        sessions.forEach { context.insert($0) }

        // Create Players.
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

        // Create DoublesMatches.
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
