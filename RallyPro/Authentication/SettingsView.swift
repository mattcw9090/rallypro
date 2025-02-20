import SwiftUI
import FirebaseAuth

struct SettingsView: View {
    @EnvironmentObject var session: SessionStore
    
    @State private var newEmail = ""
    @State private var newPassword = ""
    @State private var errorMessage: String?
    @State private var successMessage: String?
    
    var body: some View {
        NavigationView {
            Form {
                // MARK: - Account Info Section
                Section(header: sectionHeader("Account Info")) {
                    if let user = session.currentUser {
                        HStack {
                            Image(systemName: "person.crop.circle.fill")
                                .font(.title2)
                                .foregroundColor(.blue)
                            Text(user.email ?? "Unknown")
                                .font(.body)
                        }
                    } else {
                        Text("No user logged in.")
                            .foregroundColor(.secondary)
                    }
                }
                
                // MARK: - Update Email Section
                Section(header: sectionHeader("Update Email")) {
                    TextField("New Email", text: $newEmail)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                        .modifier(RoundedFieldModifier())
                    
                    Button(action: updateEmail) {
                        Text("Update Email")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(PrimaryButtonStyle())
                }
                
                // MARK: - Update Password Section
                Section(header: sectionHeader("Update Password")) {
                    SecureField("New Password", text: $newPassword)
                        .modifier(RoundedFieldModifier())
                    
                    Button(action: updatePassword) {
                        Text("Update Password")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(PrimaryButtonStyle())
                }
                
                // MARK: - Sign Out Section
                Section {
                    Button(action: { session.signOut() }) {
                        Text("Sign Out")
                            .frame(maxWidth: .infinity)
                    }
                    .foregroundColor(.red)
                    .buttonStyle(BorderlessButtonStyle())
                }
                
                // MARK: - Status Messages
                if let errorMessage = errorMessage {
                    Section {
                        Text(errorMessage)
                            .foregroundColor(.red)
                    }
                }
                
                if let successMessage = successMessage {
                    Section {
                        Text(successMessage)
                            .foregroundColor(.green)
                    }
                }
            }
            .listStyle(InsetGroupedListStyle())
            .navigationTitle("Settings")
        }
    }
    
    // MARK: - Helper Section Header
    private func sectionHeader(_ title: String) -> some View {
        HStack {
            Text(title)
                .font(.headline)
                .foregroundColor(.primary)
            Spacer()
        }
    }
    
    // MARK: - Email Update Function
    private func updateEmail() {
        guard !newEmail.isEmpty else {
            errorMessage = "Please enter a new email address."
            successMessage = nil
            return
        }
        
        guard let user = Auth.auth().currentUser else {
            errorMessage = "No user logged in."
            successMessage = nil
            return
        }
        
        user.sendEmailVerification(beforeUpdatingEmail: newEmail) { error in
            if let error = error {
                errorMessage = error.localizedDescription
                successMessage = nil
            } else {
                successMessage = "A verification email has been sent to \(newEmail). Please verify to complete the update."
                errorMessage = nil
            }
        }
    }
    
    // MARK: - Password Update Function
    private func updatePassword() {
        guard !newPassword.isEmpty else {
            errorMessage = "Please enter a new password."
            successMessage = nil
            return
        }
        
        Auth.auth().currentUser?.updatePassword(to: newPassword) { error in
            if let error = error {
                errorMessage = error.localizedDescription
                successMessage = nil
            } else {
                successMessage = "Password updated successfully."
                errorMessage = nil
            }
        }
    }
}

// MARK: - Custom Modifiers & Styles

struct RoundedFieldModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(10)
            .background(Color(UIColor.secondarySystemBackground))
            .cornerRadius(8)
    }
}

struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding()
            .background(Color.blue.opacity(configuration.isPressed ? 0.7 : 1.0))
            .foregroundColor(.white)
            .cornerRadius(8)
    }
}
