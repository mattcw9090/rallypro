import SwiftUI
import SwiftData
import AppKit

// MARK: - Alert Helper

struct AlertMessage: Identifiable {
    let id = UUID()
    let message: String
}

// MARK: - TeamsView

struct TeamsView: View {
    let session: Session
    @EnvironmentObject var teamsManager: TeamsManager

    @State private var alertMessage: AlertMessage?
    @State private var swapCandidates: [Player] = []

    var body: some View {
        VStack(spacing: 16) {
            ScrollView(.vertical) {
                HStack(alignment: .top, spacing: 16) {
                    teamColumn(
                        title: "Red Team",
                        color: .red,
                        participants: teamsManager.redTeamParticipants
                    ) { participant in
                        let player = participant.player
                        Button("Unassign") { teamsManager.updateTeam(for: player, to: nil) }
                        Button("Move to Black") { teamsManager.updateTeam(for: player, to: .Black) }
                        Button("Select for Swap") {
                            if !swapCandidates.contains(where: { $0.id == player.id }) {
                                swapCandidates.append(player)
                            }
                        }
                    }

                    teamColumn(
                        title: "Black Team",
                        color: .black,
                        participants: teamsManager.blackTeamParticipants
                    ) { participant in
                        let player = participant.player
                        Button("Unassign") { teamsManager.updateTeam(for: player, to: nil) }
                        Button("Move to Red") { teamsManager.updateTeam(for: player, to: .Red) }
                        Button("Select for Swap") {
                            if !swapCandidates.contains(where: { $0.id == player.id }) {
                                swapCandidates.append(player)
                            }
                        }
                    }

                    teamColumn(
                        title: "Unassigned",
                        color: .gray,
                        participants: teamsManager.unassignedParticipants
                    ) { participant in
                        let player = participant.player
                        Button("Add to Waitlist") { teamsManager.moveToWaitlist(player: player) }
                        Button("Move to Black") { teamsManager.updateTeam(for: player, to: .Black) }
                        Button("Move to Red") { teamsManager.updateTeam(for: player, to: .Red) }
                    }
                }
                .padding(.horizontal)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)

            Button(action: generate) {
                Label("Generate Draws", systemImage: "shuffle")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .padding()
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
            .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
            
            if swapCandidates.count == 2 {
                Button("Swap \(swapCandidates[0].name) ↔︎ \(swapCandidates[1].name)") {
                    teamsManager.swapParticipants(swapCandidates[0], swapCandidates[1])
                    swapCandidates.removeAll()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .padding()
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
            }

            if !swapCandidates.isEmpty {
                Button("Clear Swap Selection") {
                    swapCandidates.removeAll()
                }
                .padding(.bottom, 8)
            }
        }
        .navigationTitle("Teams")
        .onAppear {
            teamsManager.setSession(session)
            teamsManager.refreshData()
        }
        .alert(item: $alertMessage) { alert in
            Alert(
                title: Text("Alert"),
                message: Text(alert.message),
                dismissButton: .default(Text("OK"))
            )
        }
    }
    
    private func toggleSwapCandidate(_ player: Player) {
        if swapCandidates.contains(where: { $0.id == player.id }) {
            swapCandidates.removeAll { $0.id == player.id }
        } else if swapCandidates.count < 2 {
            swapCandidates.append(player)
        }
    }

    private func generate() {
        if teamsManager.validateTeams() {
            teamsManager.generateDrawsStatic()
            alertMessage = AlertMessage(message: "Draws generated. Check console for details.")
        } else {
            alertMessage = AlertMessage(message: "Team validation failed.")
        }
    }

    @ViewBuilder
    private func teamColumn<Content: View>(
        title: String,
        color: Color,
        participants: [SessionParticipant],
        @ViewBuilder menuItems: @escaping (SessionParticipant) -> Content
    )-> some View {
        VStack(alignment: .leading, spacing: 8) {
            teamHeader(title: title, color: color, count: participants.count)

            ForEach(Array(participants.enumerated()), id: \.element.id) { index, participant in
                HStack(spacing: 8) {
                    Text("\(index + 1)")
                        .font(.subheadline).bold()
                        .frame(width: 24, alignment: .trailing)

                    TeamMemberRow(
                        name: participant.player.name,
                        team: participant.team,
                        teamPosition: participant.teamPosition,
                        isSelected: swapCandidates.contains(where: { $0.id == participant.player.id })
                    )
                    .onTapGesture {
                        toggleSwapCandidate(participant.player)
                    }
                    .modifier(TeamRowStyle())
                }
                .contextMenu { menuItems(participant) }
            }
        }
        .frame(maxWidth: .infinity, alignment: .topLeading)
    }

    private func teamHeader(title: String, color: Color, count: Int) -> some View {
        HStack(spacing: 8) {
            Circle()
                .fill(color)
                .frame(width: 10, height: 10)

            Text("\(title) (\(count))")
                .font(.headline)
        }
        .padding(.vertical, 6)
        .background(Color(NSColor.controlBackgroundColor).opacity(0.6))
        .cornerRadius(6)
    }

    private func teamForTitle(_ title: String) -> Team? {
        switch title {
        case "Red Team": return .Red
        case "Black Team": return .Black
        default: return nil
        }
    }
}

// MARK: - TeamRowStyle

struct TeamRowStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(6)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(NSColor.windowBackgroundColor))
            )
            .shadow(color: .black.opacity(0.03), radius: 4, x: 0, y: 2)
    }
}

// MARK: - TeamMemberRow
struct TeamMemberRow: View {
    let name: String
    let team: Team?
    let teamPosition: Int
    let isSelected: Bool

    var body: some View {
        HStack {
            Image(systemName: "person.fill")
                .foregroundColor(color(for: team))
                .frame(width: 30, height: 30)

            Text("\(name) [\(teamPosition)]")
                .font(.body)
                .padding(.leading, 5)

            Spacer()
        }
        .padding(.vertical, 5)
        .padding(.horizontal, 8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isSelected ? Color.accentColor.opacity(0.2) : Color(NSColor.windowBackgroundColor))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(isSelected ? Color.accentColor : .clear, lineWidth: 2)
        )
    }

    private func color(for team: Team?) -> Color {
        switch team {
        case .Red: return .red
        case .Black: return .black
        default: return .gray
        }
    }
}
