import SwiftUI
import SwiftData

struct EditPlayerView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var playerManager: PlayerManager
    @EnvironmentObject var seasonManager: SeasonSessionManager

    @Bindable var player: Player
    @State private var editedName: String = ""
    @State private var editedStatus: Player.PlayerStatus = .notInSession
    @State private var editedIsMale: Bool = true
    @State private var showingAlert = false
    @State private var alertMessage = ""

    var body: some View {
        VStack(spacing: 16) {
            Text("Edit Player")
                .font(.largeTitle)
                .bold()

            TextField("Name", text: $editedName)
                .textFieldStyle(RoundedBorderTextFieldStyle())

            Picker("Status", selection: $editedStatus) {
                ForEach(Player.PlayerStatus.allCases, id: \.self) { status in
                    Text(status.rawValue).tag(status)
                }
            }
            .pickerStyle(SegmentedPickerStyle())

            Toggle("Is Male", isOn: $editedIsMale)

            HStack(spacing: 20) {
                Button("Cancel") {
                    dismiss()
                }
                .buttonStyle(.bordered)

                Button("Save") {
                    saveChanges()
                }
                .buttonStyle(.borderedProminent)
                .disabled(editedName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .padding()
        .background(
            LinearGradient(
                gradient: Gradient(colors: [Color.blue.opacity(0.1), Color.white]),
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .cornerRadius(12)
        .padding()
        .onAppear {
            editedName = player.name
            editedStatus = player.status
            editedIsMale = player.isMale ?? true
        }
        .alert("Error", isPresented: $showingAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(alertMessage)
        }
    }

    private func saveChanges() {
        do {
            try playerManager.updatePlayerInfo(
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
