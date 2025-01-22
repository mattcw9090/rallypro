import SwiftUI
import SwiftData

struct AlertMessage: Identifiable {
    let id = UUID()
    let message: String
}

struct TeamsView: View {
    let session: Session
    
    @Environment(\.modelContext) private var context
    
    @State private var alertMessage: AlertMessage?
    
    @State private var selectedNumberOfWaves: Int = 5
    @State private var selectedNumberOfCourts: Int = 2
    
    @Query private var allParticipants: [SessionParticipant]
    @Query private var allDoublesMatches: [DoublesMatch]
    
    @Query(sort: [SortDescriptor<Player>(\.name, order: .forward)])
    private var allPlayers: [Player]
    
    private var participants: [SessionParticipant] {
        allParticipants.filter { $0.session == session }
    }
    
    private var doublesMatches: [DoublesMatch] {
        allDoublesMatches.filter { $0.session == session }
    }

    var body: some View {
        NavigationView {
            VStack {
                List {
                    // Red Team Section
                    Section(header: teamHeader(text: "Red Team", color: .red, count: redTeamMembers.count)) {
                        ForEach(redTeamMembers, id: \.id) { player in
                            TeamMemberRow(name: player.name, team: .Red)
                                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                    Button("Unassign") {
                                        updateTeam(for: player, to: nil)
                                    }
                                    .tint(.gray)
                                    Button("Black") {
                                        updateTeam(for: player, to: .Black)
                                    }
                                    .tint(.black)
                                }
                        }
                    }

                    // Black Team Section
                    Section(header: teamHeader(text: "Black Team", color: .black, count: blackTeamMembers.count)) {
                        ForEach(blackTeamMembers, id: \.id) { player in
                            TeamMemberRow(name: player.name, team: .Black)
                                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                    Button("Unassign") {
                                        updateTeam(for: player, to: nil)
                                    }
                                    .tint(.gray)
                                    Button("Red") {
                                        updateTeam(for: player, to: .Red)
                                    }
                                    .tint(.red)
                                }
                        }
                    }

                    // Unassigned Section
                    Section(header: teamHeader(text: "Unassigned", color: .gray, count: unassignedMembers.count)) {
                        ForEach(unassignedMembers, id: \.id) { player in
                            Text(player.name)
                                .font(.body)
                                .padding(.vertical, 5)
                                .swipeActions(edge: .leading, allowsFullSwipe: false) {
                                    Button("Waitlist") {
                                        moveToWaitlist(player: player)
                                    }
                                    .tint(.orange)
                                }
                                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                    Button("Black") {
                                        updateTeam(for: player, to: .Black)
                                    }
                                    .tint(.black)
                                    Button("Red") {
                                        updateTeam(for: player, to: .Red)
                                    }
                                    .tint(.red)
                                }
                        }
                    }

                }
                .listStyle(InsetGroupedListStyle())
                
                // MARK: - Dropdowns for Number of Waves and Courts
                HStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 5) {
                        Text("Waves")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                        Picker("Number of Waves", selection: $selectedNumberOfWaves) {
                            ForEach(1...10, id: \.self) { number in
                                Text("\(number)").tag(number)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                        .labelsHidden()
                    }

                    VStack(alignment: .leading, spacing: 5) {
                        Text("Courts")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                        Picker("Number of Courts", selection: $selectedNumberOfCourts) {
                            ForEach(1...10, id: \.self) { number in
                                Text("\(number)").tag(number)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                        .labelsHidden()
                    }
                }
                .padding([.horizontal, .top], 10)
                
                Button(action: {
                    if validateTeams() {
                        let logic = Logic()
                        
                        if let overallLineup = logic.generateCombinedLineup(
                            numberOfPlayersPerTeam: 6,
                            numberOfWaves: selectedNumberOfWaves,
                            numberOfCourts: selectedNumberOfCourts
                        ) {
                            print("Overall Lineup: \(overallLineup)")
                            deleteExistingDoublesMatches()
                            
                            for (waveIndex, wave) in overallLineup.enumerated() {
                                for match in wave {
                                    let firstPair = match[0]
                                    let secondPair = match[1]
                                    
                                    let newMatch = DoublesMatch(
                                        session: session,
                                        waveNumber: waveIndex + 1,
                                        redPlayer1: redTeamMembers[firstPair.0 - 1],
                                        redPlayer2: redTeamMembers[firstPair.1 - 1],
                                        blackPlayer1: blackTeamMembers[secondPair.0 - 1],
                                        blackPlayer2: blackTeamMembers[secondPair.1 - 1]
                                    )
                                    
                                    context.insert(newMatch)
                                }
                            }
                            
                        } else {
                            print("No valid lineup found after 10 attempts for red or black.")
                        }
                        alertMessage = AlertMessage(message: "Done trying draws. Check console for details.")
                    }
                }) {
                    Text("Generate Draws")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                        .padding()
                }
                .alert(item: $alertMessage) { message in
                    Alert(
                        title: Text("Validation Result"),
                        message: Text(message.message),
                        dismissButton: .default(Text("OK"))
                    )
                }
            }
        }
    }
    
    // MARK: - Computed Arrays
    
    private var redTeamMembers: [Player] {
        participants.filter { $0.team == .Red }.map { $0.player }
    }

    private var blackTeamMembers: [Player] {
        participants.filter { $0.team == .Black }.map { $0.player }
    }

    private var unassignedMembers: [Player] {
        participants.filter { $0.team == nil }.map { $0.player }
    }

    // MARK: - Validation

    private func validateTeams() -> Bool {
        // Check for unassigned players
        if !unassignedMembers.isEmpty {
            alertMessage = AlertMessage(message: "There are unassigned players.")
            return false
        }

        // Check total number of players
        let totalPlayers = participants.count

        if totalPlayers < 12 || totalPlayers % 2 != 0 {
            alertMessage = AlertMessage(message: "Each team must have 6 players or more.")
            return false
        }

        // Check if red team and black team have the same number of players
        if redTeamMembers.count != blackTeamMembers.count {
            alertMessage = AlertMessage(message: "Red team and Black team must have the same number of players.")
            return false
        }

        return true
    }

    // MARK: - UI Helpers
    
    private func updateTeam(for player: Player, to team: Team?) {
        guard let participant = participants.first(where: { $0.player == player }) else { return }
        participant.team = team
        saveContext()
    }
    
    private func moveToWaitlist(player: Player) {
        guard let participant = participants.first(where: { $0.player == player }) else {
            alertMessage = AlertMessage(message: "Player not found in the current session.")
            return
        }
        context.delete(participant)
        player.status = .onWaitlist
        
        let currentMaxPosition = allPlayers
            .filter { $0.status == .onWaitlist }
            .compactMap { $0.waitlistPosition }
            .max() ?? 0
        player.waitlistPosition = currentMaxPosition + 1
        saveContext()
        alertMessage = AlertMessage(message: "\(player.name) has been moved to the waitlist.")
    }
    
    private func deleteExistingDoublesMatches() {
        for match in doublesMatches {
            context.delete(match)
        }
        
        saveContext()
        
        print("All existing DoublesMatch records for this session have been deleted.")
    }
    
    private func teamHeader(text: String, color: Color, count: Int) -> some View {
        HStack {
            Circle()
                .fill(color)
                .frame(width: 10, height: 10)
            Text("\(text) (\(count))")
                .font(.headline)
                .foregroundColor(color)
        }
    }
    
    /// Save changes to SwiftData
    private func saveContext() {
        do {
            try context.save()
        } catch {
            print("Failed to save context: \(error)")
        }
    }
}

struct TeamMemberRow: View {
    let name: String
    let team: Team

    var body: some View {
        HStack {
            Image(systemName: "person.fill")
                .foregroundColor(teamColor)
                .frame(width: 30, height: 30)
            Text(name)
                .font(.body)
                .padding(.leading, 5)
        }
        .padding(.vertical, 5)
    }

    private var teamColor: Color {
        switch team {
        case .Red:   return .red
        case .Black: return .black
        }
    }
}

#Preview {
    let schema = Schema([Season.self, Session.self, Player.self, SessionParticipant.self])
    let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
    
    do {
        let mockContainer = try ModelContainer(for: schema, configurations: [modelConfiguration])
        let context = mockContainer.mainContext

        // Insert mock data
        let season = Season(seasonNumber: 4)
        context.insert(season)
        let session = Session(sessionNumber: 5, season: season)
        context.insert(session)
        let playerRed  = Player(name: "Shin Hean")
        let playerRed2 = Player(name: "Suan Sian Foo")
        let playerBlk  = Player(name: "Chris Fan")
        let playerBlk2 = Player(name: "CJ")
        let playerUnassigned = Player(name: "Hoson")
        context.insert(playerRed)
        context.insert(playerRed2)
        context.insert(playerBlk)
        context.insert(playerBlk2)
        context.insert(playerUnassigned)
        let p1 = SessionParticipant(session: session, player: playerRed,  team: .Red)
        let p2 = SessionParticipant(session: session, player: playerRed2, team: .Red)
        let p3 = SessionParticipant(session: session, player: playerBlk,  team: .Black)
        let p4 = SessionParticipant(session: session, player: playerBlk2, team: .Black)
        let pUnassigned = SessionParticipant(session: session, player: playerUnassigned)
        context.insert(p1)
        context.insert(p2)
        context.insert(p3)
        context.insert(p4)
        context.insert(pUnassigned)
        
        return TeamsView(session: session)
            .modelContainer(mockContainer)
    } catch {
        fatalError("Could not create ModelContainer: \(error)")
    }
}
