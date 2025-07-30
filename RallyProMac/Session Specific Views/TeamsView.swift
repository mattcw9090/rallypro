import SwiftUI
import SwiftData
import AppKit

// Alert helper
struct AlertMessage: Identifiable {
    let id = UUID()
    let message: String
}

struct TeamsView: View {
    let session: Session
    @EnvironmentObject var teamsManager: TeamsManager

    @State private var alertMessage: AlertMessage?
    @State private var selectedNumberOfWaves: Int = 5
    @State private var selectedNumberOfCourts: Int = 2

    var body: some View {
        List {
            // Red Team Section
            Section(header: teamHeader(title: "Red Team", color: .red, count: teamsManager.redTeamMembers.count)) {
                ForEach(teamsManager.redTeamMembers, id: \.id) { player in
                    TeamMemberRow(name: player.name, team: .Red)
                        .padding(6)
                        .background(RoundedRectangle(cornerRadius: 8).fill(Color(NSColor.windowBackgroundColor)))
                        .shadow(color: .black.opacity(0.03), radius: 4, x: 0, y: 2)
                        .swipeActions(edge: .trailing) {
                            Button(role: .destructive) {
                                teamsManager.updateTeam(for: player, to: nil)
                            } label: {
                                Label("Unassign", systemImage: "xmark.circle")
                            }
                            Button {
                                teamsManager.updateTeam(for: player, to: .Black)
                            } label: {
                                Label("Black", systemImage: "circle.fill")
                            }
                        }
                }
            }

            // Black Team Section
            Section(header: teamHeader(title: "Black Team", color: .black, count: teamsManager.blackTeamMembers.count)) {
                ForEach(teamsManager.blackTeamMembers, id: \.id) { player in
                    TeamMemberRow(name: player.name, team: .Black)
                        .padding(6)
                        .background(RoundedRectangle(cornerRadius: 8).fill(Color(NSColor.windowBackgroundColor)))
                        .shadow(color: .black.opacity(0.03), radius: 4, x: 0, y: 2)
                        .swipeActions(edge: .trailing) {
                            Button(role: .destructive) {
                                teamsManager.updateTeam(for: player, to: nil)
                            } label: {
                                Label("Unassign", systemImage: "xmark.circle")
                            }
                            Button {
                                teamsManager.updateTeam(for: player, to: .Red)
                            } label: {
                                Label("Red", systemImage: "circle.fill")
                            }
                        }
                }
            }

            // Unassigned Section
            Section(header: teamHeader(title: "Unassigned", color: .gray, count: teamsManager.unassignedMembers.count)) {
                ForEach(teamsManager.unassignedMembers, id: \.id) { player in
                    TeamMemberRow(name: player.name, team: nil)
                        .padding(6)
                        .background(RoundedRectangle(cornerRadius: 8).fill(Color(NSColor.windowBackgroundColor)))
                        .shadow(color: .black.opacity(0.03), radius: 4, x: 0, y: 2)
                        .swipeActions(edge: .leading) {
                            Button {
                                teamsManager.moveToWaitlist(player: player)
                            } label: {
                                Label("Waitlist", systemImage: "clock")
                            }
                        }
                        .swipeActions(edge: .trailing) {
                            Button {
                                teamsManager.updateTeam(for: player, to: .Black)
                            } label: {
                                Label("Black", systemImage: "circle.fill")
                            }
                            Button {
                                teamsManager.updateTeam(for: player, to: .Red)
                            } label: {
                                Label("Red", systemImage: "circle.fill")
                            }
                        }
                }
            }

            // Controls Section
            Section {
                controlsView
                    .padding()
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                    .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
            }
        }
        .listStyle(.inset)
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
        .navigationTitle("Teams")
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

    private var controlsView: some View {
        HStack(spacing: 20) {
            pickerStack(label: "Waves", selection: $selectedNumberOfWaves)
            pickerStack(label: "Courts", selection: $selectedNumberOfCourts)
            Button(action: generate) {
                Label("Generate Draws", systemImage: "shuffle")
                    .font(.headline)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
    }

    private func pickerStack(label: String, selection: Binding<Int>) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.subheadline)
                .foregroundColor(.secondary)
            Picker(label, selection: selection) {
                ForEach(1...10, id: \.self) {
                    Text("\($0)")
                }
            }
            .pickerStyle(.menu)
            .labelsHidden()
        }
    }

    private func generate() {
        if teamsManager.validateTeams() {
            teamsManager.generateDraws(
                numberOfWaves: selectedNumberOfWaves,
                numberOfCourts: selectedNumberOfCourts
            )
            alertMessage = AlertMessage(message: "Draws generated. Check console for details.")
        } else {
            alertMessage = AlertMessage(message: "Team validation failed.")
        }
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
        guard let team = team else { return .gray }
        switch team {
        case .Red: return .red
        case .Black: return .black
        }
    }
}
