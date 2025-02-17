import SwiftUI
import SwiftData

enum DetailSegment: String, CaseIterable, Identifiable {
    case teams = "Teams"
    case draws = "Draws"
    case results = "Results"
    case payments = "Payments"
    
    var id: String { rawValue }
}

struct SessionDetailView: View {
    let session: Session
    @State private var selectedSegment: DetailSegment = .teams

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Picker("View", selection: $selectedSegment) {
                    ForEach(DetailSegment.allCases) { segment in
                        Text(segment.rawValue).tag(segment)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                .padding([.top, .bottom])

                Divider()

                Group {
                    switch selectedSegment {
                    case .teams:
                        TeamsView(session: session)
                    case .draws:
                        DrawsView(session: session)
                    case .results:
                        ResultsView(session: session)
                    case .payments:
                        PaymentsView(session: session)  // Show the PaymentsView
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .navigationTitle("Season \(session.seasonNumber) Session \(session.sessionNumber)")
        }
    }
}

#Preview {
    let schema = Schema([Season.self, Session.self, Player.self, SessionParticipant.self])
    let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)

    do {
        let mockContainer = try ModelContainer(for: schema, configurations: [modelConfiguration])
        let context = mockContainer.mainContext

        let season = Season(seasonNumber: 4)
        context.insert(season)
        let session = Session(sessionNumber: 5, season: season)
        context.insert(session)
        
        // Insert mock players.
        let player1 = Player(name: "Alice")
        let player2 = Player(name: "Bob")
        context.insert(player1)
        context.insert(player2)
        
        // Create SessionParticipants.
        let sp1 = SessionParticipant(session: session, player: player1)
        let sp2 = SessionParticipant(session: session, player: player2)
        context.insert(sp1)
        context.insert(sp2)
        
        // Create any necessary managers.
        let teamsManager = TeamsManager(modelContext: context)
        let drawsManager = DrawsManager(modelContext: context)
        let resultsManager = ResultsManager(modelContext: context)

        return NavigationStack {
            SessionDetailView(session: session)
                .environmentObject(teamsManager)
                .environmentObject(drawsManager)
                .environmentObject(resultsManager)
                .modelContainer(mockContainer)
        }
    } catch {
        fatalError("Could not create ModelContainer: \(error)")
    }
}
