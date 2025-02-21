import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var profileManager: ProfileManager
    
    @State private var newEmail = ""
    @State private var newPassword = ""
    @State private var errorMessage: String?
    @State private var successMessage: String?
    
    @State private var showDeleteAlert = false
    
    var body: some View {
        NavigationView {
            Form {
                // MARK: - Account Info Section
                Section(header: Text("Account Info")) {
                    if let user = authManager.currentUser {
                        Text(user.email ?? "Unknown")
                    } else {
                        Text("No user logged in.")
                            .foregroundColor(.secondary)
                    }
                }
                
                // MARK: - Profile Info Section
                if let profile = profileManager.userProfile {
                    Section(header: Text("Profile Info")) {
                        Text("Name: \(profile.fullName)")
                        if let bio = profile.bio, !bio.isEmpty {
                            Text("Bio: \(bio)")
                        }
                    }
                }
                
                // MARK: - Email/Password Linking or Updating
                if isPasswordLinked {
                    Section(header: Text("Update Email & Password")) {
                        TextField("New Email", text: $newEmail)
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                        
                        SecureField("New Password", text: $newPassword)
                        
                        Button("Update Email") {
                            authManager.updateEmail(newEmail: newEmail) { error in
                                if let error = error {
                                    self.errorMessage = error.localizedDescription
                                    self.successMessage = nil
                                } else {
                                    self.successMessage = "A verification email has been sent to \(newEmail). Please verify to complete the update."
                                    self.errorMessage = nil
                                }
                            }
                        }
                        
                        Button("Update Password") {
                            authManager.updatePassword(newPassword: newPassword) { error in
                                if let error = error {
                                    self.errorMessage = error.localizedDescription
                                    self.successMessage = nil
                                } else {
                                    self.successMessage = "Password updated successfully."
                                    self.errorMessage = nil
                                }
                            }
                        }
                    }
                } else {
                    Section(header: Text("Link Email & Password")) {
                        TextField("Email", text: $newEmail)
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                        
                        SecureField("Password", text: $newPassword)
                        
                        Button("Link Email & Password") {
                            authManager.linkEmailPassword(email: newEmail, password: newPassword) { error in
                                if let error = error {
                                    self.errorMessage = error.localizedDescription
                                    self.successMessage = nil
                                } else {
                                    self.successMessage = "Email & Password linked successfully."
                                    self.errorMessage = nil
                                }
                            }
                        }
                    }
                }
                
                // MARK: - Link Accounts Section (only if at least one is not linked)
                if !isGoogleLinked || !isAppleLinked {
                    Section(header: Text("Link Accounts")) {
                        if !isGoogleLinked {
                            Button("Link Google Account") {
                                let rootVC = UIApplication.shared.connectedScenes
                                    .compactMap { $0 as? UIWindowScene }
                                    .first?.windows.first?.rootViewController ?? UIViewController()
                                authManager.linkGoogleAccount(presenting: rootVC) { error in
                                    if let error = error {
                                        self.errorMessage = error.localizedDescription
                                        self.successMessage = nil
                                    } else {
                                        self.successMessage = "Google account linked successfully."
                                        self.errorMessage = nil
                                    }
                                }
                            }
                        }
                        if !isAppleLinked {
                            Button("Link Apple Account") {
                                authManager.linkAppleAccount { error in
                                    if let error = error {
                                        self.errorMessage = error.localizedDescription
                                        self.successMessage = nil
                                    } else {
                                        self.successMessage = "Apple account linked successfully."
                                        self.errorMessage = nil
                                    }
                                }
                            }
                        }
                    }
                }
                
                // MARK: - Sign Out Section
                Section {
                    Button("Sign Out") {
                        authManager.signOut { error in
                            if let error = error {
                                self.errorMessage = error.localizedDescription
                            }
                        }
                    }
                    .foregroundColor(.red)
                }
                
                // MARK: - Delete Account Section
                Section {
                    Button("Delete Account") {
                        showDeleteAlert = true
                    }
                    .foregroundColor(.red)
                }
                .alert(isPresented: $showDeleteAlert) {
                    Alert(
                        title: Text("Delete Account"),
                        message: Text("Are you sure you want to delete your account? This action cannot be undone."),
                        primaryButton: .destructive(Text("Delete")) {
                            // First, delete the user profile from Firestore
                            profileManager.deleteUserProfile { error in
                                if let error = error {
                                    self.errorMessage = error.localizedDescription
                                } else {
                                    // If profile deletion succeeds, delete the auth account
                                    authManager.deleteAccount { error in
                                        if let error = error {
                                            self.errorMessage = error.localizedDescription
                                        } else {
                                            self.successMessage = "Account deleted successfully."
                                        }
                                    }
                                }
                            }
                        },
                        secondaryButton: .cancel()
                    )
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
            .navigationTitle("Settings")
        }
    }
    
    // MARK: - Computed Properties
    
    private var isGoogleLinked: Bool {
        authManager.currentUser?.providerData.contains(where: { $0.providerID == "google.com" }) ?? false
    }
    
    private var isAppleLinked: Bool {
        authManager.currentUser?.providerData.contains(where: { $0.providerID == "apple.com" }) ?? false
    }
    
    private var isPasswordLinked: Bool {
        authManager.currentUser?.providerData.contains(where: { $0.providerID == "password" }) ?? false
    }
}
