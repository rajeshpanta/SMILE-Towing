import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct CustomerSignUpView: View {
    @State private var firstName: String = ""
    @State private var lastName: String = ""
    @State private var email: String = ""
    @State private var phoneNumber: String = ""
    @State private var password: String = ""
    @State private var confirmPassword: String = ""
    @State private var showPassword: Bool = false
    @State private var showConfirmPassword: Bool = false
    @State private var acceptTerms: Bool = false
    @State private var showAlert: Bool = false
    @State private var alertMessage: String = ""
    @State private var showSuccessPopup: Bool = false // For showing the success popup
    @State private var showTermsPopup: Bool = false // For showing terms and conditions popup
    @Environment(\.presentationMode) var presentationMode // For navigation back to login
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Customer Sign-Up")
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding(.top, 40)
            
            Spacer()
            
            // First Name
            TextField("First Name", text: $firstName)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.horizontal)
            
            // Last Name
            TextField("Last Name", text: $lastName)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.horizontal)
            
            // Email
            TextField("Email (e.g., name@gmail.com)", text: $email)
                .keyboardType(.emailAddress)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.horizontal)
            
            // Phone Number
            TextField("Phone Number (Optional)", text: $phoneNumber)
                .keyboardType(.numberPad)
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
            
            // Confirm Password with Eye Icon
            HStack {
                if showConfirmPassword {
                    TextField("Confirm Password", text: $confirmPassword)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding(.horizontal, 10)
                } else {
                    SecureField("Confirm Password", text: $confirmPassword)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding(.horizontal, 10)
                }
                Button(action: {
                    showConfirmPassword.toggle()
                }) {
                    Image(systemName: showConfirmPassword ? "eye" : "eye.slash")
                        .foregroundColor(.gray)
                }
                .padding(.trailing, 10)
            }
            
            // Terms and Conditions Section
            HStack(alignment: .center) {
                Toggle(isOn: $acceptTerms) {
                    HStack {
                        Text("I accept the")
                        Button(action: {
                            showTermsPopup = true
                        }) {
                            Text("Terms and Conditions")
                                .foregroundColor(.blue)
                                .underline()
                        }
                    }
                }
                .toggleStyle(SwitchToggleStyle(tint: .green))
                .padding(.horizontal)
            }
            
            // Sign-Up Button
            Button(action: {
                validateInputs()
            }) {
                Text("Sign Up")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(acceptTerms ? Color.green : Color.gray) // Dim button if not accepted
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .padding(.horizontal)
            
            Spacer()
        }
        .padding()
        .navigationTitle("Customer Sign-Up")
        .alert(isPresented: $showAlert) {
            Alert(title: Text("Validation Error"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
        }
        // Terms and Conditions Popup
        .overlay(
            Group {
                if showTermsPopup {
                    VStack(spacing: 20) {
                        Text("Terms and Conditions")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        ScrollView {
                            Text("""
                            1. Customers must provide accurate details about their location and vehicle.
                            2. Payments for services must be completed as per the agreed terms.
                            3. Customers must inspect their vehicle before and after towing and report any issues immediately.
                            4. The company is not liable for damages caused by incorrect customer information.
                            5. Both drivers and customers must treat each other respectfully and professionally.
                            """)
                            .multilineTextAlignment(.leading)
                            .padding()
                        }
                        .frame(height: 200)
                        
                        Button(action: {
                            showTermsPopup = false
                        }) {
                            Text("Close")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.red)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                        }
                        .padding(.horizontal)
                    }
                    .padding()
                    .background(Color.white)
                    .cornerRadius(20)
                    .shadow(radius: 10)
                    .frame(width: 300)
                }
            }
        )
        // Success Popup
        .overlay(
            Group {
                if showSuccessPopup {
                    VStack(spacing: 20) {
                        Text("You have been successfully signed up!")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .multilineTextAlignment(.center)
                        
                        Text("Please login now.")
                            .font(.body)
                            .foregroundColor(.gray)
                        
                        Button(action: {
                            // Close popup and navigate back to login
                            showSuccessPopup = false
                            presentationMode.wrappedValue.dismiss()
                        }) {
                            Text("OK")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                        }
                        .padding(.horizontal)
                    }
                    .padding()
                    .background(Color.white)
                    .cornerRadius(20)
                    .shadow(radius: 10)
                    .frame(width: 300)
                }
            }
        )
    }
    
    private func validateInputs() {
        // Check required fields
        if firstName.isEmpty || lastName.isEmpty || email.isEmpty {
            alertMessage = "First Name, Last Name, and Email are required."
            showAlert = true
            return
        }
        
        // Validate email domain
        if !email.matchesPattern(regex: #"^[a-zA-Z0-9._%+-]+@(gmail\.com|yahoo\.com|icloud\.com)$"#) {
            alertMessage = "Please enter a valid email ending with @gmail.com, @yahoo.com, or @icloud.com."
            showAlert = true
            return
        }
        
        // Validate password length and character rules
        if password.count < 8 || !password.matchesPattern(regex: #".*\d.*"#) {
            alertMessage = "Password must be at least 8 characters long and include at least 1 number."
            showAlert = true
            return
        }
        
        // Confirm password matches
        if password != confirmPassword {
            alertMessage = "Password and Confirm Password must match."
            showAlert = true
            return
        }
        
        // Check terms and conditions acceptance
        if !acceptTerms {
            alertMessage = "You must accept our Terms and Conditions to create an account."
            showAlert = true
            return
        }
        
        // If all validations pass, create user in Firebase Authentication
        Auth.auth().createUser(withEmail: email, password: password) { authResult, error in
            if let error = error {
                alertMessage = "Failed to sign up: \(error.localizedDescription)"
                showAlert = true
                return
            }
            
            // Save user details to Firestore
            if let user = authResult?.user {
                let db = Firestore.firestore()
                db.collection("users").document(user.uid).setData([
                    "firstName": firstName,
                    "lastName": lastName,
                    "email": email,
                    "role": "Customer" // Save the role as "Customer"
                ]) { error in
                    if let error = error {
                        alertMessage = "Failed to save user details: \(error.localizedDescription)"
                        showAlert = true
                        return
                    }
                    // Show success popup
                    showSuccessPopup = true
                }
            }
        }
    }
}

// String Extension for Regex Matching
extension String {
    func matchesPattern(regex: String) -> Bool {
        return self.range(of: regex, options: .regularExpression) != nil
    }
}
