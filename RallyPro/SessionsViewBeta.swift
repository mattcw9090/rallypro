import SwiftUI

struct SessionsViewBeta: View {
    @StateObject var manager = SeasonSessionManagerBeta()
    
    // Helper to get the latest season (if any)
    var latestSeason: SeasonBeta? {
        manager.seasons.max(by: { $0.seasonNumber < $1.seasonNumber })
    }
    
    // Sorted seasons in descending order (latest season first)
    var sortedSeasons: [SeasonBeta] {
        manager.seasons.sorted { $0.seasonNumber > $1.seasonNumber }
    }
    
    // Returns a header title for a given season with an indicator.
    func seasonHeader(for season: SeasonBeta) -> String {
        if season.id == latestSeason?.id && !season.isComplete {
            return "Season \(season.seasonNumber) (In Progress)"
        } else if season.isComplete {
            return "Season \(season.seasonNumber) (Completed)"
        } else {
            return "Season \(season.seasonNumber)"
        }
    }
    
    var body: some View {
        NavigationView {
            List {
                ForEach(sortedSeasons) { season in
                    DisclosureGroup(seasonHeader(for: season)) {
                        if let sessions = season.sessions, !sessions.isEmpty {
                            // Sort sessions in descending order (latest first)
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
                        
                        // For the latest season if it's not complete, show inline buttons.
                        if season.id == latestSeason?.id && !season.isComplete {
                            HStack {
                                Button(action: {
                                    manager.addNextSession()
                                }) {
                                    Text("Add Session")
                                }
                                .buttonStyle(.borderedProminent)
                                
                                Button(action: {
                                    manager.markSeasonAsComplete(season)
                                }) {
                                    Text("Mark Season Complete")
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
                // Global "Add Season" button at the top-right.
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        manager.addNextSeason()
                    }) {
                        Text("Add Season")
                    }
                    // Disable if the latest season exists and is not complete.
                    .disabled(latestSeason != nil && !latestSeason!.isComplete)
                }
            }
            .onAppear {
                manager.fetchSeasons()
            }
        }
    }
}
