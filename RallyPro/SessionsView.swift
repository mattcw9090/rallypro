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
            .alert("Cannot Add Season", isPresented: $showAlert) {
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
                seasonNumber: season.seasonNumber,
                sessions: seasonManager.allSessions.filter { $0.season.id == season.id },
                isCompleted: season.isCompleted,
                markIncomplete: { markSeasonIncomplete(season) },
                addSession: { addSession(to: season) },
                markComplete: { markSeasonComplete(season) }
            )
        }
        .listStyle(InsetGroupedListStyle())
        .overlay(addSeasonButton, alignment: .bottom)
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
}

struct SeasonAccordionView: View {
    @Binding var isExpanded: Bool
    let seasonNumber: Int
    let sessions: [Session]
    let isCompleted: Bool
    let markIncomplete: () -> Void
    let addSession: () -> Void
    let markComplete: () -> Void

    var body: some View {
        DisclosureGroup(isExpanded: $isExpanded) {
            if sessions.isEmpty {
                Text("No sessions")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .padding(.vertical, 5)
            } else {
                // List each session
                ForEach(sessions) { session in
                    NavigationLink(destination: SessionDetailView(session: session)) {
                        HStack {
                            Image(systemName: "calendar.circle.fill")
                            Text("Session \(session.sessionNumber)")
                                .font(.body)
                        }
                        .padding(.vertical, 5)
                    }
                }
                // Navigation link for seasonal results
                NavigationLink(
                    destination: SeasonalResultsView(seasonNumber: seasonNumber)
                ) {
                    HStack {
                        Image(systemName: "chart.bar.fill")
                        Text("Season \(seasonNumber) Results")
                            .font(.body)
                    }
                    .padding(.vertical, 5)
                }
            }

            // Buttons for adding a session and marking complete/incomplete
            if !isCompleted {
                HStack(spacing: 20) {
                    Button("Add Session", action: addSession)
                        .padding(.vertical, 5)
                        .padding(.horizontal, 10)
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(6)
                        .font(.caption)

                    Button("Mark Complete", action: markComplete)
                        .padding(.vertical, 5)
                        .padding(.horizontal, 10)
                        .background(Color.orange)
                        .foregroundColor(.white)
                        .cornerRadius(6)
                        .font(.caption)
                }
                .padding(.top, 10)
            } else {
                Button("Mark Incomplete", action: markIncomplete)
                    .padding(.vertical, 5)
                    .padding(.horizontal, 10)
                    .background(Color.red)
                    .foregroundColor(.white)
                    .cornerRadius(6)
                    .font(.caption)
                    .padding(.top, 10)
            }
        } label: {
            HStack {
                Text("Season \(seasonNumber)")
                    .font(.headline)
                    .foregroundColor(isCompleted ? .black : .blue)
                Spacer()
                Text(isCompleted ? "Completed" : "In Progress")
                    .font(.subheadline)
                    .foregroundColor(isCompleted ? .black : .blue)
            }
        }
        .contentShape(Rectangle())
    }
}

#Preview {
    let schema = Schema([Season.self, Session.self])
    let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)

    do {
        let mockContainer = try ModelContainer(for: schema, configurations: [modelConfiguration])
        let context = mockContainer.mainContext

        // Insert a sample season and session for preview.
        let season1 = Season(seasonNumber: 1, isCompleted: true)
        context.insert(season1)
        let session1 = Session(sessionNumber: 1, season: season1)
        context.insert(session1)

        // Create managers using the same context.
        let playerManager = PlayerManager(modelContext: context)
        let seasonManager = SeasonSessionManager(modelContext: context)

        return NavigationStack {
            SessionsView()
                .modelContainer(mockContainer)
                .environmentObject(seasonManager)
                .environmentObject(playerManager)
        }
    } catch {
        fatalError("Could not create ModelContainer: \(error)")
    }
}
