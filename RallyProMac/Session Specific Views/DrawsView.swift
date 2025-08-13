import SwiftUI
import SwiftData

struct DrawsView: View {
    let session: Session

    @EnvironmentObject var drawsManager: DrawsManager
    @Environment(\.modelContext) private var modelContext
    @State private var isEditingPlayers = false

    private var filteredMatches: [DoublesMatch] { drawsManager.doublesMatches(for: session) }
    private var participants: [SessionParticipant] { drawsManager.participants(for: session) }
    private var redTeamMembers: [Player] { drawsManager.redTeamMembers(for: session) }
    private var blackTeamMembers: [Player] { drawsManager.blackTeamMembers(for: session) }
    private var maxWaveNumber: Int { drawsManager.maxWaveNumber(for: session) }

    private var displayContent: some View {
        let grouped = Dictionary(grouping: filteredMatches, by: { $0.waveNumber })
        return VStack(spacing: 16) {
            ForEach(grouped.keys.sorted(), id: \.self) { wave in
                if let matches = grouped[wave] {
                    WaveView(
                        title: "Wave \(wave)",
                        matches: matches,
                        isEditingPlayers: isEditingPlayers,
                        redTeamMembers: redTeamMembers,
                        blackTeamMembers: blackTeamMembers,
                        addMatchAction: { drawsManager.addMatch(for: session, wave: wave) },
                        deleteMatchAction: { drawsManager.deleteMatch($0, for: session) }
                    )
                    .padding(.horizontal)
                }
            }
        }
    }

    var body: some View {
        NavigationStack {
            ZStack { ScrollView { displayContent } }
                .navigationTitle("Draws")
                .toolbar {
                    Button(isEditingPlayers ? "Done" : "Edit") {
                        if isEditingPlayers { try? modelContext.save() }
                        withAnimation { isEditingPlayers.toggle() }
                    }
                    if isEditingPlayers {
                        Button("Add Wave") { drawsManager.addWave(for: session) }
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
                Text("Score: \(text)").font(.subheadline)
            }
        }
        .padding()
        .background(matchBackground)
        .overlay(ongoingBorder)
        .cornerRadius(8)
        .shadow(radius: 2)
        .onAppear { initializeScores() }
        .alert(isPresented: $showingAlert) {
            Alert(title: Text("Error"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
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
                teamPlayerNameView(currentPlayer: match.redPlayer1,   team: .Red)   { updatePlayer(.red1, to: $0) }
                teamPlayerNameView(currentPlayer: match.redPlayer2,   team: .Red)   { updatePlayer(.red2, to: $0) }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Text("vs").bold()

            VStack(alignment: .trailing, spacing: 6) {
                teamPlayerNameView(currentPlayer: match.blackPlayer1, team: .Black) { updatePlayer(.black1, to: $0) }
                teamPlayerNameView(currentPlayer: match.blackPlayer2, team: .Black) { updatePlayer(.black2, to: $0) }
            }
            .frame(maxWidth: .infinity, alignment: .trailing)

            if isEditingPlayers {
                Button(role: .destructive) { deleteMatchAction(match) } label: {
                    Image(systemName: "trash").foregroundColor(.red)
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
        let members = (team == .Red) ? redTeamMembers : blackTeamMembers
        return Group {
            if isEditingPlayers {
                Menu {
                    ForEach(members, id: \.id) { player in
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
            setInputs(title: "Set 1",
                      red: $redFirstSetScore, black: $blackFirstSetScore,
                      redFocus: .redFirst, blackFocus: .blackFirst)
            setInputs(title: "Set 2",
                      red: $redSecondSetScore, black: $blackSecondSetScore,
                      redFocus: .redSecond, blackFocus: .blackSecond)
            Spacer()
        }
        .padding(.top, 4)
        .onChange(of: redFirstSetScore)    { handleScoreChange() }
        .onChange(of: blackFirstSetScore)  { handleScoreChange() }
        .onChange(of: redSecondSetScore)   { handleScoreChange() }
        .onChange(of: blackSecondSetScore) { handleScoreChange() }
    }

    private func setInputs(
        title: String,
        red: Binding<String>,
        black: Binding<String>,
        redFocus: ScoreField,
        blackFocus: ScoreField
    ) -> some View {
        VStack(spacing: 4) {
            Text(title).font(.caption)
            HStack(spacing: 4) {
                TextField("R", text: red)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 40)
                    .focused($activeScoreField, equals: redFocus)
                Text("-")
                TextField("B", text: black)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 40)
                    .focused($activeScoreField, equals: blackFocus)
            }
        }
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

    private var matchBackground: Color {
        if match.isComplete { return winningTeamColor }
        if match.isOngoing { return Color.yellow.opacity(0.18) }
        return Color.clear
    }

    private var ongoingBorder: some View {
        (match.isOngoing && !match.isComplete)
        ? AnyView(RoundedRectangle(cornerRadius: 8).stroke(Color.yellow.opacity(0.7), lineWidth: 2))
        : AnyView(RoundedRectangle(cornerRadius: 8).stroke(Color.clear, lineWidth: 0))
    }

    private var partialScoreText: String? {
        var parts: [String] = []
        if match.redTeamScoreFirstSet != 0 || match.blackTeamScoreFirstSet != 0 {
            parts.append("\(match.redTeamScoreFirstSet)-\(match.blackTeamScoreFirstSet)")
        }
        if match.redTeamScoreSecondSet != 0 || match.blackTeamScoreSecondSet != 0 {
            parts.append("\(match.redTeamScoreSecondSet)-\(match.blackTeamScoreSecondSet)")
        }
        return parts.isEmpty ? nil : parts.joined(separator: ", ")
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
        let red = match.redTeamScoreFirstSet + match.redTeamScoreSecondSet
        let black = match.blackTeamScoreFirstSet + match.blackTeamScoreSecondSet
        return red == black ? nil : (red > black ? .Red : .Black)
    }

    private var winningTeamColor: Color {
        switch winningTeam {
        case .Red:   return Color.red.opacity(0.2)
        case .Black: return Color.black.opacity(0.2)
        case .none:  return Color.clear
        }
    }

    private enum PlayerSlot { case red1, red2, black1, black2 }

    private func updatePlayer(_ slot: PlayerSlot, to newPlayer: Player) {
        do {
            switch slot {
            case .red1:   match.redPlayer1   = newPlayer
            case .red2:   match.redPlayer2   = newPlayer
            case .black1: match.blackPlayer1 = newPlayer
            case .black2: match.blackPlayer2 = newPlayer
            }
            try modelContext.save()
        } catch {
            alertMessage = "Failed to save player selection: \(error.localizedDescription)"
            showingAlert = true
        }
    }
}
