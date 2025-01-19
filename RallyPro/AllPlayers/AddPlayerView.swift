import SwiftUI
import SwiftData

struct AddPlayerView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var name: String = ""
    @State private var status: Player.PlayerStatus = .notInSession
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    // All Players Query
    @Query private var allPlayers: [Player]

    // Latest Waitlist Position Query
    private var latestWaitlistPosition: Int? {
        allPlayers
            .filter { $0.status == .onWaitlist }
            .compactMap { $0.waitlistPosition }
            .max()
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

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Player Details")) {
                    TextField("Name", text: $name)
                        .autocapitalization(.words)
                        .disableAutocorrection(true)

                    Picker("Status", selection: $status) {
                        ForEach(Player.PlayerStatus.allCases, id: \.self) { status in
                            Text(status.rawValue).tag(status)
                        }
                    }
                }
            }
            .navigationTitle("Add Player")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        addPlayer()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
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

    private func addPlayer() {
        // Trim the name to remove leading and trailing whitespaces
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Unique Name Validation
        if allPlayers.contains(where: { $0.name.lowercased() == trimmedName.lowercased() }) {
            alertMessage = "A player with the name '\(trimmedName)' already exists. Please choose a different name."
            showingAlert = true
            return
        }
        
        let newPlayer = Player(name: trimmedName, status: status)

        // Add player to the waitlist if status is .onWaitlist
        if status == .onWaitlist {
            let nextPosition = (latestWaitlistPosition ?? 0) + 1
            newPlayer.waitlistPosition = nextPosition
        }
        // Add player to the current session if status is .playing
        else if status == .playing {
            guard let session = latestSession else {
                alertMessage = "No active session exists to add the player."
                showingAlert = true
                return
            }

            let sessionParticipantsRecord = SessionParticipant(session: session, player: newPlayer)
            modelContext.insert(sessionParticipantsRecord)
        }

        modelContext.insert(newPlayer)

        do {
            try modelContext.save()
            dismiss()
        } catch {
            alertMessage = "Failed to save player: \(error.localizedDescription)"
            showingAlert = true
        }
    }
}

#Preview {
    let schema = Schema([Player.self])
    let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)

    do {
        let mockContainer = try ModelContainer(for: schema, configurations: [modelConfiguration])

        // Insert Mock Data
        let context = mockContainer.mainContext
        context.insert(Player(name: "Alice", status: .playing))
        context.insert(Player(name: "Bob", status: .onWaitlist, waitlistPosition: 2))
        context.insert(Player(name: "Charlie", status: .notInSession))
        context.insert(Player(name: "Denise", status: .onWaitlist, waitlistPosition: 1))

        return AddPlayerView()
            .modelContainer(mockContainer)
    } catch {
        fatalError("Could not create ModelContainer: \(error)")
    }
}
