import SwiftUI
import SwiftData

struct EditPlayerView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @Bindable var player: Player
    @State private var editedName: String = ""
    @State private var editedStatus: Player.PlayerStatus = .notInSession
    @State private var showingAlert = false
    @State private var alertMessage = ""

    // All Players Query
    @Query private var allPlayers: [Player]

    // Waitlist Players Query
    private var waitlistPlayers: [Player] {
        allPlayers.filter { $0.status == .onWaitlist }
            .sorted { ($0.waitlistPosition ?? 0) < ($1.waitlistPosition ?? 0) }
    }

    // Latest Season Query
    @Query(sort: \Season.seasonNumber, order: .reverse) private var allSeasons: [Season]
    private var latestSeason: Season? { allSeasons.first }
    
    // Latest Session Query
    @Query(sort: \Session.sessionNumber, order: .reverse) private var allSessions: [Session]
    private var latestSession: Session? {
        guard let season = latestSeason else { return nil }
        return allSessions.first { $0.season == season }
    }

    // Current Session Participants Query
    @Query private var allParticipants: [SessionParticipant]
    private var latestSessionParticipants: [SessionParticipant]? {
        guard let session = latestSession else { return nil }
        return allParticipants.filter { $0.session == session }
    }

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Player Details")) {
                    TextField("Name", text: $editedName)
                        .autocapitalization(.words)
                        .disableAutocorrection(true)

                    Picker("Status", selection: $editedStatus) {
                        ForEach(Player.PlayerStatus.allCases, id: \.self) { status in
                            Text(status.rawValue).tag(status)
                        }
                    }
                }
            }
            .navigationTitle("Edit Player")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveChanges()
                    }
                    .disabled(editedName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .onAppear {
                editedName = player.name
                editedStatus = player.status
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

    private func saveChanges() {
        // Trim the edited name to remove leading and trailing whitespaces
        let trimmedName = editedName.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Unique Name Validation
        if allPlayers.contains(where: { $0.name.lowercased() == trimmedName.lowercased() && $0.id != player.id }) {
            alertMessage = "A player with the name '\(trimmedName)' already exists. Please choose a different name."
            showingAlert = true
            return
        }
        
        switch (player.status, editedStatus) {
        
        case (.notInSession, .onWaitlist):
            player.waitlistPosition = (waitlistPlayers.compactMap { $0.waitlistPosition }.max() ?? 0) + 1
            
        case (.onWaitlist, .notInSession):
            guard let removedPosition = player.waitlistPosition else { return }
            player.waitlistPosition = nil
            waitlistPlayers
                .filter { ($0.waitlistPosition ?? 0) > removedPosition }
                .forEach { $0.waitlistPosition? -= 1 }
            
        case (.notInSession, .playing), (.onWaitlist, .playing):
            guard let session = latestSession else {
                alertMessage = "No active session to move the player into."
                showingAlert = true
                return
            }
            
            if player.status == .onWaitlist, let removedPosition = player.waitlistPosition {
                player.status = .playing
                player.waitlistPosition = nil
                waitlistPlayers
                    .filter { ($0.waitlistPosition ?? 0) > removedPosition }
                    .forEach { $0.waitlistPosition? -= 1 }
            }
            
            modelContext.insert(SessionParticipant(session: session, player: player))
            
        case (.playing, .notInSession), (.playing, .onWaitlist):
            guard let session = latestSession, let latestSessionParticipants = latestSessionParticipants else {
                alertMessage = "No active session to remove the player from."
                showingAlert = true
                return
            }
            
            if latestSessionParticipants.contains(where: { $0.player == player && $0.team != nil }) {
                alertMessage = "Please unassign the player from the team before changing their status."
                showingAlert = true
                return
            }
            
            if let participantRecord = latestSessionParticipants.first(where: { $0.player == player }) {
                modelContext.delete(participantRecord)
            } else {
                alertMessage = "Player is not found in the current session participants."
                showingAlert = true
                return
            }
            
            if editedStatus == .onWaitlist {
                player.waitlistPosition = (waitlistPlayers.compactMap { $0.waitlistPosition }.max() ?? 0) + 1
            }
            
        default:
            break
        }
        
        player.name = trimmedName
        player.status = editedStatus
        
        do {
            try modelContext.save()
            dismiss()
        } catch {
            alertMessage = "Failed to save changes: \(error.localizedDescription)"
            showingAlert = true
        }
    }
}

#Preview {
    let schema = Schema([Player.self, Season.self, Session.self, SessionParticipant.self])
    let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)

    do {
        let mockContainer = try ModelContainer(for: schema, configurations: [modelConfiguration])

        // Insert Mock Data
        let context = mockContainer.mainContext
        let playerToEdit = Player(name: "Charlie", status: .playing)
        context.insert(Player(name: "Alice", status: .playing))
        context.insert(Player(name: "Bob", status: .onWaitlist, waitlistPosition: 2))
        context.insert(playerToEdit)
        context.insert(Player(name: "Denise", status: .onWaitlist, waitlistPosition: 1))
        let season = Season(seasonNumber: 1)
        context.insert(season)
        let session = Session(sessionNumber: 1, season: season)
        context.insert(session)
        let participant = SessionParticipant(session: session, player: playerToEdit, team: .Red)
        context.insert(participant)

        return EditPlayerView(player: playerToEdit)
            .modelContainer(mockContainer)
    } catch {
        fatalError("Could not create ModelContainer: \(error)")
    }
}
