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
}
