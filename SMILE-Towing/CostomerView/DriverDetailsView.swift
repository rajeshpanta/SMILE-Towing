import SwiftUI
import FirebaseFirestore
import MapKit

struct DriverDetailsView: View {
    let driverName: String
    let driverContact: String
    let driverETA: String
    let requestId: String // To track and manage the request in Firestore

    @State private var showCancelConfirmation: Bool = false
    @State private var driverLocation = CLLocationCoordinate2D(latitude: 0, longitude: 0) // Driver's live location
    @State private var serviceStatus: String = "En Route" // Default service status
    @State private var isServiceCompleted: Bool = false // Flag for service completion

    var body: some View {
        VStack(spacing: 20) {
            Text("Driver Details")
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding(.top, 20)

            // Map View for Real-Time Driver Location
            Map(coordinateRegion: .constant(
                MKCoordinateRegion(
                    center: driverLocation,
                    span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                )
            ))
            .frame(height: 200)
            .cornerRadius(10)
            .padding(.horizontal)

            VStack(alignment: .leading, spacing: 15) {
                HStack {
                    Text("Driver Name:")
                        .font(.headline)
                    Spacer()
                    Text(driverName)
                        .font(.subheadline)
                }

                HStack {
                    Text("Contact:")
                        .font(.headline)
                    Spacer()
                    Text(driverContact)
                        .font(.subheadline)
                }

                HStack {
                    Text("ETA:")
                        .font(.headline)
                    Spacer()
                    Text(driverETA)
                        .font(.subheadline)
                }

                HStack {
                    Text("Service Status:")
                        .font(.headline)
                    Spacer()
                    Text(serviceStatus)
                        .font(.subheadline)
                        .foregroundColor(serviceStatus == "Completed" ? .green : .orange)
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(10)
            .shadow(radius: 5)

            Spacer()

            // Call Driver Button
            Button(action: {
                if let phoneURL = URL(string: "tel://\(driverContact.filter { $0.isNumber })") {
                    UIApplication.shared.open(phoneURL)
                } else {
                    print("Invalid phone number")
                }
            }) {
                Text("Call Driver")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                    .cornerRadius(10)
            }
            .padding(.horizontal)

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

            Spacer()
        }
        .padding()
        .navigationTitle("Driver Assigned")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            fetchDriverLocation()
            listenForServiceUpdates()
        }
    }

    // MARK: - Cancel Request Function
    private func cancelRequest() {
        let db = Firestore.firestore()
        db.collection("tow_requests").document(requestId).updateData([
            "status": "Canceled"
        ]) { error in
            if let error = error {
                print("Error canceling request: \(error.localizedDescription)")
            } else {
                print("Request canceled successfully!")
            }
        }
    }

    // MARK: - Fetch Driver Location
    private func fetchDriverLocation() {
        let db = Firestore.firestore()
        db.collection("tow_requests").document(requestId).addSnapshotListener { documentSnapshot, error in
            if let error = error {
                print("Error fetching driver location: \(error.localizedDescription)")
                return
            }

            guard let data = documentSnapshot?.data(),
                  let geoPoint = data["driver_location"] as? GeoPoint else { return }

            self.driverLocation = CLLocationCoordinate2D(latitude: geoPoint.latitude, longitude: geoPoint.longitude)
        }
    }

    // MARK: - Listen for Service Updates
    private func listenForServiceUpdates() {
        let db = Firestore.firestore()
        db.collection("tow_requests").document(requestId).addSnapshotListener { documentSnapshot, error in
            if let error = error {
                print("Error listening for service updates: \(error.localizedDescription)")
                return
            }

            guard let data = documentSnapshot?.data(),
                  let status = data["status"] as? String else { return }

            self.serviceStatus = status

            if status == "Completed" {
                self.isServiceCompleted = true
                showServiceCompletionNotification()
            }
        }
    }

    // MARK: - Show Notification for Service Completion
    private func showServiceCompletionNotification() {
        let content = UNMutableNotificationContent()
        content.title = "Service Completed"
        content.body = "The towing service has been completed. Thank you for using our app!"
        content.sound = .default

        let request = UNNotificationRequest(identifier: "ServiceCompletedNotification", content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error showing notification: \(error.localizedDescription)")
            }
        }
    }
}

// MARK: - Preview
struct DriverDetailsView_Previews: PreviewProvider {
    static var previews: some View {
        DriverDetailsView(driverName: "John Doe", driverContact: "123-456-7890", driverETA: "10 minutes", requestId: "sample_request_id")
    }
}
