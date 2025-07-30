import SwiftUI
import SwiftData

enum DetailSegment: String, CaseIterable, Identifiable {
    case teams = "Teams"
    case draws = "Draws"
    case results = "Results"
    case payments = "Payments"

    var id: String { rawValue }
}

struct SessionDetailView: View {
    let session: Session
    @State private var selectedSegment: DetailSegment = .teams

    var body: some View {
        NavigationStack {
            ZStack {
                // Subtle background gradient for a modern touch
                LinearGradient(
                    gradient: Gradient(colors: [Color.blue.opacity(0.2), Color.purple.opacity(0.2)]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                VStack(spacing: 16) {
                    // Enhanced segmented picker
                    Picker(selection: $selectedSegment) {
                        ForEach(DetailSegment.allCases) { segment in
                            Text(segment.rawValue)
                                .font(.headline)
                                .padding(.vertical, 4)
                        }
                    } label: {}
                    .pickerStyle(.segmented)
                    .controlSize(.large)
                    .padding(.horizontal)

                    // Card-like container for content
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
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.white.opacity(0.85))
                    )
                    .shadow(color: Color.black.opacity(0.15), radius: 8, x: 0, y: 4)
                    .animation(.easeInOut(duration: 0.25), value: selectedSegment)
                }
                .padding()
            }
            .navigationTitle("Season \(session.seasonNumber) Session \(session.sessionNumber)")
            .accentColor(.purple)
        }
    }
}
