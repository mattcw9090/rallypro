import SwiftUI
import SwiftData
import AppKit

struct SeasonalResultsView: View {
    @EnvironmentObject var seasonalResultsManager: SeasonalResultsManager
    let seasonNumber: Int

    @State private var hiddenPlayerIDs: Set<UUID> = []

    private var aggregatedResults: [(player: Player, sessionCount: Int, matchCount: Int, finalAverageScore: Double)] {
        seasonalResultsManager.aggregatedPlayers(forSeasonNumber: seasonNumber)
    }

    private var filteredResults: [(player: Player, sessionCount: Int, matchCount: Int, finalAverageScore: Double)] {
        aggregatedResults.filter { !hiddenPlayerIDs.contains($0.player.id) }
    }

    private var displayContent: some View {
        let results = filteredResults
        let scores = results.map { $0.finalAverageScore }
        let minScore = scores.min() ?? 0
        let maxScore = scores.max() ?? 1

        return List {
            HStack {
                Text("Player")
                    .font(.headline)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Text("Sessions")
                    .font(.headline)
                    .frame(width: 80, alignment: .trailing)
                Text("Avg Score")
                    .font(.headline)
                    .frame(width: 80, alignment: .trailing)
            }
            .padding(.vertical, 10)

            ForEach(results, id: \.player.id) { item in
                let fraction: Double = (maxScore > minScore)
                    ? (item.finalAverageScore - minScore) / (maxScore - minScore)
                    : 0.5
                let rowColor = Color(red: 1 - fraction, green: fraction, blue: 0).opacity(0.3)

                HStack {
                    Text(item.player.name)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Text("\(item.sessionCount)")
                        .frame(width: 80, alignment: .trailing)
                    Text(String(format: "%.1f", item.finalAverageScore))
                        .frame(width: 80, alignment: .trailing)
                }
                .padding(.vertical, 5)
                .listRowBackground(rowColor)
                .contextMenu {
                    Button(role: .destructive) {
                        hiddenPlayerIDs.insert(item.player.id)
                    } label: {
                        Label("Hide", systemImage: "eye.slash")
                    }
                }
            }
        }
        .listStyle(.inset)
    }

    var body: some View {
        NavigationStack {
            displayContent
                .navigationTitle("Season \(seasonNumber) Results")
                .toolbar {
                    if !hiddenPlayerIDs.isEmpty {
                        Button("Show All") {
                            hiddenPlayerIDs.removeAll()
                        }
                    }
                }
        }
    }
}