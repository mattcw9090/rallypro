import SwiftUI
import SwiftData

@main
struct RallyProMacApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([Player.self, Season.self, Session.self, SessionParticipant.self, DoublesMatch.self])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    @StateObject private var playerManager: PlayerManager
    @StateObject private var seasonSessionManager: SeasonSessionManager
    @StateObject private var seasonalResultsManager: SeasonalResultsManager
    @StateObject private var teamsManager: TeamsManager
    @StateObject private var drawsManager: DrawsManager
    @StateObject private var resultsManager: ResultsManager

    init() {
        let modelContext = sharedModelContainer.mainContext

        _playerManager = StateObject(wrappedValue: PlayerManager(modelContext: modelContext))
        _seasonSessionManager = StateObject(wrappedValue: SeasonSessionManager(modelContext: modelContext))
        _seasonalResultsManager = StateObject(wrappedValue: SeasonalResultsManager(modelContext: modelContext))
        _teamsManager = StateObject(wrappedValue: TeamsManager(modelContext: modelContext))
        _drawsManager = StateObject(wrappedValue: DrawsManager(modelContext: modelContext))
        _resultsManager = StateObject(wrappedValue: ResultsManager(modelContext: modelContext))

        // ✅ Fix team positions on launch
        assignTeamPositionsIfNeeded(context: modelContext)
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(playerManager)
                .environmentObject(seasonSessionManager)
                .environmentObject(seasonalResultsManager)
                .environmentObject(teamsManager)
                .environmentObject(drawsManager)
                .environmentObject(resultsManager)
                .frame(minWidth: 600, minHeight: 400)
        }
        .modelContainer(sharedModelContainer)
    }
    
    // 1️⃣ A lightweight Hashable key
    private struct SessionTeamKey: Hashable {
        let sessionID: String
        let teamValue: String
    }

    // 2️⃣ Your helper that assigns positions
    private func assignTeamPositionsIfNeeded(context: ModelContext) {
        do {
            let participants = try context.fetch(FetchDescriptor<SessionParticipant>())

            // 3️⃣ Group with the Hashable key
            let grouped = Dictionary(grouping: participants) { p in
                SessionTeamKey(
                    sessionID: p.session.uniqueIdentifier,
                    teamValue: p.teamRawValue ?? "Unassigned"
                )
            }

            // 4️⃣ Walk each (session, team) bucket
            for (key, teamMembers) in grouped {
                guard key.teamValue != "Unassigned" else { continue }          // skip folks not on a team
                guard teamMembers.contains(where: { $0.teamPosition == -1 }) else { continue } // already done

                // 🔀 Sort however you like here
                for (index, participant) in teamMembers
                        .sorted(by: { $0.player.name < $1.player.name })
                        .enumerated() {
                    participant.teamPosition = index
                }
            }

            try context.save()
        } catch {
            print("❌ Couldn’t auto-assign teamPositions: \(error)")
        }
    }

}
