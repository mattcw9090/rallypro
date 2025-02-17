import SwiftUI
import SwiftData

struct PaymentsView: View {
    let session: Session
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        List {
            ForEach(session.participants, id: \.compositeKey) { participant in
                HStack {
                    Text(participant.player.name)
                    Spacer()
                    Toggle(isOn: Binding(
                        get: { participant.hasPaid },
                        set: { newValue in
                            participant.hasPaid = newValue
                            try? modelContext.save()
                        }
                    )) {
                        Text("Paid")
                    }
                    .labelsHidden()
                }
                .padding(.vertical, 8)
            }
        }
        .listStyle(InsetGroupedListStyle())
        .navigationTitle("Payments")
    }
}

#Preview {
    // Update your preview to include a Session with participants having a payment status.
    let schema = Schema([Season.self, Session.self, Player.self, SessionParticipant.self])
    let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
    
    do {
        let mockContainer = try ModelContainer(for: schema, configurations: [modelConfiguration])
        let context = mockContainer.mainContext
        
        let season = Season(seasonNumber: 4)
        context.insert(season)
        let session = Session(sessionNumber: 5, season: season)
        context.insert(session)
        
        // Insert some mock players.
        let player1 = Player(name: "Alice")
        let player2 = Player(name: "Bob")
        context.insert(player1)
        context.insert(player2)
        
        // Create SessionParticipants.
        let sp1 = SessionParticipant(session: session, player: player1)
        let sp2 = SessionParticipant(session: session, player: player2)
        context.insert(sp1)
        context.insert(sp2)
        
        session.participants = [sp1, sp2]
        
        return PaymentsView(session: session)
            .modelContainer(mockContainer)
    } catch {
        fatalError("Failed to create preview container: \(error)")
    }
}
