//import SwiftUI
//import MapKit
//import FirebaseAuth
//import FirebaseFirestore
//
//struct CustomerSearchView: View {
//    @ObservedObject var locationManager: LocationManager // LocationManager to get real-time location updates
//    @Binding var searchText: String // Binding to share text input
//    @Binding var region: MKCoordinateRegion // Binding for map region updates
//    @Binding var pinnedLocation: PinLocation? // Binding for pin location
//    @Binding var alertItem: AlertItem? // Binding for alerts
//    @State private var issue: String = "" // State for entering issue details
//
//    var body: some View {
//        VStack {
//            // Search and Pin Location
//            HStack {
//                // Search Text Field
//                TextField("Enter address for towing request", text: $searchText)
//                    .padding(10)
//                    .background(Color(.systemGray6))
//                    .cornerRadius(15)
//                    .shadow(radius: 5)
//                    .onSubmit {
//                        searchForLocation() // Search when user submits
//                    }
//
//                // Search Button
//                Button(action: searchForLocation) {
//                    Image(systemName: "magnifyingglass")
//                        .font(.title2)
//                        .padding(10)
//                        .background(Color.blue)
//                        .foregroundColor(.white)
//                        .clipShape(Circle())
//                        .shadow(radius: 5)
//                }
//            }
//            .padding(.horizontal)
//            .padding(.top, 40)
//
//            // Issue Description
//            VStack(alignment: .leading, spacing: 10) {
//                Text("Describe the Issue")
//                    .font(.headline)
//                    .padding(.horizontal)
//
//                TextField("Enter issue (e.g., flat tire, engine failure)", text: $issue)
//                    .padding(10)
//                    .background(Color(.systemGray6))
//                    .cornerRadius(15)
//                    .shadow(radius: 5)
//                    .padding(.horizontal)
//            }
//
//            // Pin Location Based on Current Location
//            if let currentLocation = locationManager.lastLocation {
//                Button(action: {
//                    let coordinate = currentLocation.coordinate
//                    pinnedLocation = PinLocation(coordinate: coordinate) // Update pinnedLocation
//                    region.center = coordinate // Update map region
//                }) {
//                    Text("Use Current Location")
//                        .font(.headline)
//                        .foregroundColor(.white)
//                        .padding()
//                        .frame(maxWidth: .infinity)
//                        .background(Color.blue)
//                        .cornerRadius(15)
//                        .shadow(radius: 5)
//                }
//                .padding(.horizontal)
//            } else if let error = locationManager.locationError {
//                Text("Error: \(error)")
//                    .foregroundColor(.red)
//                    .padding(.horizontal)
//            }
//
//            // Submit Button
//            Button(action: submitTowRequest) {
//                Text("Request Tow")
//                    .font(.headline)
//                    .foregroundColor(.white)
//                    .padding()
//                    .frame(maxWidth: .infinity)
//                    .background(Color.green)
//                    .cornerRadius(15)
//                    .shadow(radius: 5)
//            }
//            .padding(.horizontal)
//            .padding(.top)
//        }
//        .onAppear {
//            // Request permissions and location updates when the view appears
//            locationManager.requestPermissions()
//            locationManager.requestLocation()
//        }
//    }
//
//    // Function to perform geocoding
//    private func searchForLocation() {
//        guard !searchText.isEmpty else {
//            alertItem = AlertItem(title: "Error", message: "Please enter an address.")
//            return
//        }
//
//        let geocoder = CLGeocoder()
//        geocoder.geocodeAddressString(searchText) { placemarks, error in
//            if let error = error {
//                DispatchQueue.main.async {
//                    alertItem = AlertItem(title: "Error", message: "Could not find location: \(error.localizedDescription)")
//                }
//                return
//            }
//
//            if let coordinate = placemarks?.first?.location?.coordinate {
//                DispatchQueue.main.async {
//                    region.center = coordinate // Update map region
//                    pinnedLocation = PinLocation(coordinate: coordinate) // Add pin to the map
//                }
//            } else {
//                DispatchQueue.main.async {
//                    alertItem = AlertItem(title: "Error", message: "No matching address found.")
//                }
//            }
//        }
//    }
//
//    // Function to submit tow request to Firestore
//    private func submitTowRequest() {
//        guard let pinnedLocation = pinnedLocation else {
//            alertItem = AlertItem(title: "Error", message: "Please pin a location before submitting.")
//            return
//        }
//
//        guard let currentUser = Auth.auth().currentUser else {
//            alertItem = AlertItem(title: "Error", message: "You must be signed in to make a request.")
//            return
//        }
//
//        let db = Firestore.firestore()
//        let newRequest = [
//            "customer_id": currentUser.uid,
//            "location": GeoPoint(latitude: pinnedLocation.coordinate.latitude, longitude: pinnedLocation.coordinate.longitude), // Dynamic location
//            "status": "Pending",
//            "issue": issue.isEmpty ? "No issue specified" : issue,
//            "created_at": FieldValue.serverTimestamp()
//        ] as [String: Any]
//
//        db.collection("tow_requests").addDocument(data: newRequest) { error in
//            if let error = error {
//                DispatchQueue.main.async {
//                    alertItem = AlertItem(title: "Error", message: "Failed to submit tow request: \(error.localizedDescription)")
//                }
//            } else {
//                DispatchQueue.main.async {
//                    alertItem = AlertItem(title: "Success", message: "Your tow request has been submitted.")
//                    // Clear input fields
//                    searchText = ""
//                    issue = ""
////                    pinnedLocation = nil  Safely reset pinnedLocation
//                }
//            }
//        }
//    }
//}
