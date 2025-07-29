import SwiftUI
import SwiftData

struct SessionsView: View {
    @EnvironmentObject var seasonManager: SeasonSessionManager

    @State private var expandedSeasons: [Int: Bool] = [:]
    @State private var showAlert = false
    @State private var alertMessage = ""

    var body: some View {
        NavigationStack {
            VStack {
                if seasonManager.allSeasons.isEmpty {
                    emptyStateView
                } else {
                    seasonListView
                }
            }
            .navigationTitle("Sessions")
            .alert("Error", isPresented: $showAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(alertMessage)
            }
            .animation(.default, value: seasonManager.allSeasons.isEmpty)
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "tray")
                .resizable()
                .scaledToFit()
                .frame(width: 100, height: 100)
                .foregroundColor(.gray)
                .accessibilityHidden(true)

            Text("No Seasons Available")
                .font(.title2)
                .foregroundColor(.gray)

            Text("Start by adding a new season to get started.")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Button(action: addNewSeason) {
                Text("Add New Season")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
            .padding(.horizontal)
        }
        .padding()
        .transition(.opacity)
    }

    private var seasonListView: some View {
        List(seasonManager.allSeasons) { season in
            SeasonAccordionView(
                isExpanded: Binding(
                    get: { expandedSeasons[season.seasonNumber] ?? false },
                    set: { expandedSeasons[season.seasonNumber] = $0 }
                ),
                season: season,
                sessions: seasonManager.allSessions.filter { $0.season.id == season.id },
                isCompleted: season.isCompleted,
                markIncomplete: { markSeasonIncomplete(season) },
                addSession: { addSession(to: season) },
                markComplete: { markSeasonComplete(season) },
                // Here we ignore the incoming parameter because we already know the season.
                deleteLatestSession: { _ in deleteLatestSession(for: season) }
            )
        }
        .listStyle(.inset)
        .safeAreaInset(edge: .bottom) {
            addSeasonButton
                .padding()
                .background(.ultraThinMaterial)
        }
    }

    private var addSeasonButton: some View {
        Button("Add New Season", action: addNewSeason)
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(8)
            .padding()
    }

    private func addNewSeason() {
        do {
            try seasonManager.createNewSeason()
        } catch {
            alertMessage = error.localizedDescription
            showAlert = true
        }
    }

    private func addSession(to season: Season) {
        do {
            try seasonManager.createSession(for: season)
        } catch {
            print("Error creating session: \(error)")
        }
    }

    private func markSeasonComplete(_ season: Season) {
        do {
            try seasonManager.updateSeasonCompletion(season, completed: true)
        } catch {
            print("Error updating season: \(error)")
        }
    }

    private func markSeasonIncomplete(_ season: Season) {
        guard let latest = seasonManager.latestSeason, season.id == latest.id else { return }
        do {
            try seasonManager.updateSeasonCompletion(season, completed: false)
        } catch {
            print("Error updating season: \(error)")
        }
    }
    
    private func deleteLatestSession(for season: Season) {
        do {
            try seasonManager.deleteLatestSession(for: season)
        } catch {
            alertMessage = error.localizedDescription
            showAlert = true
        }
    }
}

struct SeasonAccordionView: View {
    @Binding var isExpanded: Bool
    let season: Season
    let sessions: [Session]
    let isCompleted: Bool
    let markIncomplete: () -> Void
    let addSession: () -> Void
    let markComplete: () -> Void
    let deleteLatestSession: (Season) -> Void

    var body: some View {
        DisclosureGroup(isExpanded: $isExpanded) {
            if sessions.isEmpty {
                Text("No sessions")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .padding(.vertical, 5)
            } else {
                // Sort sessions in ascending order (oldest to latest)
                let sortedSessions = sessions.sorted { $0.sessionNumber < $1.sessionNumber }
                ForEach(sortedSessions, id: \.id) { session in
                    NavigationLink(destination: SessionDetailView(session: session)) {
                        HStack {
                            Image(systemName: "calendar.circle.fill")
                            Text("Session \(session.sessionNumber)")
                                .font(.body)
                        }
                        .padding(.vertical, 5)
                    }
                    // Add swipe action only for the latest session.
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        if session == sortedSessions.last {
                            Button(role: .destructive) {
                                deleteLatestSession(season)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                }
                // Navigation link for seasonal results.
                NavigationLink(
                    destination: SeasonalResultsView(seasonNumber: season.seasonNumber)
                ) {
                    HStack {
                        Image(systemName: "chart.bar.fill")
                        Text("Season \(season.seasonNumber) Results")
                            .font(.body)
                    }
                    .padding(.vertical, 5)
                }
            }
        } label: {
            HStack {
                Text("Season \(season.seasonNumber)")
                    .font(.headline)
                    .foregroundColor(isCompleted ? .black : .blue)
                Spacer()
                Text(isCompleted ? "Completed" : "In Progress")
                    .font(.subheadline)
                    .foregroundColor(isCompleted ? .black : .blue)
            }
            // Attach a context menu to the header so the actions are separate from the tap area.
            .contextMenu {
                Button("Add Session", action: addSession)
                if !isCompleted {
                    Button("Mark Complete", action: markComplete)
                } else {
                    Button("Mark Incomplete", action: markIncomplete)
                }
            }
        }
        .contentShape(Rectangle()) // Makes sure the tap area for the disclosure group is only on the header.
    }
}
