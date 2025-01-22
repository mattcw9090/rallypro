import SwiftUI
import SwiftData

struct DrawsView: View {
    let session: Session

    @Query private var allDoublesMatches: [DoublesMatch]
    @Query private var allParticipants: [SessionParticipant]

    // Global editing toggle
    @State private var isEditingPlayers = false

    @Environment(\.modelContext) private var modelContext

    private var participants: [SessionParticipant] {
        allParticipants.filter { $0.session == session }
    }

    // Build red/black player arrays
    private var redTeamMembers: [Player] {
        participants.filter { $0.team == .Red }.map { $0.player }
    }
    private var blackTeamMembers: [Player] {
        participants.filter { $0.team == .Black }.map { $0.player }
    }

    // Calculate the current max wave
    private var maxWaveNumber: Int {
        allDoublesMatches
            .filter { $0.session == session }
            .map { $0.waveNumber }
            .max() ?? 0
    }

    var body: some View {
        NavigationView {
            let filteredMatches = allDoublesMatches.filter { $0.session == session }
            // Group matches by wave number
            let groupedMatches = Dictionary(grouping: filteredMatches, by: { $0.waveNumber })

            ScrollView {
                LazyVStack(spacing: 16) {
                    ForEach(groupedMatches.keys.sorted(), id: \.self) { wave in
                        if let matches = groupedMatches[wave] {
                            WaveView(
                                title: "Wave \(wave)",
                                matches: matches,
                                isEditingPlayers: isEditingPlayers,
                                redTeamMembers: redTeamMembers,
                                blackTeamMembers: blackTeamMembers,
                                addMatchAction: {
                                    addMatch(for: wave)
                                },
                                deleteMatchAction: { match in
                                    deleteMatch(match)
                                }
                            )
                            .padding(.horizontal)
                        }
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("Draws")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(isEditingPlayers ? "Done" : "Edit") {
                        if isEditingPlayers {
                            // Save changes before leaving edit mode
                            try? modelContext.save()
                        }
                        withAnimation {
                            isEditingPlayers.toggle()
                        }
                    }
                }

                // Add Wave button on the right (only in edit mode)
                ToolbarItem(placement: .navigationBarTrailing) {
                    if isEditingPlayers {
                        Button("Add Wave") {
                            addWave()
                        }
                    }
                }
            }
        }
    }

    // MARK: - Adding Waves & Matches

    /// Creates a new wave with waveNumber = maxWaveNumber + 1, plus one empty match.
    private func addWave() {
        let newWaveNumber = maxWaveNumber + 1

        let newMatch = DoublesMatch(
            session: session,
            waveNumber: newWaveNumber,
            redPlayer1: redTeamMembers.first ?? Player(name: "Red Player A"),
            redPlayer2: redTeamMembers.dropFirst().first ?? Player(name: "Red Player B"),
            blackPlayer1: blackTeamMembers.first ?? Player(name: "Black Player A"),
            blackPlayer2: blackTeamMembers.dropFirst().first ?? Player(name: "Black Player B")
        )
        modelContext.insert(newMatch)

        do {
            try modelContext.save()
        } catch {
            print("Error adding new wave: \(error.localizedDescription)")
        }
    }

    /// Creates a new match within an existing wave.
    private func addMatch(for wave: Int) {
        let newMatch = DoublesMatch(
            session: session,
            waveNumber: wave,
            redPlayer1: redTeamMembers.first ?? Player(name: "Red Player A"),
            redPlayer2: redTeamMembers.dropFirst().first ?? Player(name: "Red Player B"),
            blackPlayer1: blackTeamMembers.first ?? Player(name: "Black Player A"),
            blackPlayer2: blackTeamMembers.dropFirst().first ?? Player(name: "Black Player B")
        )
        modelContext.insert(newMatch)

        do {
            try modelContext.save()
        } catch {
            print("Error adding new match: \(error.localizedDescription)")
        }
    }

    // MARK: - Deleting Matches & Reordering Waves

    /// Delete the given match, then shift wave numbers if that wave is now empty.
    private func deleteMatch(_ match: DoublesMatch) {
        let deletedWaveNumber = match.waveNumber

        modelContext.delete(match)
        do {
            try modelContext.save()
        } catch {
            print("Error deleting match: \(error.localizedDescription)")
        }

        reorderWavesAfterDeletingWaveIfNeeded(deletedWaveNumber)
    }

    /// If the wave is empty after deletion, shift all wave numbers above it by -1.
    private func reorderWavesAfterDeletingWaveIfNeeded(_ wave: Int) {
        // Check if wave is now empty
        let isWaveEmpty = !allDoublesMatches.contains { $0.session == session && $0.waveNumber == wave }
        guard isWaveEmpty else { return }

        // Wave is empty -> shift subsequent waves downward
        let matchesToShift = allDoublesMatches.filter {
            $0.session == session && $0.waveNumber > wave
        }
        for match in matchesToShift {
            match.waveNumber -= 1
        }
        do {
            try modelContext.save()
        } catch {
            print("Error shifting wave numbers: \(error.localizedDescription)")
        }
    }
}

// MARK: - WaveView

struct WaveView: View {
    let title: String
    let matches: [DoublesMatch]

    // Passed down from DrawsView
    let isEditingPlayers: Bool

    let redTeamMembers: [Player]
    let blackTeamMembers: [Player]

    // Handler for adding a match in this wave
    let addMatchAction: () -> Void
    // Handler for deleting a match in this wave
    let deleteMatchAction: (DoublesMatch) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(title)
                    .font(.headline)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)

                Spacer()

                // Show "Add Match" button inline if editing
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

    // Callback up to the parent to handle deletion
    let deleteMatchAction: (DoublesMatch) -> Void

    // Score states
    @State private var redFirstSetScore = ""
    @State private var blackFirstSetScore = ""
    @State private var redSecondSetScore = ""
    @State private var blackSecondSetScore = ""

    // Alert
    @State private var showingAlert = false
    @State private var alertMessage = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            matchHeader

            // If we're in editing mode, always show the score input, regardless of match completion.
            // Otherwise, if the match is complete, show final inline score.
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

// MARK: - Subviews & Private Helpers

extension MatchView {
    /// The row showing the two red players vs. two black players, plus a delete button (in edit mode).
    private var matchHeader: some View {
        HStack {
            // Red side (two players)
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

            // Black side (two players)
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

            // Delete button on the far right if editing
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

    /// A helper that shows either a plain text or a menu for editing a player's name.
    /// If `team == .Red`, it will show redTeamMembers; if `.Black`, blackTeamMembers.
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
                        .underline() // visually indicate it's editable
                        .foregroundColor(team == .Red ? .red : .black)
                }
            } else {
                Text(currentPlayer.name)
                    .foregroundColor(team == .Red ? .red : .black)
            }
        }
    }

    /// Score Input (compact layout)
    @ViewBuilder
    private var scoreInputView: some View {
        HStack(spacing: 16) {
            // ----- SET 1 -----
            VStack(spacing: 4) {
                Text("Set 1")
                    .font(.caption)
                
                HStack(spacing: 4) {
                    // Red first-set score
                    TextField("R", text: $redFirstSetScore)
                        .keyboardType(.numberPad)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 40)
                        .focused($activeScoreField, equals: .redFirst)
                        .onChange(of: redFirstSetScore) { oldValue, newValue in
                            // 1) Enforce max 2 digits
                            if newValue.count > 2 {
                                redFirstSetScore = String(newValue.prefix(2))
                            }
                            // 2) Move focus when we have exactly 2 digits
                            if redFirstSetScore.count == 2 {
                                activeScoreField = .blackFirst
                            }
                            // 3) Update underlying model
                            updateScoreFields()
                        }
                    
                    Text("-")
                    
                    // Black first-set score
                    TextField("B", text: $blackFirstSetScore)
                        .keyboardType(.numberPad)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 40)
                        .focused($activeScoreField, equals: .blackFirst)
                        .onChange(of: blackFirstSetScore) { oldValue, newValue in
                            if newValue.count > 2 {
                                blackFirstSetScore = String(newValue.prefix(2))
                            }
                            if blackFirstSetScore.count == 2 {
                                activeScoreField = .redSecond
                            }
                            updateScoreFields()
                        }
                }
            }

            // ----- SET 2 -----
            VStack(spacing: 4) {
                Text("Set 2")
                    .font(.caption)
                
                HStack(spacing: 4) {
                    // Red second-set score
                    TextField("R", text: $redSecondSetScore)
                        .keyboardType(.numberPad)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 40)
                        .focused($activeScoreField, equals: .redSecond)
                        .onChange(of: redSecondSetScore) { oldValue, newValue in
                            if newValue.count > 2 {
                                redSecondSetScore = String(newValue.prefix(2))
                            }
                            if redSecondSetScore.count == 2 {
                                activeScoreField = .blackSecond
                            }
                            updateScoreFields()
                        }

                    Text("-")

                    // Black second-set score
                    TextField("B", text: $blackSecondSetScore)
                        .keyboardType(.numberPad)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 40)
                        .focused($activeScoreField, equals: .blackSecond)
                        .onChange(of: blackSecondSetScore) { oldValue, newValue in
                            if newValue.count > 2 {
                                blackSecondSetScore = String(newValue.prefix(2))
                            }
                            // Optionally dismiss keyboard when final text field is filled:
                            // if blackSecondSetScore.count == 2 {
                            //     activeScoreField = nil
                            // }
                            updateScoreFields()
                        }
                }
            }

            Spacer()
        }
        .padding(.top, 4)
    }
}

// MARK: - Logic & Computed Properties

extension MatchView {
    private func initializeScores() {
        // Populate local text fields from match data
        if match.redTeamScoreFirstSet != 0 || match.blackTeamScoreFirstSet != 0 {
            redFirstSetScore = "\(match.redTeamScoreFirstSet)"
            blackFirstSetScore = "\(match.blackTeamScoreFirstSet)"
        }
        if match.redTeamScoreSecondSet != 0 || match.blackTeamScoreSecondSet != 0 {
            redSecondSetScore = "\(match.redTeamScoreSecondSet)"
            blackSecondSetScore = "\(match.blackTeamScoreSecondSet)"
        }
    }

    /// Called whenever any of the score text fields change.
    private func updateScoreFields() {
        match.redTeamScoreFirstSet   = Int(redFirstSetScore)   ?? 0
        match.blackTeamScoreFirstSet = Int(blackFirstSetScore) ?? 0
        match.redTeamScoreSecondSet  = Int(redSecondSetScore)  ?? 0
        match.blackTeamScoreSecondSet = Int(blackSecondSetScore) ?? 0

        // Mark as complete if both sets have scores
        let set1Complete = (!redFirstSetScore.isEmpty && !blackFirstSetScore.isEmpty)
        let set2Complete = (!redSecondSetScore.isEmpty && !blackSecondSetScore.isEmpty)
        match.isComplete = set1Complete && set2Complete
    }

    /// Update methods for each specific position
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

    private var winningTeam: Team? {
        let redTotal = match.redTeamScoreFirstSet + match.redTeamScoreSecondSet
        let blackTotal = match.blackTeamScoreFirstSet + match.blackTeamScoreSecondSet

        if redTotal > blackTotal {
            return .Red
        } else if blackTotal > redTotal {
            return .Black
        } else {
            return nil
        }
    }

    private var matchScore: String {
        "\(match.redTeamScoreFirstSet)-\(match.blackTeamScoreFirstSet), " +
        "\(match.redTeamScoreSecondSet)-\(match.blackTeamScoreSecondSet)"
    }
}

// MARK: - Preview

#Preview {
    let schema = Schema([
        Season.self,
        Session.self,
        Player.self,
        SessionParticipant.self,
        DoublesMatch.self
    ])
    let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)

    do {
        let mockContainer = try ModelContainer(for: schema, configurations: [modelConfiguration])
        let context = mockContainer.mainContext

        // Create mock data
        let season = Season(seasonNumber: 4)
        context.insert(season)

        let session = Session(sessionNumber: 5, season: season)
        context.insert(session)

        let players = ["Shin", "Suan Sian Foo", "Chris Fan", "CJ", "Nicson Hiew", "Issac Lai"]
            .map { Player(name: $0) }
        players.forEach { context.insert($0) }

        // Mock participants
        let participant1 = SessionParticipant(session: session, player: players[0], team: .Red)
        let participant2 = SessionParticipant(session: session, player: players[1], team: .Red)
        let participant3 = SessionParticipant(session: session, player: players[2], team: .Black)
        let participant4 = SessionParticipant(session: session, player: players[3], team: .Black)
        let participant5 = SessionParticipant(session: session, player: players[4], team: .Red)
        let participant6 = SessionParticipant(session: session, player: players[5], team: .Black)
        [participant1, participant2, participant3, participant4, participant5, participant6].forEach {
            context.insert($0)
        }

        // Example wave 1
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

        // Example wave 2
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

        return DrawsView(session: session)
            .modelContainer(mockContainer)
    } catch {
        fatalError("Could not create ModelContainer: \(error)")
    }
}
