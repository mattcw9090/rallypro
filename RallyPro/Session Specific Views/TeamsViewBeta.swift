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
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                // Unassign from team.
                                Button {
                                    updateTeam(for: participant, to: nil)
                                } label: {
                                    Label("Unassign", systemImage: "xmark")
                                }
                                .tint(.gray)
                                
                                // Switch to Black team.
                                Button {
                                    updateTeam(for: participant, to: .black)
                                } label: {
                                    Label("Switch to Black", systemImage: "moon.fill")
                                }
                                .tint(.black)
                            }
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
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                // Unassign from team.
                                Button {
                                    updateTeam(for: participant, to: nil)
                                } label: {
                                    Label("Unassign", systemImage: "xmark")
                                }
                                .tint(.gray)
                                
                                // Switch to Red team.
                                Button {
                                    updateTeam(for: participant, to: .red)
                                } label: {
                                    Label("Switch to Red", systemImage: "flame.fill")
                                }
                                .tint(.red)
                            }
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
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                // Assign to Red team.
                                Button {
                                    updateTeam(for: participant, to: .red)
                                } label: {
                                    Label("Assign Red", systemImage: "flame.fill")
                                }
                                .tint(.red)
                                
                                // Assign to Black team.
                                Button {
                                    updateTeam(for: participant, to: .black)
                                } label: {
                                    Label("Assign Black", systemImage: "moon.fill")
                                }
                                .tint(.black)
                            }
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
    
    /// Updates the team for a participant both locally and in Firestore.
    private func updateTeam(for participant: SessionParticipantBeta, to newTeam: TeamType?) {
        teamsManager.updateTeam(for: participant, to: newTeam) { error in
            if error == nil {
                if let index = teamsManager.participants.firstIndex(where: { $0.id == participant.id }) {
                    teamsManager.participants[index].team = newTeam
                }
            }
        }
    }
}
