import SwiftUI
import MapKit
import FirebaseAuth
import FirebaseFirestore

// MARK: - Identifiable Wrapper for Customer Locations
struct CustomerLocation: Identifiable {
    let id = UUID() // Unique identifier
    let coordinate: CLLocationCoordinate2D
}

struct DriverHome: View {
    @StateObject private var locationManager = LocationManager() // Shared LocationManager
    @State private var region = MKCoordinateRegion( // Initial map region
        center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194), // Default to San Francisco
        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
    )

    @State private var isMenuOpen: Bool = false // State to toggle menu
    @State private var showSignOutMessage: Bool = false // State for showing sign-out message
    @State private var showProfileView: Bool = false // State for navigating to profile view
    @State private var showVehiclesView: Bool = false
    
    @Environment(\.presentationMode) var presentationMode // For navigating back to login

    @State private var isOnline: Bool = false { // State for Online/Offline toggle
        didSet {
            updateDriverOnlineStatus(isOnline: isOnline) // Update Firestore status when toggled
            if isOnline {
                locationManager.requestLocation() // Ensure location updates start when online
            }
        }
    }
    @State private var showOfflineError: Bool = false // Error for trying to view jobs while offline
    @State private var navigateToAvailableJobs: Bool = false // State for navigating to AvailableJobView


    // Updated customer locations
    @State private var customerLocations: [CustomerLocation] = [
        CustomerLocation(coordinate: CLLocationCoordinate2D(latitude: 37.7809, longitude: -122.4194)), // Example customer 1
        CustomerLocation(coordinate: CLLocationCoordinate2D(latitude: 37.7683, longitude: -122.4175))  // Example customer 2
    ]

    var body: some View {
        ZStack(alignment: .topLeading) {
            // Map View
            Map(coordinateRegion: $region, showsUserLocation: true, annotationItems: customerLocations) { location in
                MapMarker(coordinate: location.coordinate, tint: .red) // Pins for customer requests
            }
            .edgesIgnoringSafeArea(.all)
            .onAppear {
                locationManager.requestPermissions() // Request location permissions
                locationManager.requestLocation() // Start location updates
            }

            // Menu Button and Online/Offline Toggle
            HStack {
                // Menu Button
                Button(action: {
                    withAnimation {
                        isMenuOpen.toggle() // Toggle menu state
                    }
                }) {
                    Image(systemName: "line.horizontal.3")
                        .font(.title)
                        .padding()
                        .background(Color.white)
                        .clipShape(Circle())
                        .shadow(radius: 5)
                }
                .padding(.leading)

                Spacer()

                // Online/Offline Toggle with Status
                HStack(spacing: 10) {
                    
                    Text(isOnline ? "Online" : "Offline")
                        .font(.headline)
                        .foregroundColor(isOnline ? .green : .red)
                    
                    Toggle("", isOn: $isOnline)
                        .labelsHidden()
                        .toggleStyle(SwitchToggleStyle(tint: .green))

                }
                .padding(10)
                .background(Color.white)
                .cornerRadius(10)
                .shadow(radius: 5)
                .padding(.trailing)

            }
            .padding(.top, 10)

            // Sliding Menu
            if isMenuOpen {
                VStack(alignment: .leading, spacing: 20) {
                    // Profile Button
                    Button(action: {
                        showProfileView = true // Trigger navigation to profile
                    }) {
                        Text("Profile")
                            .font(.headline)
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.white)
                            .cornerRadius(8)
                    }

                    Button(action: {
                        showVehiclesView = true
                    }) {
                        Text("Vehicles")
                            .font(.headline)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding()
                            .background(Color.white)
                            .cornerRadius(8)
                    }

                    // Sign Out Button
                    Button(action: {
                        handleSignOut()
                    }) {
                        Text("Sign Out")
                            .font(.headline)
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.white)
                            .cornerRadius(8)
                            .foregroundColor(.red)
                    }

                    Spacer() // Fill remaining space at the bottom
                }
                .frame(width: 200) // Fixed width for the menu
                .frame(maxHeight: .infinity) // Stretch to the bottom of the screen
                .background(Color.gray.opacity(0.2))
                .cornerRadius(10)
                .shadow(radius: 5)
                .padding(.top, 80) // Ensure menu slides below the button
                .transition(.move(edge: .leading)) // Slide from left
                .animation(.easeInOut, value: isMenuOpen)
            }

            // Full-Screen Pop-Up for Sign Out
            if showSignOutMessage {
                ZStack {
                    // Blurred Background
                    Color.black.opacity(0.5)
                        .edgesIgnoringSafeArea(.all)

                    // Pop-Up Message
                    VStack(spacing: 20) {
                        Text("You have been successfully signed out.")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .multilineTextAlignment(.center)
                            .padding()

                        Text("Redirecting to login...")
                            .font(.body)
                            .foregroundColor(.gray)

                        ProgressView() // Optional progress indicator
                            .scaleEffect(1.5)
                            .padding()
                    }
                    .frame(width: 300)
                    .padding()
                    .background(Color.white)
                    .cornerRadius(15)
                    .shadow(radius: 10)
                }
                .transition(.opacity)
                .animation(.easeInOut, value: showSignOutMessage)
            }

            // Example Buttons for Driver Actions
            VStack {
                Spacer()
                
                NavigationLink(destination: AvailableJobView(), isActive: $navigateToAvailableJobs) {
                    EmptyView()
                }
                
                HStack(spacing: 20) {
                    Button(action: {
                        if isOnline {
                            navigateToAvailableJobs = true // Show available jobs if online
                                      } else {
                                          showOfflineError = true // Show error when offline
                                      }
                    }) {
                        Text("Available Jobs")
                            .font(.headline)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                    .alert(isPresented: $showOfflineError) {
                        Alert(
                            title: Text("Offline"),
                            message: Text("You must go online to see available job offers."),
                            dismissButton: .default(Text("OK"))
                        )
                    }

                    Button(action: {
                        print("Earnings tapped")
                    }) {
                        Text("Earnings")
                            .font(.headline)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.green)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 20)
            }

            // Re-Center Button
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Button(action: {
                        if let currentLocation = locationManager.lastLocation {
                            region.center = currentLocation.coordinate // Re-center to current location
                        }
                    }) {
                        Image(systemName: "location.fill") // Arrow location icon
                            .font(.title)
                            .padding()
                            .background(Color.white.opacity(0.9))
                            .clipShape(Circle())
                            .shadow(radius: 5)
                    }
                    .padding(.trailing, 20)
                    .padding(.bottom, 100)
                }
            }
        }
        .navigationBarBackButtonHidden(true) // Disables the back button
        .onChange(of: locationManager.lastLocation) { newLocation in
            if let location = newLocation {
                region.center = location.coordinate // Update map region
            }
        }
        .sheet(isPresented: $showProfileView) {
            DriverProfileView() // Navigate to Driver Profile View
        }
        .sheet(isPresented: $showVehiclesView) {
            DriverVehiclesView() // Navigate to Driver Vehicles View
        }
    }

    private func handleSignOut() {
        showSignOutMessage = true
        updateDriverOnlineStatus(isOnline: false) // Ensure driver is offline on sign-out
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            showSignOutMessage = false
            presentationMode.wrappedValue.dismiss() // Navigate back to login
        }
    }

    private func updateDriverOnlineStatus(isOnline: Bool) {
        guard let currentUser = Auth.auth().currentUser else { return }
        let db = Firestore.firestore()

        var data: [String: Any] = ["isOnline": isOnline]
        
        // Include location if the driver is going online
        if isOnline, let location = locationManager.lastLocation {
            data["location"] = GeoPoint(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude)
        }

        db.collection("users").document(currentUser.uid).updateData(data) { error in
            if let error = error {
                print("Error updating online status: \(error.localizedDescription)")
            } else {
                print("Driver online status updated to \(isOnline ? "Online" : "Offline").")
            }
        }
    }
}
