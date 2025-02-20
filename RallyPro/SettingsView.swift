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
                Section(header: Text("Account Info")) {
                    if let user = session.currentUser {
                        Text("Logged in as: \(user.email ?? "Unknown")")
                    } else {
                        Text("No user logged in.")
                    }
                }
                
                Section(header: Text("Update Email")) {
                    TextField("New Email", text: $newEmail)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                    Button("Update Email") {
                        updateEmail()
                    }
                }
                
                Section(header: Text("Update Password")) {
                    SecureField("New Password", text: $newPassword)
                    Button("Update Password") {
                        updatePassword()
                    }
                }
                
                Section {
                    Button("Sign Out") {
                        session.signOut()
                    }
                    .foregroundColor(.red)
                }
                
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
            .navigationTitle("Settings")
        }
    }
    
    // Updated email update using sendEmailVerification(beforeUpdatingEmail:)
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
    
    // Password update remains the same.
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
