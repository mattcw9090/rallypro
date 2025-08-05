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

    var body: some View {
        VStack(spacing: 16) {
            // Teams Columns
            ScrollView(.vertical) {
                HStack(alignment: .top, spacing: 16) {
                    teamColumn(
                        title: "Red Team",
                        color: .red,
                        members: teamsManager.redTeamMembers
                    ) { player in
                        Button("Unassign") { teamsManager.updateTeam(for: player, to: nil) }
                        Button("Move to Black") { teamsManager.updateTeam(for: player, to: .Black) }
                    }

                    teamColumn(
                        title: "Black Team",
                        color: .black,
                        members: teamsManager.blackTeamMembers
                    ) { player in
                        Button("Unassign") { teamsManager.updateTeam(for: player, to: nil) }
                        Button("Move to Red") { teamsManager.updateTeam(for: player, to: .Red) }
                    }

                    teamColumn(
                        title: "Unassigned",
                        color: .gray,
                        members: teamsManager.unassignedMembers
                    ) { player in
                        Button("Add to Waitlist") { teamsManager.moveToWaitlist(player: player) }
                        Button("Move to Black") { teamsManager.updateTeam(for: player, to: .Black) }
                        Button("Move to Red") { teamsManager.updateTeam(for: player, to: .Red) }
                    }
                }
                .padding(.horizontal)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)

            // Generate Button Only
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

    // MARK: - Generic Column Builder
    @ViewBuilder
    private func teamColumn<Content: View>(
        title: String,
        color: Color,
        members: [Player],
        @ViewBuilder menuItems: @escaping (Player) -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            teamHeader(title: title, color: color, count: members.count)

            // enumerate so we can show index+1
            ForEach(Array(members.enumerated()), id: \.element.id) { index, player in
                HStack(spacing: 8) {
                    // index badge
                    Text("\(index + 1)")
                        .font(.subheadline).bold()
                        .frame(width: 24, alignment: .trailing)

                    TeamMemberRow(name: player.name, team: teamForTitle(title))
                        .modifier(TeamRowStyle())
                }
                .contextMenu { menuItems(player) }
            }
        }
        .frame(maxWidth: .infinity, alignment: .topLeading)
    }

    // MARK: - Generate Action
    private func generate() {
        if teamsManager.validateTeams() {
            teamsManager.generateDrawsStatic()
            alertMessage = AlertMessage(message: "Draws generated. Check console for details.")
        } else {
            alertMessage = AlertMessage(message: "Team validation failed.")
        }
    }

    // MARK: - Helpers
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
        case "Red Team":   return .Red
        case "Black Team": return .Black
        default:            return nil
        }
    }
}

// MARK: - Row Style Modifier
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

    var body: some View {
        HStack {
            Image(systemName: "person.fill")
                .foregroundColor(color(for: team))
                .frame(width: 30, height: 30)

            Text(name)
                .font(.body)
                .padding(.leading, 5)

            Spacer()
        }
        .padding(.vertical, 5)
    }

    private func color(for team: Team?) -> Color {
        switch team {
        case .Red:   return .red
        case .Black: return .black
        default:     return .gray
        }
    }
}
