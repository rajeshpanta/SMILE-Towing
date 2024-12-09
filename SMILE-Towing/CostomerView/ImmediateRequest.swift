import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct ImmediateRequest: View {
    @State private var selectedTruckType: String? = nil // Holds the selected tow truck type
    @State private var navigateToDriverSearch: Bool = false // Tracks navigation to DriverSearchView
    @State private var requestId: String = "" // Holds the requestId for the tow request
    @State private var issue: String = "" // Holds the issue description
    @StateObject private var locationManager = LocationManager() // Add location manager instance

    // Example tow truck types
    let towTruckTypes = [
        ("Flatbed Tow Truck", "Suitable for all vehicles, especially damaged ones.", "$100 - $150"),
        ("Wheel-Lift Tow Truck", "Ideal for lighter vehicles, quick operations.", "$80 - $120"),
        ("Hook and Chain Tow Truck", "Used for older cars, might cause scratches.", "$70 - $100"),
        ("Integrated Tow Truck", "Perfect for heavy-duty vehicles like buses.", "$120 - $180")
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Choose Tow Truck Type")
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding(.top, 20)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)

            ScrollView {
                VStack(spacing: 20) {
                    ForEach(towTruckTypes, id: \.0) { truckType in
                        TowTruckTypeCard(
                            name: truckType.0,
                            description: truckType.1,
                            price: truckType.2,
                            isSelected: selectedTruckType == truckType.0
                        ) {
                            selectedTruckType = truckType.0
                        }
                    }
                }
                .padding(.horizontal)
            }

            if let selectedTruckType = selectedTruckType {
                Text("Selected: \(selectedTruckType)")
                    .font(.headline)
                    .foregroundColor(.green)
                    .padding(.horizontal)
            }

            // Issue description field
            VStack(alignment: .leading, spacing: 10) {
                Text("Describe the issue")
                    .font(.headline)
                    .padding(.horizontal)

                TextField("Enter issue (e.g., flat tire, engine failure)", text: $issue)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                    .shadow(radius: 3)
                    .padding(.horizontal)
            }

            Spacer()

            // Confirm Button
            Button(action: {
                saveTowRequest()
            }) {
                Text("Confirm Selection")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(selectedTruckType == nil ? Color.gray.opacity(0.6) : Color.green)
                    .cornerRadius(10)
            }
            .disabled(selectedTruckType == nil || issue.isEmpty) // Disable if no selection or issue description
            .padding(.horizontal)

            // Navigation Link to DriverSearchView
            NavigationLink(
                destination: DriverSearchView(
                    selectedTruckType: selectedTruckType ?? "",
                    requestId: requestId
                ),
                isActive: $navigateToDriverSearch
            ) {
                EmptyView() // Invisible navigation link
            }
        }
        .padding(.vertical)
        .navigationTitle("Tow Truck Selection")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            locationManager.requestLocation() // Request location permission on view appear
        }
    }

    // MARK: - Save Tow Request to Firestore
    private func saveTowRequest() {
        guard let currentUser = Auth.auth().currentUser else {
            print("Error: User not authenticated")
            return
        }

        guard let selectedTruckType = selectedTruckType else {
            print("Error: No truck type selected")
            return
        }

        guard let location = locationManager.lastLocation else {
            print("Error: Location not available")
            return
        }

        let db = Firestore.firestore()
        let newRequestId = UUID().uuidString // Generate a unique requestId
        requestId = newRequestId // Store the requestId for navigation

        let issueDescription = issue.isEmpty ? "No issue specified" : issue

        db.collection("tow_requests").document(newRequestId).setData([
            "customer_id": currentUser.uid,
            "truck_type": selectedTruckType,
            "status": "Pending",
            "created_at": Timestamp(date: Date()),
            "location": GeoPoint(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude),
            "issue": issueDescription // Add the issue field
        ]) { error in
            if let error = error {
                print("Error saving request: \(error.localizedDescription)")
            } else {
                print("Request saved successfully!")
                DispatchQueue.main.async {
                    // Trigger navigation only after saving the request
                    self.navigateToDriverSearch = true
                }
            }
        }
    }
}

// MARK: - TowTruckTypeCard View
struct TowTruckTypeCard: View {
    let name: String
    let description: String
    let price: String
    let isSelected: Bool
    let onSelect: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                VStack(alignment: .leading, spacing: 5) {
                    Text(name)
                        .font(.headline)
                        .foregroundColor(isSelected ? .green : .primary)
                    Text(description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Text("Price: \(price)")
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundColor(.blue)
                }
                Spacer()
                Button(action: onSelect) {
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .resizable()
                        .frame(width: 30, height: 30)
                        .foregroundColor(isSelected ? .green : .gray)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(10)
        .shadow(radius: 3)
    }
}
