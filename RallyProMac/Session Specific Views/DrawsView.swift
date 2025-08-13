import SwiftUI
import SwiftData

struct DrawsView: View {
    let session: Session

    @EnvironmentObject var drawsManager: DrawsManager
    @Environment(\.modelContext) private var modelContext

    @State private var isEditingPlayers = false

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
                ScrollView { displayContent }
            }
            .navigationTitle("Draws")
            .toolbar {
                Button(isEditingPlayers ? "Done" : "Edit") {
                    if isEditingPlayers {
                        try? modelContext.save()
                    }
                    withAnimation { isEditingPlayers.toggle() }
                }
                if isEditingPlayers {
                    Button("Add Wave") {
                        drawsManager.addWave(for: session)
                    }
                }
            }
        }
        .onAppear { drawsManager.refreshData() }
        .onChange(of: session.id) { drawsManager.refreshData() }
    }
}

struct WaveView: View {
    let title: String
    let matches: [DoublesMatch]
    let isEditingPlayers: Bool
    let redTeamMembers: [Player]
    let blackTeamMembers: [Player]
    let addMatchAction: () -> Void
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

struct MatchView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var match: DoublesMatch

    @FocusState private var activeScoreField: ScoreField?
    private enum ScoreField { case redFirst, blackFirst, redSecond, blackSecond }

    let isEditingPlayers: Bool
    let redTeamMembers: [Player]
    let blackTeamMembers: [Player]
    let deleteMatchAction: (DoublesMatch) -> Void

    @State private var redFirstSetScore = ""
    @State private var blackFirstSetScore = ""
    @State private var redSecondSetScore = ""
    @State private var blackSecondSetScore = ""

    @State private var showingAlert = false
    @State private var alertMessage = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                matchHeader
                if match.isOngoing && !match.isComplete {
                    Text("ONGOING")
                        .font(.caption2).bold()
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.yellow.opacity(0.6))
                        .cornerRadius(4)
                }
            }
            if isEditingPlayers {
                scoreInputView
            } else if let text = partialScoreText {
                Text("Score: \(text)")
                    .font(.subheadline)
            }
        }
        .padding()
        .background(matchBackground)
        .overlay(ongoingBorder)
        .cornerRadius(8)
        .shadow(radius: 2)
        .onAppear { initializeScores() }
        .alert(isPresented: $showingAlert) {
            Alert(
                title: Text("Error"),
                message: Text(alertMessage),
                dismissButton: .default(Text("OK"))
            )
        }
        .contextMenu {
            Button(match.isOngoing ? "Clear Ongoing" : "Mark Ongoing") { toggleOngoing() }
                .disabled(match.isComplete)
        }
        .onChange(of: match.isComplete) {
            if match.isComplete, match.isOngoing {
                match.isOngoing = false
                do { try modelContext.save() }
                catch {
                    alertMessage = "Failed to update match status: \(error.localizedDescription)"
                    showingAlert = true
                }
            }
        }
    }

    private var matchHeader: some View {
        HStack {
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

            Text("vs").bold()

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
                        Button(player.name) { updateAction(player) }
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
            VStack(spacing: 4) {
                Text("Set 1").font(.caption)
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
            VStack(spacing: 4) {
                Text("Set 2").font(.caption)
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
        .onChange(of: redFirstSetScore)    { handleScoreChange() }
        .onChange(of: blackFirstSetScore)  { handleScoreChange() }
        .onChange(of: redSecondSetScore)   { handleScoreChange() }
        .onChange(of: blackSecondSetScore) { handleScoreChange() }
    }

    private func handleScoreChange() {
        match.redTeamScoreFirstSet    = Int(redFirstSetScore)    ?? 0
        match.blackTeamScoreFirstSet  = Int(blackFirstSetScore)  ?? 0
        match.redTeamScoreSecondSet   = Int(redSecondSetScore)   ?? 0
        match.blackTeamScoreSecondSet = Int(blackSecondSetScore) ?? 0

        let set1Done = !redFirstSetScore.isEmpty && !blackFirstSetScore.isEmpty
        let set2Done = !redSecondSetScore.isEmpty && !blackSecondSetScore.isEmpty
        match.isComplete = set1Done && set2Done

        if match.isComplete { match.isOngoing = false }

        do { try modelContext.save() }
        catch {
            alertMessage = "Failed to save scores: \(error.localizedDescription)"
            showingAlert = true
        }
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

    private var matchBackground: Color {
        if match.isComplete {
            return winningTeamColor
        } else if match.isOngoing {
            return Color.yellow.opacity(0.18)
        } else {
            return Color.clear
        }
    }

    private var ongoingBorder: some View {
        Group {
            if match.isOngoing && !match.isComplete {
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.yellow.opacity(0.7), lineWidth: 2)
            } else {
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.clear, lineWidth: 0)
            }
        }
    }

    private var partialScoreText: String? {
        var pieces: [String] = []
        if match.redTeamScoreFirstSet != 0 || match.blackTeamScoreFirstSet != 0 {
            pieces.append("\(match.redTeamScoreFirstSet)-\(match.blackTeamScoreFirstSet)")
        }
        if match.redTeamScoreSecondSet != 0 || match.blackTeamScoreSecondSet != 0 {
            pieces.append("\(match.redTeamScoreSecondSet)-\(match.blackTeamScoreSecondSet)")
        }
        return pieces.isEmpty ? nil : pieces.joined(separator: ", ")
    }

    private func toggleOngoing() {
        guard !match.isComplete else { return }
        match.isOngoing.toggle()
        do { try modelContext.save() }
        catch {
            alertMessage = "Failed to update match status: \(error.localizedDescription)"
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
        case .Red: return Color.red.opacity(0.2)
        case .Black: return Color.black.opacity(0.2)
        case .none: return Color.clear
        }
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
}
