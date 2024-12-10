import SwiftUI
import FirebaseAuth // Import FirebaseAuth for authentication
import FirebaseFirestore // Import Firestore for database access

struct DriverSignInView: View {
    @State private var email: String = UserDefaults.standard.string(forKey: "driverSavedEmail") ?? "" // Load saved email
    @State private var password: String = ""
    @State private var showPassword: Bool = false
    @State private var rememberMe: Bool = UserDefaults.standard.bool(forKey: "driverRememberMe") // Load Remember Me state
    @State private var showAlert: Bool = false
    @State private var alertMessage: String = ""
    @State private var navigateToHome: Bool = false
    @State private var showForgotPasswordView: Bool = false // To show Forgot Password screen

    var body: some View {
        VStack(spacing: 20) {
            Text("Driver Sign-In")
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding(.top, 40)

            Spacer()

            // Email
            TextField("Email (e.g., name@gmail.com)", text: $email)
                .keyboardType(.emailAddress)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.horizontal)

            // Password with Eye Icon
            HStack {
                if showPassword {
                    TextField("Password", text: $password)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding(.horizontal, 10)
                } else {
                    SecureField("Password", text: $password)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding(.horizontal, 10)
                }
                Button(action: {
                    showPassword.toggle()
                }) {
                    Image(systemName: showPassword ? "eye" : "eye.slash")
                        .foregroundColor(.gray)
                }
                .padding(.trailing, 10)
            }
            .padding(.horizontal)

            // Remember Me Toggle
            Toggle(isOn: $rememberMe) {
                Text("Remember Me")
            }
            .padding(.horizontal)

            // Login Button
            Button(action: {
                validateInputs()
            }) {
                Text("Login")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .padding(.horizontal)

            // Forgot Password Button
            Button(action: {
                showForgotPasswordView = true
            }) {
                Text("Forgot Password?")
                    .foregroundColor(.blue)
                    .underline()
                    .font(.subheadline)
            }
            .sheet(isPresented: $showForgotPasswordView) {
                ForgotPasswordView() // Show Forgot Password view
            }

            // NavigationLink outside the button to trigger navigation
            NavigationLink(destination: DriverHome(), isActive: $navigateToHome) {
                EmptyView() // Placeholder view to control navigation
            }

            // "Don't have an account?" with Sign-Up button
            HStack {
                Text("Don't have an account?")
                NavigationLink(destination: DriverSignUpView()) {
                    Text("Sign Up")
                        .foregroundColor(.blue)
                        .fontWeight(.bold)
                }
            }
            .padding(.bottom, 20)

            Spacer()
        }
        .padding()
        .navigationTitle("Driver Sign-In")
        .alert(isPresented: $showAlert) {
            Alert(title: Text("Validation Error"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
        }
        .onAppear {
            // Automatically populate email if Remember Me was checked
            if rememberMe {
                email = UserDefaults.standard.string(forKey: "driverSavedEmail") ?? ""
            }
        }
    }

    // Validation Function
    private func validateInputs() {
        if email.isEmpty || password.isEmpty {
            alertMessage = "Email and Password are required."
            showAlert = true
            return
        }

        if !email.matche(regex: #"^[a-zA-Z0-9._%+-]+@(gmail\.com|yahoo\.com|icloud\.com)$"#) {
            alertMessage = "Please enter a valid email ending with @gmail.com, @yahoo.com, or @icloud.com."
            showAlert = true
            return
        }

        Auth.auth().signIn(withEmail: email, password: password) { result, error in
            if let error = error {
                alertMessage = "Login failed: \(error.localizedDescription)"
                showAlert = true
                return
            }

            // Fetch role from Firestore
            guard let userUID = result?.user.uid else { return }
            let db = Firestore.firestore()
            db.collection("users").document(userUID).getDocument { document, error in
                if let error = error {
                    alertMessage = "Failed to fetch user role: \(error.localizedDescription)"
                    showAlert = true
                    return
                }

                // Check if role exists and matches "Driver"
                if let data = document?.data(), let role = data["role"] as? String {
                    if role == "Driver" {
                        // Save email and Remember Me state if checked
                        if rememberMe {
                            UserDefaults.standard.set(email, forKey: "driverSavedEmail")
                            UserDefaults.standard.set(true, forKey: "driverRememberMe")
                        } else {
                            UserDefaults.standard.removeObject(forKey: "driverSavedEmail")
                            UserDefaults.standard.set(false, forKey: "driverRememberMe")
                        }
                        // Navigate to DriverHome
                        navigateToHome = true
                    } else {
                        alertMessage = "You are not authorized to log in as a Driver. Please use the Customer login page."
                        showAlert = true
                    }
                } else {
                    alertMessage = "Role information is missing or invalid."
                    showAlert = true
                }
            }
        }
    }
}

// String Extension for Regex Matching
extension String {
    func matche(regex: String) -> Bool {
        return self.range(of: regex, options: .regularExpression) != nil
    }
}
