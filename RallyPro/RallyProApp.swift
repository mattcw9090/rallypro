import SwiftUI
import FirebaseCore
import FirebaseAuth
import SwiftData
import GoogleSignIn

// Create AppDelegate to initialize Firebase and handle Google Sign-In callbacks.
class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        FirebaseApp.configure()
        return true
    }
    
    // Handle the callback URL for Google Sign-In.
    @available(iOS 9.0, *)
    func application(_ app: UIApplication, open url: URL,
                     options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {
        return GIDSignIn.sharedInstance.handle(url)
    }
}

@main
struct RallyProApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate

    // Shared model container (unchanged).
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([Player.self, Season.self, Session.self, SessionParticipant.self, DoublesMatch.self])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    @StateObject private var authManager = AuthManager()
    @StateObject private var profileManager = ProfileManager()
    @StateObject private var playerManager: PlayerManager
    @StateObject private var playerManagerBeta: PlayerManagerBeta
    @StateObject private var seasonSessionManager: SeasonSessionManager
    @StateObject private var seasonSessionManagerBeta: SeasonSessionManagerBeta
    @StateObject private var seasonalResultsManager: SeasonalResultsManager
    @StateObject private var teamsManager: TeamsManager
    @StateObject private var drawsManager: DrawsManager
    @StateObject private var resultsManager: ResultsManager

    init() {
        let modelContext = sharedModelContainer.mainContext
        _playerManager = StateObject(wrappedValue: PlayerManager(modelContext: modelContext))
        _playerManagerBeta = StateObject(wrappedValue: PlayerManagerBeta())
        _seasonSessionManager = StateObject(wrappedValue: SeasonSessionManager(modelContext: modelContext))
        _seasonSessionManagerBeta = StateObject(wrappedValue: SeasonSessionManagerBeta())
        _seasonalResultsManager = StateObject(wrappedValue: SeasonalResultsManager(modelContext: modelContext))
        _teamsManager = StateObject(wrappedValue: TeamsManager(modelContext: modelContext))
        _drawsManager = StateObject(wrappedValue: DrawsManager(modelContext: modelContext))
        _resultsManager = StateObject(wrappedValue: ResultsManager(modelContext: modelContext))
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(authManager)
                .environmentObject(profileManager)
                .environmentObject(playerManager)
                .environmentObject(playerManagerBeta)
                .environmentObject(seasonSessionManager)
                .environmentObject(seasonSessionManagerBeta)
                .environmentObject(seasonalResultsManager)
                .environmentObject(teamsManager)
                .environmentObject(drawsManager)
                .environmentObject(resultsManager)
        }
        .modelContainer(sharedModelContainer)
    }
}
