import SwiftUI
import SwiftData

enum DetailSegment: String, CaseIterable, Identifiable {
    case teams = "Teams"
    case draws = "Draws"
    case results = "Results"
    case payments = "Payments"
    
    var id: String { rawValue }
    var icon: String {
        switch self {
        case .teams: return "person.3.fill"
        case .draws: return "shuffle"
        case .results: return "checkmark.circle.fill"
        case .payments: return "creditcard.fill"
        }
    }
}

struct SessionDetailView: View {
    let session: Session
    @State private var selectedSegment: DetailSegment = .teams

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Segmented Picker with Icons and Material Background
                Picker("View", selection: $selectedSegment) {
                    ForEach(DetailSegment.allCases) { segment in
                        Label(segment.rawValue, systemImage: segment.icon)
                            .tag(segment)
                    }
                }
                .pickerStyle(.segmented)
                .padding(8)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 8))
                .padding(.horizontal)
                .padding(.top)

                Divider()

                // Content Card
                Group {
                    switch selectedSegment {
                    case .teams:
                        TeamsView(session: session)
                    case .draws:
                        DrawsView(session: session)
                    case .results:
                        ResultsView(session: session)
                    case .payments:
                        PaymentsView(session: session)
                    }
                }
                .padding()
                .background(Color(NSColor.controlBackgroundColor).opacity(0.8))
                .cornerRadius(12)
                .shadow(color: .black.opacity(0.1), radius: 6, x: 0, y: 3)
                .padding()
            }
            .navigationTitle("Season \(session.seasonNumber) • Session \(session.sessionNumber)")
        }
    }
}
