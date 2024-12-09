import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct DriverProfileView: View {
    @State private var fullName: String = ""
    @State private var email: String = ""
    @State private var phoneNumber: String = ""
    @State private var pronouns: String = ""
    @State private var password: String = "********" // Masked password
    @State private var showPasswordChangeView: Bool = false
    @State private var profileImage: Image? = Image(systemName: "person.crop.circle")
    @State private var showNotification: Bool = false // Notification state
    @State private var notificationMessage: String = "" // Notification message
    @State private var showAlert: Bool = false
    @State private var alertMessage: String = ""
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Driver Account Info")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding(.top, 20)

                profileImage?
                    .resizable()
                    .scaledToFill()
                    .frame(width: 100, height: 100)
                    .clipShape(Circle())
                    .padding()

                VStack(alignment: .leading, spacing: 15) {
                    VStack(alignment: .leading) {
                        Text("Full Name")
                            .font(.headline)
                        TextField("Full Name", text: $fullName)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }

                    VStack(alignment: .leading) {
                        Text("Email")
                            .font(.headline)
                        TextField("Email", text: $email)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .disabled(true) // Non-editable email
                    }

                    VStack(alignment: .leading) {
                        Text("Phone Number")
                            .font(.headline)
                        TextField("Phone Number", text: $phoneNumber)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }

                    VStack(alignment: .leading) {
                        Text("Pronouns")
                            .font(.headline)
                        TextField("Pronouns", text: $pronouns)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }

                    VStack(alignment: .leading) {
                        Text("Password")
                            .font(.headline)
                        HStack {
                            Text(password)
                                .foregroundColor(.gray)
                                .padding(.leading, 10)

                            Spacer()

                            Button(action: {
                                showPasswordChangeView = true
                            }) {
                                Text("Change Password")
                                    .foregroundColor(.blue)
                                    .underline()
                            }
                        }
                        .padding(10)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                    }
                }
                .padding(.horizontal)

                Button(action: {
                    saveProfileChanges()
                }) {
                    Text("Save Changes")
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
            .sheet(isPresented: $showPasswordChangeView) {
                DriverPwChangeView(
                    onSave: { newPassword in
                        password = "********" // Mask updated password
                        notificationMessage = "Password Updated"
                        showNotification = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                            showNotification = false
                        }
                    }
                )
            }
            .overlay(
                // Notification View
                VStack {
                    if showNotification {
                        Text(notificationMessage)
                            .font(.headline)
                            .padding()
                            .background(Color.green)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                            .transition(.move(edge: .top))
                            .animation(.easeInOut, value: showNotification)
                    }
                    Spacer()
                }
                .padding(.top, 40),
                alignment: .top
            )
            .onAppear {
                fetchDriverDetails()
            }
        }
    }

    private func fetchDriverDetails() {
        guard let userUID = Auth.auth().currentUser?.uid else {
            alertMessage = "User not authenticated."
            showAlert = true
            return
        }

        let db = Firestore.firestore()
        db.collection("users").document(userUID).getDocument { document, error in
            if let error = error {
                alertMessage = "Failed to fetch profile details: \(error.localizedDescription)"
                showAlert = true
                return
            }

            if let data = document?.data() {
                fullName = "\(data["firstName"] as? String ?? "") \(data["lastName"] as? String ?? "")"
                email = data["email"] as? String ?? ""
                phoneNumber = data["phoneNumber"] as? String ?? ""
                pronouns = data["pronouns"] as? String ?? ""
            }
        }
    }

    private func saveProfileChanges() {
        guard let userUID = Auth.auth().currentUser?.uid else {
            alertMessage = "User not authenticated."
            showAlert = true
            return
        }

        let db = Firestore.firestore()
        db.collection("users").document(userUID).updateData([
            "firstName": fullName.components(separatedBy: " ").first ?? "",
            "lastName": fullName.components(separatedBy: " ").last ?? "",
            "phoneNumber": phoneNumber,
            "pronouns": pronouns
        ]) { error in
            if let error = error {
                alertMessage = "Failed to save changes: \(error.localizedDescription)"
                showAlert = true
            } else {
                notificationMessage = "Information Updated"
                showNotification = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    showNotification = false
                }
            }
        }
    }
}
