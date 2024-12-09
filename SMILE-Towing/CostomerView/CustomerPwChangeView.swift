import SwiftUI
import FirebaseAuth

struct CustomerPwChangeView: View {
    @State private var newPassword: String = ""
    @State private var confirmPassword: String = ""
    @State private var showError: Bool = false // State for error message
    @State private var errorMessage: String = "" // Detailed error message
    @State private var showSuccess: Bool = false // State for success message
    @Environment(\.presentationMode) var presentationMode

    var onSave: ((String) -> Void)? // Callback to update the password

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Change Password")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding(.top, 20)

                VStack(alignment: .leading, spacing: 15) {
                    Text("New Password")
                        .font(.headline)
                    SecureField("Enter new password", text: $newPassword)
                        .textFieldStyle(RoundedBorderTextFieldStyle())

                    Text("Confirm New Password")
                        .font(.headline)
                    SecureField("Confirm new password", text: $confirmPassword)
                        .textFieldStyle(RoundedBorderTextFieldStyle())

                    if showError {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .font(.subheadline)
                    }
                }
                .padding(.horizontal)

                Button(action: {
                    handleChangePassword()
                }) {
                    Text("Save Password")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                        .padding(.horizontal)
                }
                .padding(.top, 20)

                if showSuccess {
                    Text("Password updated successfully!")
                        .foregroundColor(.green)
                        .font(.subheadline)
                }

                Spacer()
            }
            .navigationTitle("Change Password")
        }
    }

    // MARK: - Handle Change Password
    private func handleChangePassword() {
        // Validate passwords
        guard !newPassword.isEmpty, !confirmPassword.isEmpty else {
            showError = true
            errorMessage = "Both fields are required."
            return
        }

        guard newPassword == confirmPassword else {
            showError = true
            errorMessage = "Passwords do not match."
            return
        }

        guard let user = Auth.auth().currentUser else {
            showError = true
            errorMessage = "No authenticated user found."
            return
        }

        // Update the password in Firebase
        user.updatePassword(to: newPassword) { error in
            if let error = error {
                showError = true
                errorMessage = "Failed to update password: \(error.localizedDescription)"
                return
            }

            // Success
            showError = false
            showSuccess = true
            onSave?(newPassword) // Call the callback if needed

            // Automatically dismiss the view after a delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                presentationMode.wrappedValue.dismiss()
            }
        }
    }
}
