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
                    Button("Export") {
                        exportPNGs()
                    }
                }
        }
    }

    private func exportPNGs() {
        let base = "RallyPro_Season\(seasonNumber)_Results"
        do {
            try ViewExporter.exportAsPNGs(pages: pagesForExport(), baseName: base)
        } catch {
            NSApp.presentError(error as NSError)
        }
    }

    private func pagesForExport() -> [(title: String, view: AnyView)] {
        let results = filteredResults
        let scores = results.map { $0.finalAverageScore }
        let minScore = scores.min() ?? 0
        let maxScore = scores.max() ?? 1

        let targetWidth: CGFloat = 1600
        let targetHeight: CGFloat = 2000
        let titleHeight: CGFloat = 36
        let headerHeight: CGFloat = 44
        let rowEstimate: CGFloat = 30
        let paddingVertical: CGFloat = 48
        let spacingAfterTitle: CGFloat = 16
        let estimatedTotalHeight = titleHeight + spacingAfterTitle + headerHeight
            + CGFloat(results.count) * rowEstimate + paddingVertical
        let scale = min(1.0, targetHeight / max(estimatedTotalHeight, 1))

        func header() -> some View {
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
            .overlay(alignment: .bottom) {
                Rectangle()
                    .frame(height: 1)
                    .foregroundColor(Color.black.opacity(0.1))
            }
        }

        func row(_ item: (player: Player, sessionCount: Int, matchCount: Int, finalAverageScore: Double)) -> some View {
            let fraction: Double = (maxScore > minScore)
                ? (item.finalAverageScore - minScore) / (maxScore - minScore)
                : 0.5
            let rowColor = Color(red: 1 - fraction, green: fraction, blue: 0).opacity(0.3)

            return HStack(spacing: 0) {
                Text(item.player.name)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 6)
                Text("\(item.sessionCount)")
                    .frame(width: 80, alignment: .trailing)
                    .padding(.vertical, 6)
                Text(String(format: "%.1f", item.finalAverageScore))
                    .frame(width: 80, alignment: .trailing)
                    .padding(.vertical, 6)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(rowColor)
            .overlay(alignment: .bottom) {
                Rectangle()
                    .frame(height: 0.5)
                    .foregroundColor(Color.black.opacity(0.1))
            }
        }

        func page<V: View>(_ title: String, scale: CGFloat, @ViewBuilder _ content: () -> V) -> (String, AnyView) {
            (title, AnyView(
                ZStack(alignment: .topLeading) {
                    Color.white
                    VStack(alignment: .leading, spacing: 16) {
                        Text(title).font(.system(size: 28, weight: .bold))
                        content()
                    }
                    .padding(24)
                    .scaleEffect(scale, anchor: .topLeading)
                }
                .environment(\.colorScheme, .light)
            ))
        }

        let singlePage = page("Season \(seasonNumber) Results", scale: scale) {
            if results.isEmpty {
                Text("No results to display.")
                    .foregroundStyle(.secondary)
            } else {
                VStack(spacing: 0) {
                    header()
                    ForEach(results, id: \.player.id) { item in
                        row(item)
                    }
                }
            }
        }

        return [singlePage]
    }
}
