import SwiftUI
import SwiftData
import AppKit

enum DetailSegment: String, CaseIterable, Identifiable {
    case teams = "Teams"
    case draws = "Draws"
    case results = "Results"
    case payments = "Payments"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .teams:    return "person.3.fill"
        case .draws:    return "shuffle"
        case .results:  return "checkmark.circle.fill"
        case .payments: return "creditcard.fill"
        }
    }
}

struct SessionDetailView: View {
    let session: Session
    @State private var selectedSegment: DetailSegment = .teams

    @EnvironmentObject var teamsManager: TeamsManager
    @EnvironmentObject var drawsManager: DrawsManager
    @EnvironmentObject var resultsManager: ResultsManager
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        VStack(spacing: 16) {
            segmentPicker
                .padding(.horizontal)

            contentView
                .padding()
                .background(Color(NSColor.controlBackgroundColor).opacity(0.8))
                .cornerRadius(12)
                .shadow(color: .black.opacity(0.1), radius: 6, x: 0, y: 3)
                .padding(.horizontal)
        }
        .navigationTitle("Season \(session.seasonNumber) • Session \(session.sessionNumber)")
        .padding(.top)
        .toolbar {
            Button("Export") { exportPNGs() }
        }
    }

    private var segmentPicker: some View {
        Picker("View", selection: $selectedSegment) {
            ForEach(DetailSegment.allCases) { segment in
                Label(segment.rawValue, systemImage: segment.icon)
                    .tag(segment)
            }
        }
        .pickerStyle(.segmented)
    }

    @ViewBuilder
    private var contentView: some View {
        switch selectedSegment {
        case .teams:
            TeamsView(session: session).id(session.id)
        case .draws:
            DrawsView(session: session).id(session.id)
        case .results:
            ResultsView(session: session).id(session.id)
        case .payments:
            PaymentsView(session: session).id(session.id)
        }
    }

    private func exportPNGs() {
        prepareDataForExport()
        let base = "RallyPro_S\(session.seasonNumber)_Sess\(session.sessionNumber)"
        do {
            try ViewExporter.exportAsPNGs(pages: pagesForExport(), baseName: base)
        } catch {
            NSApp.presentError(error as NSError)
        }
    }

    private func prepareDataForExport() {
        teamsManager.setSession(session)
        teamsManager.refreshData()
        drawsManager.refreshData()
        resultsManager.refreshData()
        RunLoop.current.run(until: Date().addingTimeInterval(0.05))
    }

    private func pagesForExport() -> [(title: String, view: AnyView)] {
        func page<V: View>(_ title: String, @ViewBuilder _ content: () -> V) -> (String, AnyView) {
            (title, AnyView(
                ZStack {
                    Color.white
                    VStack(alignment: .leading, spacing: 16) {
                        Text(title)
                            .font(.system(size: 28, weight: .bold))
                        content()
                    }
                    .padding(24)
                }
                .environment(\.colorScheme, .light)
            ))
        }

        let teamsPage = page("Teams") {
            HStack(alignment: .top, spacing: 24) {
                teamListColumn(title: "Red Team", color: .red, rows: teamsManager.redTeamParticipants)
                teamListColumn(title: "Black Team", color: .black, rows: teamsManager.blackTeamParticipants)
            }
        }

        let drawsPage = page("Draws") {
            let matches = drawsManager.doublesMatches(for: session)
            let grouped = Dictionary(grouping: matches, by: { $0.waveNumber })
            VStack(alignment: .leading, spacing: 16) {
                ForEach(grouped.keys.sorted(), id: \.self) { wave in
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Wave \(wave)").font(.headline)
                        VStack(alignment: .leading, spacing: 6) {
                            ForEach(grouped[wave] ?? [], id: \.id) { m in
                                HStack(alignment: .firstTextBaseline, spacing: 8) {
                                    Text("\(m.redPlayer1.name) & \(m.redPlayer2.name)")
                                        .foregroundColor(.red)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                    Text("vs").bold()
                                    Text("\(m.blackPlayer1.name) & \(m.blackPlayer2.name)")
                                        .foregroundColor(.black)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                    if m.redTeamScoreFirstSet + m.blackTeamScoreFirstSet +
                                        m.redTeamScoreSecondSet + m.blackTeamScoreSecondSet > 0 {
                                        Text("Score: \(m.redTeamScoreFirstSet)-\(m.blackTeamScoreFirstSet), \(m.redTeamScoreSecondSet)-\(m.blackTeamScoreSecondSet)")
                                            .font(.footnote)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                                .padding(8)
                                .background(Color.gray.opacity(0.08))
                                .cornerRadius(6)
                            }
                        }
                    }
                }
            }
        }

        let resultsPage = page("Results") {
            let totalRed = resultsManager.totalRedScore(for: session)
            let totalBlack = resultsManager.totalBlackScore(for: session)
            let rows = resultsManager.participantScores(for: session)

            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    VStack(alignment: .leading) {
                        Text("Red Team").font(.subheadline)
                        Text("\(totalRed)").font(.title).foregroundColor(.red)
                    }
                    Spacer()
                    VStack(alignment: .trailing) {
                        Text("Black Team").font(.subheadline)
                        Text("\(totalBlack)").font(.title).foregroundColor(.black)
                    }
                }
                .padding()
                .background(Color.gray.opacity(0.08))
                .cornerRadius(8)

                VStack(alignment: .leading, spacing: 8) {
                    Text("Player Net Score Differences").font(.headline)
                    ForEach(rows, id: \.0) { name, score in
                        HStack {
                            Text(name).frame(maxWidth: .infinity, alignment: .leading)
                            Text("\(score) points").frame(maxWidth: .infinity, alignment: .trailing)
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
        }

        return [teamsPage, drawsPage, resultsPage]
    }
}

@ViewBuilder
private func teamListColumn(title: String, color: Color, rows: [SessionParticipant]) -> some View {
    VStack(alignment: .leading, spacing: 8) {
        HStack(spacing: 8) {
            Circle().fill(color).frame(width: 10, height: 10)
        }
        ForEach(Array(rows.enumerated()), id: \.element.id) { index, p in
            HStack(spacing: 8) {
                Text("\(index + 1)").bold().frame(width: 24, alignment: .trailing)
                Text(p.player.name)
                Spacer()
            }
            .padding(6)
            .background(Color.gray.opacity(0.05))
            .cornerRadius(6)
        }
    }
}
