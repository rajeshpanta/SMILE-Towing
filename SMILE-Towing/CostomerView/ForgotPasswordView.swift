import SwiftUI
import FirebaseAuth

struct ForgotPasswordView: View {
    @State private var email: String = ""
    @State private var showAlert: Bool = false
    @State private var alertMessage: String = ""

    var body: some View {
        VStack(spacing: 20) {
            Text("Forgot Password")
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding(.top, 40)
            
            Spacer()
            
            TextField("Enter your registered email", text: $email)
                .keyboardType(.emailAddress)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.horizontal)
            
            Button(action: {
                sendPasswordResetEmail()
            }) {
                Text("Send Reset Link")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .padding(.horizontal)
            
            Spacer()
        }
        .padding()
        .navigationTitle("Forgot Password")
        .alert(isPresented: $showAlert) {
            Alert(title: Text("Reset Password"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
        }
    }

    private func sendPasswordResetEmail() {
        guard email.matches(regex: #"^[a-zA-Z0-9._%+-]+@(gmail\.com|yahoo\.com|icloud\.com)$"#) else {
            alertMessage = "Please enter a valid email ending with @gmail.com, @yahoo.com, or @icloud.com."
            showAlert = true
            return
        }

        Auth.auth().sendPasswordReset(withEmail: email) { error in
            if let error = error {
                // Generic error message for security purposes
                alertMessage = "If the email is registered, a password reset link has been sent."
            } else {
                alertMessage = "If the email is registered, a password reset link has been sent."
            }
            showAlert = true
        }
    }
}
