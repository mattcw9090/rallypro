import SwiftUI
import SwiftData

@main
struct RallyProApp: App {
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
    @StateObject private var seasonManager: SeasonSessionManager
    @StateObject private var seasonalResultsManager: SeasonalResultsManager

    init() {
        let modelContext = sharedModelContainer.mainContext
        _playerManager = StateObject(wrappedValue: PlayerManager(modelContext: modelContext))
        _seasonManager = StateObject(wrappedValue: SeasonSessionManager(modelContext: modelContext))
        _seasonalResultsManager = StateObject(wrappedValue: SeasonalResultsManager(modelContext: modelContext))
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(playerManager)
                .environmentObject(seasonManager)
                .environmentObject(seasonalResultsManager)
        }
        .modelContainer(sharedModelContainer)
    }
}
