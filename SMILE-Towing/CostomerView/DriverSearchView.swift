import SwiftUI
import FirebaseFirestore

struct DriverSearchView: View {
    let selectedTruckType: String
    let requestId: String // Pass the tow request ID to manage in Firestore

    @State private var isDriverAssigned: Bool = false
    @State private var driverDetails: [String: String]? = nil // Holds driver info
    @State private var noDriverFound: Bool = false // Tracks if no driver is available
    @State private var timerExpired: Bool = false // Tracks if the 1-minute timer expired
    @Environment(\.presentationMode) var presentationMode // For navigating back
    @State private var loading: Bool = true // Tracks loading state
    @State private var showCancelConfirmation: Bool = false // Tracks cancel confirmation dialog

    var body: some View {
        VStack(spacing: 20) {
            if loading {
                ProgressView("Searching for a Driver...")
                    .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                    .font(.headline)
                Text("Please have patience while we find the best driver for your \(selectedTruckType).")
                    .font(.subheadline)
                    .multilineTextAlignment(.center)
                    .padding()
            } else if isDriverAssigned, let driver = driverDetails {
                NavigationLink(
                    destination: DriverDetailsView(
                        driverName: driver["name"] ?? "Unknown",
                        driverContact: driver["contact"] ?? "Unknown",
                        driverETA: driver["eta"] ?? "Unknown",
                        requestId: requestId
                    ),
                    isActive: $isDriverAssigned
                ) {
                    Text("Driver Assigned! View Details")
                        .font(.headline)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                        .padding(.horizontal)
                }
            } else if noDriverFound || timerExpired {
                VStack(spacing: 10) {
                    Text("No drivers are available right now.")
                        .font(.headline)
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)

                    Button(action: {
                        presentationMode.wrappedValue.dismiss() // Go back
                    }) {
                        Text("Try Again or Select a Different Tow Truck")
                            .font(.subheadline)
                            .foregroundColor(.blue)
                            .underline()
                    }
                }
                .padding()
            }

            Spacer()

            // Cancel Request Button
            Button(action: {
                showCancelConfirmation = true
            }) {
                Text("Cancel Request")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.red)
                    .cornerRadius(10)
            }
            .padding(.horizontal)
            .padding(.bottom)
            .alert(isPresented: $showCancelConfirmation) {
                Alert(
                    title: Text("Cancel Request"),
                    message: Text("Are you sure you want to cancel this request?"),
                    primaryButton: .destructive(Text("Yes")) {
                        cancelRequest()
                    },
                    secondaryButton: .cancel()
                )
            }
        }
        .onAppear {
            listenForDriverAssignment()
            startTimer()
        }
        .padding()
        .navigationTitle("Driver Search")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Listen for Driver Assignment
    private func listenForDriverAssignment() {
        let db = Firestore.firestore()
        db.collection("tow_requests").document(requestId)
            .addSnapshotListener { documentSnapshot, error in
                if let error = error {
                    print("Error listening for driver assignment: \(error.localizedDescription)")
                    return
                }

                guard let data = documentSnapshot?.data() else { return }

                // Check if the driver is assigned
                if let driverName = data["driver_name"] as? String,
                   let driverContact = data["driver_phone"] as? String,
                   let driverETA = data["driver_eta"] as? String,
                   let status = data["status"] as? String, status == "Accepted" {
                    self.driverDetails = [
                        "name": driverName,
                        "contact": driverContact,
                        "eta": driverETA
                    ]
                    self.isDriverAssigned = true
                    self.loading = false
                }
            }
    }

    // MARK: - Timeout Mechanism
    private func startTimer() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 60) { // 1-minute timeout
            if !isDriverAssigned {
                self.timerExpired = true
                self.loading = false
            }
        }
    }

    // MARK: - Cancel Request
    private func cancelRequest() {
        let db = Firestore.firestore()
        db.collection("tow_requests").document(requestId).updateData([
            "status": "Canceled"
        ]) { error in
            if let error = error {
                print("Error canceling request: \(error.localizedDescription)")
            } else {
                print("Request canceled successfully!")
                presentationMode.wrappedValue.dismiss() // Navigate back after canceling
            }
        }
    }
}

// MARK: - Preview
struct DriverSearchView_Previews: PreviewProvider {
    static var previews: some View {
        DriverSearchView(selectedTruckType: "Flatbed Tow Truck", requestId: "sample_request_id")
    }
}
