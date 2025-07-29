import SwiftUI
import SwiftData
import AppKit

struct ResultsView: View {
    let session: Session

    @EnvironmentObject var resultsManager: ResultsManager

    // MARK: - Computed Properties (Delegated to the Manager)
    
    private var totalRedScore: Int {
        resultsManager.totalRedScore(for: session)
    }

    private var totalBlackScore: Int {
        resultsManager.totalBlackScore(for: session)
    }

    private var participantScores: [(String, Int)] {
        resultsManager.participantScores(for: session)
    }

    // MARK: - Display Content (Interactive View)
    
    private var displayContent: some View {
        VStack(spacing: 20) {
            // Team Scores Section
            VStack {
                Text("Team Scores")
                    .font(.headline)
                    .padding(.vertical)
                HStack {
                    VStack {
                        Text("Red Team")
                            .font(.subheadline)
                        Text("\(totalRedScore)")
                            .font(.title)
                            .foregroundColor(.red)
                    }
                    Spacer()
                    VStack {
                        Text("Black Team")
                            .font(.subheadline)
                        Text("\(totalBlackScore)")
                            .font(.title)
                            .foregroundColor(.black)
                    }
                }
                .padding()
            }
            .background(Color(NSColor.windowBackgroundColor))
            .cornerRadius(10)
            .padding(.horizontal)
            
            // Player Net Contributions Section
            VStack(alignment: .leading) {
                Text("Player's Net Score Differences")
                    .font(.headline)
                    .padding(.bottom, 10)
                // Use LazyVStack if you have many rows
                LazyVStack(alignment: .leading, spacing: 10) {
                    ForEach(participantScores, id: \.0) { (name, score) in
                        SessionResultsRowView(playerName: name, playerScore: score)
                    }
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical)
    }

    // MARK: - Body
    var body: some View {
        ScrollView {
            displayContent
        }
        .navigationTitle("Results")
        .onAppear {
            resultsManager.refreshData()
        }
    }
}

// MARK: - SessionResultsRowView

struct SessionResultsRowView: View {
    var playerName: String
    var playerScore: Int

    var body: some View {
        HStack {
            Text(playerName)
                .frame(maxWidth: .infinity, alignment: .leading)
            Text("\(playerScore) points")
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .padding(.vertical, 5)
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

        // Create Season & Session.
        let season = Season(seasonNumber: 4)
        let session = Session(sessionNumber: 5, season: season)
        context.insert(season)
        context.insert(session)

        // Create Players.
        let playerNames = ["Shin", "Suan Sian Foo", "Chris Fan", "CJ", "Nicson Hiew", "Issac Lai"]
        let players = playerNames.map { Player(name: $0) }
        players.forEach { context.insert($0) }

        // Create SessionParticipants and assign teams.
        let teams: [Team] = [.Black, .Black, .Red, .Red, .Black, .Red]
        let participants = zip(players, teams).map { SessionParticipant(session: session, player: $0.0, team: $0.1) }
        participants.forEach { context.insert($0) }

        // Create DoublesMatches.
        let match1 = DoublesMatch(
            session: session,
            waveNumber: 1,
            redPlayer1: players[0],
            redPlayer2: players[1],
            blackPlayer1: players[2],
            blackPlayer2: players[3],
            redTeamScoreFirstSet: 21,
            blackTeamScoreFirstSet: 15,
            redTeamScoreSecondSet: 21,
            blackTeamScoreSecondSet: 15,
            isComplete: true
        )
        let match2 = DoublesMatch(
            session: session,
            waveNumber: 1,
            redPlayer1: players[4],
            redPlayer2: players[5],
            blackPlayer1: players[2],
            blackPlayer2: players[3],
            isComplete: false
        )
        let match3 = DoublesMatch(
            session: session,
            waveNumber: 2,
            redPlayer1: players[1],
            redPlayer2: players[0],
            blackPlayer1: players[2],
            blackPlayer2: players[3],
            redTeamScoreFirstSet: 18,
            blackTeamScoreFirstSet: 22,
            isComplete: true
        )
        [match1, match2, match3].forEach { context.insert($0) }

        try? context.save()

        // Initialize the ResultsManager.
        let resultsManager = ResultsManager(modelContext: context)

        return ResultsView(session: session)
            .environmentObject(resultsManager)
            .modelContainer(container)
    } catch {
        fatalError("Preview setup failed: \(error)")
    }
}
