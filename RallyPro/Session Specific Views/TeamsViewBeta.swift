import SwiftUI

struct TeamsViewBeta: View {
    let session: SessionBeta
    
    @StateObject private var teamsManager = TeamsManagerBeta()
    
    // Group participants by team.
    private var redTeam: [SessionParticipantBeta] {
        teamsManager.participants.filter { $0.team == .red }
    }
    
    private var blackTeam: [SessionParticipantBeta] {
        teamsManager.participants.filter { $0.team == .black }
    }
    
    private var unassigned: [SessionParticipantBeta] {
        teamsManager.participants.filter { $0.team == nil }
    }
    
    var body: some View {
        List {
            Section(header: Text("Red Team")) {
                if redTeam.isEmpty {
                    Text("None")
                        .foregroundColor(.gray)
                } else {
                    ForEach(redTeam) { participant in
                        Text(participant.player.name)
                    }
                }
            }
            
            Section(header: Text("Black Team")) {
                if blackTeam.isEmpty {
                    Text("None")
                        .foregroundColor(.gray)
                } else {
                    ForEach(blackTeam) { participant in
                        Text(participant.player.name)
                    }
                }
            }
            
            Section(header: Text("Unassigned")) {
                if unassigned.isEmpty {
                    Text("None")
                        .foregroundColor(.gray)
                } else {
                    ForEach(unassigned) { participant in
                        Text(participant.player.name)
                    }
                }
            }
        }
        .listStyle(InsetGroupedListStyle())
        .navigationTitle("Teams")
        .onAppear {
            teamsManager.fetchParticipants(for: session.id)
        }
    }
}
