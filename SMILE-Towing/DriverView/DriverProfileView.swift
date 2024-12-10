import SwiftUI
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage

struct DriverProfileView: View {
    @State private var fullName: String = ""
    @State private var email: String = ""
    @State private var phoneNumber: String = ""
    @State private var pronouns: String = ""
    @State private var profileImage: UIImage? = UIImage(systemName: "person.crop.circle")
    @State private var showImagePicker: Bool = false
    @State private var isLoading: Bool = false // Loading state
    @State private var showAlert: Bool = false
    @State private var alertMessage: String = ""
    @State private var passwordPlaceholder: String = "********" // Password mask
    @State private var navigateToChangePassword: Bool = false
    @State private var showNotification: Bool = false
    @State private var notificationMessage: String = ""

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                        .padding()
                } else {
                    Text("Driver Account Info")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .padding(.top, 20)

                    VStack {
                        if let profileImage = profileImage {
                            Image(uiImage: profileImage)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 100, height: 100)
                                .clipShape(Circle())
                                .padding()
                        }

                        HStack {
                            Button(action: {
                                showImagePicker = true
                            }) {
                                Text("Change Profile Picture")
                                    .font(.headline)
                                    .foregroundColor(.blue)
                            }
                            
                            Button(action: {
                                removeProfilePicture()
                            }) {
                                Text("Remove Picture")
                                    .font(.headline)
                                    .foregroundColor(.red)
                            }
                        }
                    }

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
                                                        Text(passwordPlaceholder)
                                                            .foregroundColor(.gray)

                                                        Spacer()

                                                        NavigationLink(
                                                            destination: CustomerPwChangeView(onSave: { newPassword in
                                                                notificationMessage = "Password updated successfully!"
                                                                showNotification = true
                                                            }),
                                                            isActive: $navigateToChangePassword
                                                        ) {
                                                            Button(action: {
                                                                navigateToChangePassword = true
                                                            }) {
                                                                Text("Change Password")
                                                                    .foregroundColor(.blue)
                                                                    .underline()
                                                            }
                                                        }
                                                    }
                                                    .padding(10)
                                                    .background(Color(.systemGray6))
                                                    .cornerRadius(8)
                                                }
                                            }
                                            .padding(.horizontal)

                                            // Save Changes Button
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
                                        }

                                        Spacer()
                                    }
                                    .sheet(isPresented: $showImagePicker) {
                                        ImagePicker(image: $profileImage)
                                            .onDisappear {
                                                if let image = profileImage {
                                                    uploadProfilePicture(image)
                                                }
                                            }
                                    }
            .onAppear {
                fetchDriverDetails()
            }
            .alert(isPresented: $showAlert) {
                Alert(title: Text("Error"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
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

                if let imageURL = data["profileImageURL"] as? String {
                    loadProfileImage(from: imageURL)
                }
            }
        }
    }

    private func uploadProfilePicture(_ image: UIImage) {
        guard let userUID = Auth.auth().currentUser?.uid else {
            alertMessage = "User not authenticated."
            showAlert = true
            return
        }

        // Detect and process image format
        var imageData: Data?
        var fileExtension: String = "jpg" // Default to JPEG

        if let jpegData = image.jpegData(compressionQuality: 0.8) {
            imageData = jpegData
            fileExtension = "jpg"
        } else if let pngData = image.pngData() {
            imageData = pngData
            fileExtension = "png"
        } else if let heicData = image.heicData(compressionQuality: 0.8) {
            imageData = heicData
            fileExtension = "heic"
        }

        guard let finalImageData = imageData else {
            alertMessage = "Unsupported image format."
            showAlert = true
            return
        }

        // Validate file size (15 MB limit)
        if finalImageData.count > 15 * 1024 * 1024 {
            alertMessage = "Image size exceeds the 15 MB limit."
            showAlert = true
            return
        }

        // Define upload path in the user's folder
        let storagePath = "profile_images/\(userUID)/driver_profile_image.\(fileExtension)"
        let storageRef = Storage.storage().reference().child(storagePath)

        isLoading = true

        // Optional: Add metadata
        let metadata = StorageMetadata()
        metadata.contentType = "image/\(fileExtension)"

        storageRef.putData(finalImageData, metadata: metadata) { _, error in
            self.isLoading = false
            if let error = error {
                alertMessage = "Failed to upload profile picture: \(error.localizedDescription)"
                showAlert = true
                return
            }

            storageRef.downloadURL { url, error in
                if let error = error {
                    alertMessage = "Failed to retrieve profile picture URL: \(error.localizedDescription)"
                    showAlert = true
                    return
                }

                if let url = url {
                    saveProfileImageURL(url.absoluteString)
                }
            }
        }
    }


    private func saveProfileImageURL(_ url: String) {
        guard let userUID = Auth.auth().currentUser?.uid else { return }

        let db = Firestore.firestore()
        db.collection("users").document(userUID).updateData([
            "profileImageURL": url
        ]) { error in
            if let error = error {
                alertMessage = "Failed to save profile picture URL: \(error.localizedDescription)"
                showAlert = true
            }
        }
    }

    private func removeProfilePicture() {
        guard let userUID = Auth.auth().currentUser?.uid else {
            alertMessage = "User not authenticated."
            showAlert = true
            return
        }

        let db = Firestore.firestore()
        db.collection("users").document(userUID).updateData([
            "profileImageURL": FieldValue.delete()
        ]) { error in
            if let error = error {
                alertMessage = "Failed to remove profile picture: \(error.localizedDescription)"
                showAlert = true
                return
            }

            profileImage = UIImage(systemName: "person.crop.circle") // Reset to default
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
                notificationMessage = "Profile information updated successfully!"
                showNotification = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    showNotification = false
                }
            }
        }
    }


    private func loadProfileImage(from url: String) {
        guard let imageURL = URL(string: url) else { return }

        DispatchQueue.global().async {
            if let data = try? Data(contentsOf: imageURL), let uiImage = UIImage(data: data) {
                DispatchQueue.main.async {
                    self.profileImage = uiImage
                }
            }
        }
    }
}
