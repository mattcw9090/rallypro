import SwiftUI

struct SessionsViewBeta: View {
    @StateObject var manager = SeasonSessionManagerBeta()

    var body: some View {
        NavigationView {
            List {
                ForEach(manager.seasons) { season in
                    DisclosureGroup("Season \(season.seasonNumber)") {
                        if let sessions = season.sessions, !sessions.isEmpty {
                            ForEach(sessions) { session in
                                Text("Session \(session.sessionNumber)")
                                    .padding(.leading, 20)
                            }
                        } else {
                            Text("No sessions available")
                                .foregroundColor(.gray)
                                .padding(.leading, 20)
                        }
                    }
                    .padding(.vertical, 5)
                }
            }
            .listStyle(InsetGroupedListStyle())
            .navigationTitle("Sessions")
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    // Global "Add Next Season" Button
                    Button {
                        manager.addNextSeason()
                    } label: {
                        Label("Add Next Season", systemImage: "plus.square.on.square")
                    }
                    // Global "Add Next Session" Button
                    Button {
                        manager.addNextSession()
                    } label: {
                        Label("Add Next Session", systemImage: "plus.circle")
                    }
                }
            }
            .onAppear {
                manager.fetchSeasons()
            }
        }
    }
}
