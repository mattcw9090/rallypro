import SwiftUI
import SwiftData

struct PaymentsView: View {
    let session: Session
    @Environment(\.modelContext) private var modelContext
    
    // A temporary state for editing the court cost as text.
    @State private var courtCostText: String = ""
    
    // Computed properties based on the number of session participants.
    var numberOfParticipants: Int {
        session.participants.count
    }
    
    var participantsPayment: Double {
        Double(numberOfParticipants) * 25
    }
    
    var payout: Double {
        (Double(numberOfParticipants) / 2.0) * 10
    }
    
    var netIncome: Double {
        participantsPayment - session.courtCost - payout
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Financial Summary Card
                VStack(alignment: .leading, spacing: 16) {
                    Text("Financial Summary")
                        .font(.headline)
                        .padding(.bottom, 4)
                    
                    // Court Cost row with highlighted TextField
                    HStack {
                        Text("Court Cost")
                            .fontWeight(.semibold)
                        Spacer()
                        TextField("Enter cost", text: $courtCostText, onCommit: {
                            if let cost = Double(courtCostText) {
                                session.courtCost = cost
                            } else {
                                session.courtCost = 0
                            }
                            try? modelContext.save()
                        })
                        .padding(8)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color(UIColor.systemBackground))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.accentColor, lineWidth: 2)
                        )
                        .keyboardType(.decimalPad)
                        .frame(width: 100)
                    }
                    
                    Divider()
                    
                    HStack {
                        Text("Participants Payment")
                        Spacer()
                        Text(String(format: "$%.2f", participantsPayment))
                    }
                    
                    HStack {
                        Text("Winning Team Payout")
                        Spacer()
                        Text(String(format: "$%.2f", payout))
                    }
                    
                    Divider()
                    
                    HStack {
                        Text("Net Income")
                            .fontWeight(.bold)
                        Spacer()
                        Text(String(format: "$%.2f", netIncome))
                            .fontWeight(.bold)
                    }
                }
                .padding()
                .background(.ultraThinMaterial)
                .cornerRadius(12)
                .shadow(radius: 4)
                .padding(.horizontal)
                
                // Participants List Card
                VStack(alignment: .leading, spacing: 0) {
                    Text("Participants")
                        .font(.headline)
                        .padding(.horizontal)
                        .padding(.vertical, 8)
                    
                    ForEach(session.participants, id: \.compositeKey) { participant in
                        HStack {
                            Text(participant.player.name)
                                .font(.body)
                            Spacer()
                            Toggle("", isOn: Binding(
                                get: { participant.hasPaid },
                                set: { newValue in
                                    participant.hasPaid = newValue
                                    try? modelContext.save()
                                }
                            ))
                            .toggleStyle(SwitchToggleStyle(tint: .blue))
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 8)
                        
                        Divider()
                    }
                }
                .background(Color(UIColor.secondarySystemBackground))
                .cornerRadius(12)
                .padding(.horizontal)
            }
            .padding(.vertical)
        }
        .navigationTitle("Payments")
        .onAppear {
            // Initialize the text field with the persistent court cost value.
            courtCostText = String(format: "%.2f", session.courtCost)
        }
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
        session.courtCost = 50.0
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
        
        // Ensure the session's participants relationship is updated.
        session.participants = [sp1, sp2]
        
        return PaymentsView(session: session)
            .modelContainer(mockContainer)
    } catch {
        fatalError("Failed to create preview container: \(error)")
    }
}
