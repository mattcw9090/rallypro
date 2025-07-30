import SwiftUI
import SwiftData

struct SessionsView: View {
    @EnvironmentObject var seasonManager: SeasonSessionManager

    @State private var expandedSeasons: [Int: Bool] = [:]
    @State private var showAlert = false
    @State private var alertMessage = ""

    var body: some View {
        VStack {
            if seasonManager.allSeasons.isEmpty {
                emptyStateView
            } else {
                seasonListView
            }
        }
        .navigationTitle("Sessions")   // still picked up by the parent split view
        .alert("Error", isPresented: $showAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(alertMessage)
        }
        .animation(.default, value: seasonManager.allSeasons.isEmpty)
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
        List {
            ForEach(seasonManager.allSeasons) { season in
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
                    deleteLatestSession: { _ in deleteLatestSession(for: season) }
                )
                .padding(.vertical, 4)
            }
        }
        .listStyle(.inset)
        .background(Color.clear)
        .safeAreaInset(edge: .bottom) {
            VStack {
                Divider()
                addSeasonButton
                    .padding(.vertical, 10)
            }
        }
    }

    private var addSeasonButton: some View {
        Button(action: addNewSeason) {
            Label("Add New Season", systemImage: "plus")
                .font(.body.bold())
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
        }
        .buttonStyle(.plain)
        .background(RoundedRectangle(cornerRadius: 10).fill(Color.accentColor))
        .foregroundColor(.white)
        .padding(.horizontal)
        .shadow(radius: 1)
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
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 6)
            } else {
                let sortedSessions = sessions.sorted { $0.sessionNumber < $1.sessionNumber }
                ForEach(sortedSessions, id: \.id) { session in
                    NavigationLink(destination: SessionDetailView(session: session)) {
                        HStack(spacing: 10) {
                            Image(systemName: "calendar.circle.fill")
                                .foregroundColor(.accentColor)
                            Text("Session \(session.sessionNumber)")
                                .font(.body)
                        }
                        .padding(.vertical, 6)
                    }
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

                NavigationLink(destination: SeasonalResultsView(seasonNumber: season.seasonNumber)) {
                    HStack(spacing: 10) {
                        Image(systemName: "chart.bar.fill")
                            .foregroundColor(.accentColor)
                        Text("Season \(season.seasonNumber) Results")
                            .font(.body)
                    }
                    .padding(.vertical, 6)
                }
            }
        } label: {
            HStack {
                Spacer().frame(width: 10)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Season \(season.seasonNumber)")
                        .font(.title3.bold())
                        .foregroundColor(isCompleted ? .primary : .blue)
                    Text(isCompleted ? "Completed" : "In Progress")
                        .font(.caption)
                        .foregroundColor(isCompleted ? .secondary : .blue)
                }
                Spacer()
            }
            .padding(.vertical, 8)
            .contextMenu {
                Button("Add Session", action: addSession)
                if isCompleted {
                    Button("Mark Incomplete", action: markIncomplete)
                } else {
                    Button("Mark Complete", action: markComplete)
                }
            }
        }
        .contentShape(Rectangle())
    }
}
