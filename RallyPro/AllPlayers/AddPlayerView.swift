import SwiftUI
import SwiftData

struct AddPlayerView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var playerManager: PlayerManager

    @State private var name: String = ""
    @State private var status: Player.PlayerStatus = .notInSession
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var isMale: Bool = true

    // Query for Seasons (used to determine the latest session)
    @Query(sort: \Season.seasonNumber, order: .reverse) private var allSeasons: [Season]
    private var latestSeason: Season? { allSeasons.first }

    // Query for Sessions (used to determine the current session)
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
                    Toggle("Is Male", isOn: $isMale)
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
        do {
            try playerManager.addPlayer(
                name: name,
                status: status,
                isMale: isMale,
                latestSession: latestSession
            )
            dismiss()
        } catch {
            alertMessage = error.localizedDescription
            showingAlert = true
        }
    }
}

#Preview {
    let schema = Schema([Player.self, Season.self, Session.self, SessionParticipant.self])
    let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)

    do {
        let mockContainer = try ModelContainer(for: schema, configurations: [modelConfiguration])
        let context = mockContainer.mainContext

        // Insert mock data
        context.insert(Player(name: "Alice", status: .playing))
        context.insert(Player(name: "Bob", status: .onWaitlist, waitlistPosition: 2, isMale: true))
        context.insert(Player(name: "Charlie", status: .notInSession, isMale: true))
        context.insert(Player(name: "Denise", status: .onWaitlist, waitlistPosition: 1, isMale: false))
        let season = Season(seasonNumber: 1)
        context.insert(season)
        let session = Session(sessionNumber: 1, season: season)
        context.insert(session)
        
        let manager = PlayerManager(modelContext: context)
        
        return AddPlayerView()
            .modelContainer(mockContainer)
            .environmentObject(manager)
    } catch {
        fatalError("Could not create ModelContainer: \(error)")
    }
}
