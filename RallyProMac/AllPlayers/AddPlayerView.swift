import SwiftUI
import SwiftData

struct AddPlayerView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var playerManager: PlayerManager
    @EnvironmentObject var seasonManager: SeasonSessionManager

    @State private var name: String = ""
    @State private var status: Player.PlayerStatus = .onWaitlist
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var isMale: Bool = true

    var body: some View {
        VStack(spacing: 16) {
            Text("Add New Player")
                .font(.largeTitle)
                .bold()

            TextField("Name", text: $name)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .onSubmit {
                    guard !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
                    addPlayer()
                }
                .submitLabel(.done)

            Picker("Status", selection: $status) {
                ForEach(Player.PlayerStatus.allCases, id: \.self) { status in
                    Text(status.rawValue).tag(status)
                }
            }
            .pickerStyle(SegmentedPickerStyle())

            Toggle("Is Male", isOn: $isMale)

            HStack(spacing: 20) {
                Button("Cancel") {
                    dismiss()
                }
                .buttonStyle(.bordered)

                Button("Save") {
                    addPlayer()
                }
                .buttonStyle(.borderedProminent)
                .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
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
        .alert("Error", isPresented: $showingAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(alertMessage)
        }
    }

    private func addPlayer() {
        do {
            try playerManager.addPlayer(
                name: name,
                status: status,
                isMale: isMale,
                latestSession: seasonManager.latestSession
            )
            dismiss()
        } catch {
            alertMessage = error.localizedDescription
            showingAlert = true
        }
    }
}
