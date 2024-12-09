import SwiftUI
import FirebaseAuth

struct DriverPwChangeView: View {
    @State private var newPassword: String = ""
    @State private var confirmPassword: String = ""
    @State private var showError: Bool = false // State for showing error messages
    @Environment(\.presentationMode) var presentationMode
    
    var onSave: ((String) -> Void)? // Callback function for saving the password

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
                        Text("Passwords do not match")
                            .foregroundColor(.red)
                            .font(.subheadline)
                    }
                }
                .padding(.horizontal)

                Button(action: {
                    if newPassword == confirmPassword {
                        updatePassword(newPassword)
                    } else {
                        showError = true // Show error if passwords do not match
                    }
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

                Spacer()
            }
            .navigationTitle("Change Password")
        }
    }

    private func updatePassword(_ newPassword: String) {
        Auth.auth().currentUser?.updatePassword(to: newPassword) { error in
            if let error = error {
                print("Error updating password: \(error.localizedDescription)")
            } else {
                onSave?(newPassword) // Pass the new password to the callback function
                presentationMode.wrappedValue.dismiss() // Dismiss the view
            }
        }
    }
}
