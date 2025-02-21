import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var authManager: AuthManager
    @State private var newEmail = ""
    @State private var newPassword = ""
    @State private var errorMessage: String?
    @State private var successMessage: String?
    
    @State private var showDeleteAlert = false
    
    var body: some View {
        NavigationView {
            Form {
                // MARK: - Account Info Section
                Section(header: sectionHeader("Account Info")) {
                    if let user = authManager.currentUser {
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
                
                // MARK: - Email/Password Linking or Updating Section
                if isPasswordLinked {
                    Section(header: sectionHeader("Update Email & Password")) {
                        TextField("New Email", text: $newEmail)
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                            .modifier(RoundedFieldModifier())
                        
                        SecureField("New Password", text: $newPassword)
                            .modifier(RoundedFieldModifier())
                        
                        Button(action: {
                            authManager.updateEmail(newEmail: newEmail) { error in
                                if let error = error {
                                    self.errorMessage = error.localizedDescription
                                    self.successMessage = nil
                                } else {
                                    self.successMessage = "A verification email has been sent to \(newEmail). Please verify to complete the update."
                                    self.errorMessage = nil
                                }
                            }
                        }) {
                            Text("Update Email")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(PrimaryButtonStyle())
                        
                        Button(action: {
                            authManager.updatePassword(newPassword: newPassword) { error in
                                if let error = error {
                                    self.errorMessage = error.localizedDescription
                                    self.successMessage = nil
                                } else {
                                    self.successMessage = "Password updated successfully."
                                    self.errorMessage = nil
                                }
                            }
                        }) {
                            Text("Update Password")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(PrimaryButtonStyle())
                    }
                } else {
                    Section(header: sectionHeader("Link Email & Password")) {
                        TextField("Email", text: $newEmail)
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                            .modifier(RoundedFieldModifier())
                        
                        SecureField("Password", text: $newPassword)
                            .modifier(RoundedFieldModifier())
                        
                        Button(action: {
                            authManager.linkEmailPassword(email: newEmail, password: newPassword) { error in
                                if let error = error {
                                    self.errorMessage = error.localizedDescription
                                    self.successMessage = nil
                                } else {
                                    self.successMessage = "Email & Password linked successfully."
                                    self.errorMessage = nil
                                }
                            }
                        }) {
                            Text("Link Email & Password")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(PrimaryButtonStyle())
                    }
                }
                
                // MARK: - Link Accounts Section
                Section(header: sectionHeader("Link Accounts")) {
                    if !isGoogleLinked {
                        Button(action: {
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
                        }) {
                            Text("Link Google Account")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(PrimaryButtonStyle())
                    }
                    if !isAppleLinked {
                        Button(action: {
                            authManager.linkAppleAccount { error in
                                if let error = error {
                                    self.errorMessage = error.localizedDescription
                                    self.successMessage = nil
                                } else {
                                    self.successMessage = "Apple account linked successfully."
                                    self.errorMessage = nil
                                }
                            }
                        }) {
                            Text("Link Apple Account")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(PrimaryButtonStyle())
                    }
                }
                
                // MARK: - Sign Out Section
                Section {
                    Button(action: {
                        authManager.signOut { error in
                            if let error = error {
                                self.errorMessage = error.localizedDescription
                            }
                        }
                    }) {
                        Text("Sign Out")
                            .frame(maxWidth: .infinity)
                    }
                    .foregroundColor(.red)
                    .buttonStyle(BorderlessButtonStyle())
                }
                
                // MARK: - Delete Account Section
                Section {
                    Button(action: { showDeleteAlert = true }) {
                        Text("Delete Account")
                            .frame(maxWidth: .infinity)
                    }
                    .foregroundColor(.red)
                    .buttonStyle(BorderlessButtonStyle())
                }
                .alert(isPresented: $showDeleteAlert) {
                    Alert(
                        title: Text("Delete Account"),
                        message: Text("Are you sure you want to delete your account? This action cannot be undone."),
                        primaryButton: .destructive(Text("Delete")) {
                            authManager.deleteAccount { error in
                                if let error = error {
                                    self.errorMessage = error.localizedDescription
                                } else {
                                    self.successMessage = "Account deleted successfully."
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
            .listStyle(InsetGroupedListStyle())
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
    
    private func sectionHeader(_ title: String) -> some View {
        HStack {
            Text(title)
                .font(.headline)
                .foregroundColor(.primary)
            Spacer()
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
