import SwiftUI
import SwiftData
import AppKit

// MARK: - Alert Helper

struct AlertMessage: Identifiable {
    let id = UUID()
    let message: String
}

struct TeamsView: View {
    let session: Session
    @EnvironmentObject var teamsManager: TeamsManager

    @State private var alertMessage: AlertMessage?
    @State private var selectedNumberOfWaves: Int = 5
    @State private var selectedNumberOfCourts: Int = 2

    // Main interactive display content using a List.
    private var displayContent: some View {
        List {
            // Red Team Section
            Section(header: teamHeader(text: "Red Team", color: .red, count: teamsManager.redTeamMembers.count)) {
                ForEach(teamsManager.redTeamMembers, id: \.id) { player in
                    TeamMemberRow(name: player.name, team: .Red)
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button("Unassign") {
                                teamsManager.updateTeam(for: player, to: nil)
                            }
                            .tint(.gray)
                            Button("Black") {
                                teamsManager.updateTeam(for: player, to: .Black)
                            }
                            .tint(.black)
                        }
                        .listRowSeparator(.hidden)
                }
            }
            // Black Team Section
            Section(header: teamHeader(text: "Black Team", color: .black, count: teamsManager.blackTeamMembers.count)) {
                ForEach(teamsManager.blackTeamMembers, id: \.id) { player in
                    TeamMemberRow(name: player.name, team: .Black)
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button("Unassign") {
                                teamsManager.updateTeam(for: player, to: nil)
                            }
                            .tint(.gray)
                            Button("Red") {
                                teamsManager.updateTeam(for: player, to: .Red)
                            }
                            .tint(.red)
                        }
                        .listRowSeparator(.hidden)
                }
            }
            // Unassigned Section
            Section(header: teamHeader(text: "Unassigned", color: .gray, count: teamsManager.unassignedMembers.count)) {
                ForEach(teamsManager.unassignedMembers, id: \.id) { player in
                    Text(player.name)
                        .font(.body)
                        .padding(.vertical, 5)
                        .swipeActions(edge: .leading, allowsFullSwipe: false) {
                            Button("Waitlist") {
                                teamsManager.moveToWaitlist(player: player)
                            }
                            .tint(.orange)
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button("Black") {
                                teamsManager.updateTeam(for: player, to: .Black)
                            }
                            .tint(.black)
                            Button("Red") {
                                teamsManager.updateTeam(for: player, to: .Red)
                            }
                            .tint(.red)
                        }
                }
            }
            // Additional controls for generating draws.
            Section {
                controlsView
                    .listRowInsets(EdgeInsets(top: 20, leading: 0, bottom: 20, trailing: 0))
                    .listRowSeparator(.hidden)
            }
        }
        .listStyle(.inset)
    }
    
    // Controls view (for Waves, Courts, and Generate Draws)
    private var controlsView: some View {
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
            Button(action: {
                if teamsManager.validateTeams() {
                    teamsManager.generateDraws(
                        numberOfWaves: selectedNumberOfWaves,
                        numberOfCourts: selectedNumberOfCourts
                    )
                    alertMessage = AlertMessage(message: "Done trying draws. Check console for details.")
                } else {
                    alertMessage = AlertMessage(message: "Team validation failed.")
                }
            }) {
                Text("Generate Draws")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 10)
    }
    
    // Helper functions for headers and team sections...
    private func teamSectionView(for players: [Player], team: Team?, headerTitle: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Circle()
                    .fill(color(for: team))
                    .frame(width: 10, height: 10)
                Text("\(headerTitle) (\(players.count))")
                    .font(.headline)
                    .foregroundColor(color(for: team))
            }
            ForEach(players, id: \.id) { player in
                TeamMemberRow(name: player.name, team: team)
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color(NSColor.windowBackgroundColor))
        .cornerRadius(10)
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
        .padding(.vertical, 4)
    }
    
    private func color(for team: Team?) -> Color {
        if let team = team {
            switch team {
            case .Red:
                return .red
            case .Black:
                return .black
            }
        }
        return .gray
    }
    
    var body: some View {
        ZStack {
            displayContent
        }
        .navigationTitle("Teams")
        .onAppear {
            teamsManager.setSession(session)
            teamsManager.refreshData()
        }
        .alert(item: $alertMessage) { alert in
            Alert(
                title: Text("Alert"),
                message: Text(alert.message),
                dismissButton: .default(Text("OK"))
            )
        }
    }

}



// MARK: - TeamMemberRow

struct TeamMemberRow: View {
    let name: String
    // For team-specific styling, this view accepts an optional team.
    // If nil, the text is shown in gray.
    let team: Team?

    var body: some View {
        HStack {
            Image(systemName: "person.fill")
                .foregroundColor(color(for: team))
                .frame(width: 30, height: 30)
            Text(name)
                .font(.body)
                .padding(.leading, 5)
            Spacer()
        }
        .padding(.vertical, 5)
    }
    
    private func color(for team: Team?) -> Color {
        if let team = team {
            switch team {
            case .Red:
                return .red
            case .Black:
                return .black
            }
        }
        return .gray
    }
}

#Preview {
    let schema = Schema([Season.self, Session.self, Player.self, SessionParticipant.self, DoublesMatch.self])
    let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
    
    do {
        let mockContainer = try ModelContainer(for: schema, configurations: [modelConfiguration])
        let context = mockContainer.mainContext
        
        // Insert mock Season and Session.
        let season = Season(seasonNumber: 4)
        context.insert(season)
        let session = Session(sessionNumber: 5, season: season)
        context.insert(session)
        
        // Insert some mock players.
        let playerRed = Player(name: "Shin Hean")
        let playerRed2 = Player(name: "Suan Sian Foo")
        let playerBlk = Player(name: "Chris Fan")
        let playerBlk2 = Player(name: "CJ")
        let playerUnassigned = Player(name: "Hoson")
        context.insert(playerRed)
        context.insert(playerRed2)
        context.insert(playerBlk)
        context.insert(playerBlk2)
        context.insert(playerUnassigned)
        
        // Create SessionParticipants for the session.
        let p1 = SessionParticipant(session: session, player: playerRed, team: .Red)
        let p2 = SessionParticipant(session: session, player: playerRed2, team: .Red)
        let p3 = SessionParticipant(session: session, player: playerBlk, team: .Black)
        let p4 = SessionParticipant(session: session, player: playerBlk2, team: .Black)
        let pUnassigned = SessionParticipant(session: session, player: playerUnassigned)
        context.insert(p1)
        context.insert(p2)
        context.insert(p3)
        context.insert(p4)
        context.insert(pUnassigned)
        
        // Initialize the TeamsManager using only the model context.
        let teamsManager = TeamsManager(modelContext: context)
        
        // Return the TeamsView with the session and the injected manager.
        return TeamsView(session: session)
            .environmentObject(teamsManager)
            .modelContainer(mockContainer)
    } catch {
        fatalError("Failed to create preview container: \(error)")
    }
}

