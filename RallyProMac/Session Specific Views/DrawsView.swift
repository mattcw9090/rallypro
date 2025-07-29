import SwiftUI
import SwiftData

struct DrawsView: View {
    let session: Session

    // Inject the DrawsManager via the environment.
    @EnvironmentObject var drawsManager: DrawsManager
    @Environment(\.modelContext) private var modelContext

    @State private var isEditingPlayers = false

    // Computed properties using in‑memory filtering provided by the manager.
    private var filteredMatches: [DoublesMatch] {
        drawsManager.doublesMatches(for: session)
    }
    
    private var participants: [SessionParticipant] {
        drawsManager.participants(for: session)
    }
    
    private var redTeamMembers: [Player] {
        drawsManager.redTeamMembers(for: session)
    }
    
    private var blackTeamMembers: [Player] {
        drawsManager.blackTeamMembers(for: session)
    }
    
    private var maxWaveNumber: Int {
        drawsManager.maxWaveNumber(for: session)
    }
    
    /// This is the interactive (display) content.
    private var displayContent: some View {
        let groupedMatches = Dictionary(grouping: filteredMatches, by: { $0.waveNumber })
        return VStack(spacing: 16) {
            ForEach(groupedMatches.keys.sorted(), id: \.self) { wave in
                if let matches = groupedMatches[wave] {
                    WaveView(
                        title: "Wave \(wave)",
                        matches: matches,
                        isEditingPlayers: isEditingPlayers,
                        redTeamMembers: redTeamMembers,
                        blackTeamMembers: blackTeamMembers,
                        addMatchAction: {
                            drawsManager.addMatch(for: session, wave: wave)
                        },
                        deleteMatchAction: { match in
                            drawsManager.deleteMatch(match, for: session)
                        }
                    )
                    .padding(.horizontal)
                }
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                // The interactive content is wrapped in a ScrollView.
                ScrollView {
                    displayContent
                }
            }
            .navigationTitle("Draws")
            .toolbar {
                Button(isEditingPlayers ? "Done" : "Edit") {
                    if isEditingPlayers {
                        try? modelContext.save()
                    }
                    withAnimation {
                        isEditingPlayers.toggle()
                    }
                }

                if isEditingPlayers {
                    Button("Add Wave") {
                        drawsManager.addWave(for: session)
                    }
                }
            }
        }
    }
}

// MARK: - WaveView

struct WaveView: View {
    let title: String
    let matches: [DoublesMatch]
    
    // Passed down from DrawsView.
    let isEditingPlayers: Bool
    
    let redTeamMembers: [Player]
    let blackTeamMembers: [Player]
    
    // Handler for adding a match in this wave.
    let addMatchAction: () -> Void
    // Handler for deleting a match.
    let deleteMatchAction: (DoublesMatch) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(title)
                    .font(.headline)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                
                Spacer()
                
                if isEditingPlayers {
                    Button(action: addMatchAction) {
                        Text("Add Match")
                            .font(.subheadline)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.blue.opacity(0.15))
                            .cornerRadius(6)
                    }
                    .transition(.opacity)
                }
            }
            
            VStack(spacing: 12) {
                ForEach(matches, id: \.id) { match in
                    MatchView(
                        match: match,
                        isEditingPlayers: isEditingPlayers,
                        redTeamMembers: redTeamMembers,
                        blackTeamMembers: blackTeamMembers,
                        deleteMatchAction: deleteMatchAction
                    )
                }
            }
            .padding(8)
            .background(Color.gray.opacity(0.1))
            .cornerRadius(8)
        }
    }
}

// MARK: - MatchView

struct MatchView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var match: DoublesMatch
    
    @FocusState private var activeScoreField: ScoreField?
    
    private enum ScoreField {
        case redFirst, blackFirst, redSecond, blackSecond
    }
    
    let isEditingPlayers: Bool
    
    let redTeamMembers: [Player]
    let blackTeamMembers: [Player]
    
    // Callback to delete the match.
    let deleteMatchAction: (DoublesMatch) -> Void
    
    // Local states for score input.
    @State private var redFirstSetScore = ""
    @State private var blackFirstSetScore = ""
    @State private var redSecondSetScore = ""
    @State private var blackSecondSetScore = ""
    
    // Alert state.
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            matchHeader
            
            if isEditingPlayers {
                scoreInputView
            } else if match.isComplete {
                Text("Score: \(matchScore)")
                    .font(.subheadline)
            }
        }
        .padding()
        .background(match.isComplete ? winningTeamColor : Color.clear)
        .cornerRadius(8)
        .shadow(radius: 2)
        .onAppear {
            initializeScores()
        }
        .alert(isPresented: $showingAlert) {
            Alert(
                title: Text("Error"),
                message: Text(alertMessage),
                dismissButton: .default(Text("OK"))
            )
        }
    }
}

// MARK: - MatchView Subviews & Helpers

extension MatchView {
    private var matchHeader: some View {
        HStack {
            // Red team (two players)
            VStack(alignment: .leading, spacing: 6) {
                teamPlayerNameView(
                    currentPlayer: match.redPlayer1,
                    team: .Red,
                    updateAction: { newPlayer in updateRedPlayer1(to: newPlayer) }
                )
                teamPlayerNameView(
                    currentPlayer: match.redPlayer2,
                    team: .Red,
                    updateAction: { newPlayer in updateRedPlayer2(to: newPlayer) }
                )
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            Text("vs")
                .bold()
            
            // Black team (two players)
            VStack(alignment: .trailing, spacing: 6) {
                teamPlayerNameView(
                    currentPlayer: match.blackPlayer1,
                    team: .Black,
                    updateAction: { newPlayer in updateBlackPlayer1(to: newPlayer) }
                )
                teamPlayerNameView(
                    currentPlayer: match.blackPlayer2,
                    team: .Black,
                    updateAction: { newPlayer in updateBlackPlayer2(to: newPlayer) }
                )
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
            
            if isEditingPlayers {
                Button(role: .destructive) {
                    deleteMatchAction(match)
                } label: {
                    Image(systemName: "trash")
                        .foregroundColor(.red)
                }
                .padding(.leading, 8)
            }
        }
        .padding(.vertical, 4)
    }
    
    private func teamPlayerNameView(
        currentPlayer: Player,
        team: Team,
        updateAction: @escaping (Player) -> Void
    ) -> some View {
        let relevantTeamMembers = (team == .Red) ? redTeamMembers : blackTeamMembers
        return Group {
            if isEditingPlayers {
                Menu {
                    ForEach(relevantTeamMembers, id: \.id) { player in
                        Button(player.name) {
                            updateAction(player)
                        }
                    }
                } label: {
                    Text(currentPlayer.name)
                        .underline()
                        .foregroundColor(team == .Red ? .red : .black)
                }
            } else {
                Text(currentPlayer.name)
                    .foregroundColor(team == .Red ? .red : .black)
            }
        }
    }
    
    @ViewBuilder
    private var scoreInputView: some View {
        HStack(spacing: 16) {
            // Set 1
            VStack(spacing: 4) {
                Text("Set 1")
                    .font(.caption)
                HStack(spacing: 4) {
                    TextField("R", text: $redFirstSetScore)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 40)
                        .focused($activeScoreField, equals: .redFirst)
                    
                    Text("-")
                    
                    TextField("B", text: $blackFirstSetScore)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 40)
                        .focused($activeScoreField, equals: .blackFirst)
                }
            }
            
            // Set 2
            VStack(spacing: 4) {
                Text("Set 2")
                    .font(.caption)
                HStack(spacing: 4) {
                    TextField("R", text: $redSecondSetScore)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 40)
                        .focused($activeScoreField, equals: .redSecond)
                    
                    Text("-")
                    
                    TextField("B", text: $blackSecondSetScore)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 40)
                        .focused($activeScoreField, equals: .blackSecond)
                }
            }
            
            Spacer()
        }
        .padding(.top, 4)
    }
    
    private func initializeScores() {
        if match.redTeamScoreFirstSet != 0 || match.blackTeamScoreFirstSet != 0 {
            redFirstSetScore = "\(match.redTeamScoreFirstSet)"
            blackFirstSetScore = "\(match.blackTeamScoreFirstSet)"
        }
        if match.redTeamScoreSecondSet != 0 || match.blackTeamScoreSecondSet != 0 {
            redSecondSetScore = "\(match.redTeamScoreSecondSet)"
            blackSecondSetScore = "\(match.blackTeamScoreSecondSet)"
        }
    }
    
    private func updateScoreFields() {
        match.redTeamScoreFirstSet = Int(redFirstSetScore) ?? 0
        match.blackTeamScoreFirstSet = Int(blackFirstSetScore) ?? 0
        match.redTeamScoreSecondSet = Int(redSecondSetScore) ?? 0
        match.blackTeamScoreSecondSet = Int(blackSecondSetScore) ?? 0
        
        let set1Complete = (!redFirstSetScore.isEmpty && !blackFirstSetScore.isEmpty)
        let set2Complete = (!redSecondSetScore.isEmpty && !blackSecondSetScore.isEmpty)
        match.isComplete = set1Complete && set2Complete
    }
    
    private func updateRedPlayer1(to newPlayer: Player) {
        do {
            match.redPlayer1 = newPlayer
            try modelContext.save()
        } catch {
            alertMessage = "Failed to save player selection: \(error.localizedDescription)"
            showingAlert = true
        }
    }
    
    private func updateRedPlayer2(to newPlayer: Player) {
        do {
            match.redPlayer2 = newPlayer
            try modelContext.save()
        } catch {
            alertMessage = "Failed to save player selection: \(error.localizedDescription)"
            showingAlert = true
        }
    }
    
    private func updateBlackPlayer1(to newPlayer: Player) {
        do {
            match.blackPlayer1 = newPlayer
            try modelContext.save()
        } catch {
            alertMessage = "Failed to save player selection: \(error.localizedDescription)"
            showingAlert = true
        }
    }
    
    private func updateBlackPlayer2(to newPlayer: Player) {
        do {
            match.blackPlayer2 = newPlayer
            try modelContext.save()
        } catch {
            alertMessage = "Failed to save player selection: \(error.localizedDescription)"
            showingAlert = true
        }
    }
    
    private var winningTeam: Team? {
        let redTotal = match.redTeamScoreFirstSet + match.redTeamScoreSecondSet
        let blackTotal = match.blackTeamScoreFirstSet + match.blackTeamScoreSecondSet
        if redTotal > blackTotal { return .Red }
        else if blackTotal > redTotal { return .Black }
        else { return nil }
    }
    
    private var winningTeamColor: Color {
        switch winningTeam {
        case .Red:
            return Color.red.opacity(0.2)
        case .Black:
            return Color.black.opacity(0.2)
        case .none:
            return Color.clear
        }
    }
    
    private var matchScore: String {
        "\(match.redTeamScoreFirstSet)-\(match.blackTeamScoreFirstSet), " +
        "\(match.redTeamScoreSecondSet)-\(match.blackTeamScoreSecondSet)"
    }
}

#Preview {
    let schema = Schema([Season.self, Session.self, Player.self, SessionParticipant.self, DoublesMatch.self])
    let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
    
    do {
        let container = try ModelContainer(for: schema, configurations: config)
        let context = container.mainContext
        
        // Create mock Season and Session.
        let season = Season(seasonNumber: 4)
        context.insert(season)
        let session = Session(sessionNumber: 5, season: season)
        context.insert(session)
        
        // Create some Players.
        let playerNames = ["Shin", "Suan Sian Foo", "Chris Fan", "CJ", "Nicson", "Issac"]
        let players = playerNames.map { Player(name: $0) }
        players.forEach { context.insert($0) }
        
        // Create SessionParticipants.
        let participant1 = SessionParticipant(session: session, player: players[0], team: .Red)
        let participant2 = SessionParticipant(session: session, player: players[1], team: .Red)
        let participant3 = SessionParticipant(session: session, player: players[2], team: .Black)
        let participant4 = SessionParticipant(session: session, player: players[3], team: .Black)
        let participant5 = SessionParticipant(session: session, player: players[4], team: .Red)
        let participant6 = SessionParticipant(session: session, player: players[5], team: .Black)
        [participant1, participant2, participant3, participant4, participant5, participant6].forEach { context.insert($0) }
        
        // Create some mock matches.
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
            redPlayer2: players[1],
            blackPlayer1: players[3],
            blackPlayer2: players[5]
        )
        let match3 = DoublesMatch(
            session: session,
            waveNumber: 2,
            redPlayer1: players[0],
            redPlayer2: players[4],
            blackPlayer1: players[2],
            blackPlayer2: players[3],
            redTeamScoreFirstSet: 18,
            blackTeamScoreFirstSet: 21
        )
        [match1, match2, match3].forEach { context.insert($0) }
        
        try? context.save()
        
        // Initialize the DrawsManager.
        let drawsManager = DrawsManager(modelContext: context)
        
        return DrawsView(session: session)
            .environmentObject(drawsManager)
            .modelContainer(container)
    } catch {
        fatalError("Failed to create preview container: \(error)")
    }
}
