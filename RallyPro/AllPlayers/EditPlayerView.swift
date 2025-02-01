import SwiftUI
import SwiftData

struct EditPlayerView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var playerManager: PlayerManager
    @EnvironmentObject var seasonManager: SeasonSessionManager

    @Bindable var player: Player
    @State private var editedName: String = ""
    @State private var editedStatus: Player.PlayerStatus = .notInSession
    @State private var editedIsMale: Bool = true
    @State private var showingAlert = false
    @State private var alertMessage = ""

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Player Details")) {
                    TextField("Name", text: $editedName)
                        .autocapitalization(.words)
                        .disableAutocorrection(true)

                    Picker("Status", selection: $editedStatus) {
                        ForEach(Player.PlayerStatus.allCases, id: \.self) { status in
                            Text(status.rawValue).tag(status)
                        }
                    }

                    Toggle("Is Male", isOn: $editedIsMale)
                }
            }
            .navigationTitle("Edit Player")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { saveChanges() }
                        .disabled(editedName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .onAppear {
                editedName = player.name
                editedStatus = player.status
                editedIsMale = player.isMale ?? true
            }
            .alert(isPresented: $showingAlert) {
                Alert(
                    title: Text("Error"),
                    message: Text(alertMessage),
                    dismissButton: .default(Text("OK"))
                )
            }
        }
    }

    private func saveChanges() {
        do {
            try playerManager.updatePlayer(
                player: player,
                newName: editedName,
                newStatus: editedStatus,
                newIsMale: editedIsMale,
                latestSession: seasonManager.latestSession
            )
            dismiss()
        } catch {
            alertMessage = error.localizedDescription
            showingAlert = true
        }
    }
}

#Preview {
    let schema = Schema([Player.self, Season.self, Session.self, SessionParticipant.self])
    let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)

    do {
        let mockContainer = try ModelContainer(for: schema, configurations: [modelConfiguration])
        let context = mockContainer.mainContext
        let playerToEdit = Player(name: "Charlie", status: .playing, isMale: true)
        let season = Season(seasonNumber: 1)
        context.insert(season)
        let session = Session(sessionNumber: 1, season: season)
        context.insert(session)

        return NavigationStack {
            EditPlayerView(player: playerToEdit)
                .modelContainer(mockContainer)
                .environmentObject(PlayerManager(modelContext: context))
                .environmentObject(SeasonSessionManager(modelContext: context))
        }
    } catch {
        fatalError("Could not create ModelContainer: \(error)")
    }
}
