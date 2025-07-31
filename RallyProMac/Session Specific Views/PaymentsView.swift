import SwiftUI
import SwiftData
import AppKit

// MARK: - Fancy Input Box Style
extension View {
    /// A macOS-friendly styled input box with padding, background, and accent border.
    func styledInputBox(width: CGFloat = 100) -> some View {
        self
            .padding(.vertical, 6)
            .padding(.horizontal, 8)
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(6)
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(Color.accentColor, lineWidth: 1)
            )
            .frame(width: width)
    }
}

struct PaymentsView: View {
    let session: Session
    @Environment(\.modelContext) private var modelContext

    @State private var courtCostText: String = ""
    @State private var shuttleNumberText: String = ""
    @State private var costPerShuttleText: String = ""

    // Computed properties based on session data.
    private var numberOfParticipants: Int {
        session.participants.count
    }
    private var participantsPayment: Double {
        Double(numberOfParticipants) * 25
    }
    private var payout: Double {
        (Double(numberOfParticipants) / 2.0) * 10
    }
    private var shuttleCost: Double {
        Double(session.numberOfShuttles) * session.costPerShuttle
    }
    private var netIncome: Double {
        participantsPayment - session.courtCost - payout - shuttleCost
    }

    private func commitChanges() {
        session.courtCost = Double(courtCostText) ?? 0
        session.numberOfShuttles = Int(shuttleNumberText) ?? 0
        session.costPerShuttle = Double(costPerShuttleText) ?? 0
        try? modelContext.save()
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Financial Summary Card
                VStack(alignment: .leading, spacing: 16) {
                    Text("Financial Summary")
                        .font(.headline)

                    // Court Cost Row
                    HStack {
                        Text("Court Cost")
                            .fontWeight(.semibold)
                        Spacer()
                        TextField("Enter cost", text: $courtCostText)
                            .styledInputBox(width: 100)
                    }

                    Divider()

                    // Shuttle Costs Group
                    Text("Shuttle Costs")
                        .font(.subheadline)
                        .fontWeight(.semibold)

                    HStack {
                        Text("Number of Shuttles")
                        Spacer()
                        TextField("0", text: $shuttleNumberText)
                            .styledInputBox(width: 80)
                    }

                    HStack {
                        Text("Cost per Shuttle")
                        Spacer()
                        TextField("0.00", text: $costPerShuttleText)
                            .styledInputBox(width: 80)
                    }

                    HStack {
                        Text("Total Shuttle Cost")
                        Spacer()
                        Text(String(format: "$%.2f", shuttleCost))
                    }

                    Divider()

                    // Payment Summary
                    HStack {
                        Text("Participants Payment")
                        Spacer()
                        Text(String(format: "$%.2f", participantsPayment))
                    }

                    HStack {
                        Text("Payout")
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
                .background(Color(NSColor.windowBackgroundColor))
                .cornerRadius(12)
                .padding(.horizontal)
            }
            .padding(.vertical)
        }
        .navigationTitle("Payments")
        .onAppear {
            courtCostText = String(format: "%.2f", session.courtCost)
            shuttleNumberText = String(session.numberOfShuttles)
            costPerShuttleText = String(format: "%.2f", session.costPerShuttle)
        }
        .onChange(of: courtCostText) { commitChanges() }
        .onChange(of: shuttleNumberText) { commitChanges() }
        .onChange(of: costPerShuttleText) { commitChanges() }
    }
}
