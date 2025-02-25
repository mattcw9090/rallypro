import SwiftUI

struct SessionsViewBeta: View {
    @StateObject var manager = SeasonSessionManagerBeta()
    
    // Helper to get the latest season (if any).
    var latestSeason: SeasonBeta? {
        manager.seasons.max(by: { $0.seasonNumber < $1.seasonNumber })
    }
    
    // Sorted seasons in descending order (latest season first)
    var sortedSeasons: [SeasonBeta] {
        manager.seasons.sorted { $0.seasonNumber > $1.seasonNumber }
    }
    
    var body: some View {
        NavigationView {
            List {
                ForEach(sortedSeasons) { season in
                    DisclosureGroup("Season \(season.seasonNumber)") {
                        if let sessions = season.sessions, !sessions.isEmpty {
                            // Sort sessions in descending order (latest first) and wrap each row in a NavigationLink.
                            ForEach(sessions.sorted { $0.sessionNumber > $1.sessionNumber }) { session in
                                NavigationLink {
                                    SessionDetailViewBeta(session: session, seasonNumber: season.seasonNumber)
                                } label: {
                                    Text("Session \(session.sessionNumber)")
                                        .padding(.leading, 20)
                                }
                            }
                        } else {
                            Text("No sessions available")
                                .foregroundColor(.gray)
                                .padding(.leading, 20)
                        }
                        
                        // If this is the latest season and it's not complete,
                        // show buttons to add the next session and mark it complete.
                        if season.id == latestSeason?.id && !season.isComplete {
                            VStack(alignment: .leading, spacing: 10) {
                                Button(action: {
                                    manager.addNextSession()
                                }) {
                                    HStack {
                                        Image(systemName: "plus.circle")
                                        Text("Add Next Session")
                                    }
                                    .frame(maxWidth: .infinity)
                                }
                                .buttonStyle(.borderedProminent)
                                
                                Button(action: {
                                    manager.markSeasonAsComplete(season)
                                }) {
                                    HStack {
                                        Image(systemName: "checkmark.circle")
                                        Text("Mark Season Complete")
                                    }
                                    .frame(maxWidth: .infinity)
                                }
                                .buttonStyle(.bordered)
                            }
                            .padding(.top, 5)
                        }
                    }
                    .padding(.vertical, 5)
                }
            }
            .listStyle(InsetGroupedListStyle())
            .navigationTitle("Sessions")
            .toolbar {
                // Top right global "Add Next Season" button.
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        manager.addNextSeason()
                    }) {
                        HStack {
                            Image(systemName: "plus.square.on.square")
                            Text("Add Next Season")
                        }
                    }
                    // Disable if the latest season is not complete.
                    .disabled(latestSeason != nil && !latestSeason!.isComplete)
                }
            }
            .onAppear {
                manager.fetchSeasons()
            }
        }
    }
}
