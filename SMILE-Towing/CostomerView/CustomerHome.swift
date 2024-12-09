import SwiftUI
import MapKit

// MARK: - Identifiable Pin Wrapper
struct PinLocation: Identifiable {
    let id = UUID()
    var coordinate: CLLocationCoordinate2D
}

struct CustomerHome: View {
    @StateObject private var locationManager = LocationManager() // Manages location
    @State private var region = MKCoordinateRegion( // Initial map region
        center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194), // Default to San Francisco
        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
    )
    @State private var searchText: String = "" // Holds the search text
    @State private var alertItem: AlertItem? // Holds the alert content
    @State private var pinnedLocation: PinLocation? // Holds the pin location
    
    @State private var isMenuOpen: Bool = false // State to toggle menu
    @State private var showSignOutMessage: Bool = false // State for showing sign-out message
    @State private var showProfileView: Bool = false // State to toggle Profile View
    @State private var showVehiclesView: Bool = false // State to toggle Vehicles View
//    @State private var showTowRequestView: Bool = false // State to navigate to the tow request page
    @State private var navigateToTowRequestView: Bool = false // Tracks navigation to Tow Request View
    
    @Environment(\.presentationMode) var presentationMode // For navigating back to login
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            // Map View
            Map(coordinateRegion: $region, showsUserLocation: true, annotationItems: pinnedLocation.map { [$0] } ?? []) { pin in
                MapAnnotation(coordinate: pin.coordinate) {
                    VStack {
                        Image(systemName: "mappin.and.ellipse")
                            .resizable()
                            .frame(width: 40, height: 40)
                            .foregroundColor(.red)
                            .shadow(radius: 5)
                        
                        Text("Request Location")
                            .font(.caption)
                            .foregroundColor(.black)
                            .padding(4)
                            .background(Color.white.opacity(0.8))
                            .cornerRadius(6)
                            .shadow(radius: 3)
                    }
                }
            }
            .edgesIgnoringSafeArea(.all)
            .onAppear {
                locationManager.requestLocation() // Request user location
            }
            
            // Menu Icon and Search Bar
            HStack {
                // Menu Button
                Button(action: {
                    withAnimation {
                        isMenuOpen.toggle() // Toggle menu state
                    }
                }) {
                    Image(systemName: "line.horizontal.3")
                        .font(.title)
                        .padding(10)
                        .background(Color.white)
                        .clipShape(Circle())
                        .shadow(radius: 5)
                }
                .zIndex(1)
                
                // Search Bar with Search Icon
                HStack {
                    TextField("Enter address for towing request", text: $searchText, onEditingChanged: { isEditing in
                        if !isEditing {
                            hideKeyboard()
                        }
                    })
                    .padding(10)
                    .background(Color(.systemGray6))
                    .cornerRadius(15)
                    .shadow(radius: 5)
                    .onSubmit {
                        searchForLocation()
                    }
                    
                    Button(action: {
                        searchForLocation()
                    }) {
                        Image(systemName: "magnifyingglass")
                            .font(.title2)
                            .padding(10)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .clipShape(Circle())
                            .shadow(radius: 5)
                    }
                }
                .padding(.leading, 10)
            }
            .padding(.horizontal)
            .padding(.top, 40)
            
            // Sliding Menu
            if isMenuOpen {
                VStack(alignment: .leading, spacing: 20) {
                    Button(action: {
                        showProfileView = true
                    }) {
                        Text("Profile")
                            .font(.headline)
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.white)
                            .cornerRadius(8)
                    }
                    .sheet(isPresented: $showProfileView) {
                        CustomerProfileView()
                    }
                    
                    Button(action: {
                        showVehiclesView = true
                    }) {
                        Text("Vehicles")
                            .font(.headline)
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.white)
                            .cornerRadius(8)
                    }
                    .sheet(isPresented: $showVehiclesView) {
                        CustomerVehiclesView()
                    }
                    
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
                    
                    Spacer()
                }
                .frame(width: 200)
                .frame(maxHeight: .infinity)
                .background(Color.gray.opacity(0.2))
                .cornerRadius(10)
                .shadow(radius: 5)
                .padding(.top, 80)
                .transition(.move(edge: .leading))
                .animation(.easeInOut, value: isMenuOpen)
            }
            
            // Full-Screen Pop-Up for Sign Out
            if showSignOutMessage {
                ZStack {
                    Color.black.opacity(0.5)
                        .edgesIgnoringSafeArea(.all)
                    
                    VStack(spacing: 20) {
                        Text("You have been successfully signed out.")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .multilineTextAlignment(.center)
                            .padding()
                        
                        Text("Redirecting to login...")
                            .font(.body)
                            .foregroundColor(.gray)
                        
                        ProgressView()
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
            
            VStack {
                Spacer()
                
                HStack {
                    Spacer()
                    Button(action: {
                        reCenterMap()
                    }) {
                        Image(systemName: "location.fill")
                            .font(.title2)
                            .padding()
                            .background(Color.white)
                            .foregroundColor(.blue)
                            .clipShape(Circle())
                            .shadow(radius: 5)
                    }
                    .padding(.trailing, 20)
                    .padding(.bottom, 30)
                }
                
                Button(action: {
                    //                    searchForLocation()
                    //                    searchForLocation()
                    searchForLocation { success in
                        if success {
                            navigateToTowRequestView = true
                        }
                    }
                }) {
                    Image(systemName: "magnifyingglass")
                    Text("Request a Tow Service")
                        .font(.headline)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                        .padding(.horizontal)
                }
                // NavigationLink to navigate to CustomerTowRequestView
                NavigationLink(
                    destination: CustomerTowRequestView(initialLocation: searchText),
                    isActive: $navigateToTowRequestView
                ) {
                    EmptyView() // Hidden NavigationLink
                }
            }
                
                .padding(.bottom, 20)
            
        }
        .onTapGesture {
            hideKeyboard()
        }
        .onChange(of: locationManager.lastLocation) { newLocation in
            if let location = newLocation {
                region.center = location.coordinate
            }
        }
        .navigationBarBackButtonHidden(true) // Hides the back button
        .alert(item: $alertItem) { alertItem in
            Alert(title: Text(alertItem.title), message: Text(alertItem.message), dismissButton: .default(Text("OK")))
        }
    }
    
    // MARK: - Helper Functions
    private func handleSignOut() {
        showSignOutMessage = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            showSignOutMessage = false
            presentationMode.wrappedValue.dismiss()
        }
    }
    
    private func reCenterMap() {
        if let currentLocation = locationManager.lastLocation?.coordinate {
            region.center = currentLocation
        } else {
            alertItem = AlertItem(title: "Error", message: "Unable to retrieve current location.")
        }
    }
    
    private func searchForLocation(completion: @escaping (Bool) -> Void) {
        guard !searchText.isEmpty else {
            alertItem = AlertItem(title: "Error", message: "Please enter an address.")
            completion(false)
            return
        }

        let geocoder = CLGeocoder()
        geocoder.geocodeAddressString(searchText) { placemarks, error in
            if let error = error {
                alertItem = AlertItem(title: "Error", message: "Could not find location: \(error.localizedDescription)")
                completion(false)
                return
            }

            if let coordinate = placemarks?.first?.location?.coordinate {
                region.center = coordinate
                pinnedLocation = PinLocation(coordinate: coordinate)
                completion(true)
            } else {
                alertItem = AlertItem(title: "Error", message: "No matching location found.")
                completion(false)
            }
        }
    }

    
    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
    
    private func searchForLocation() {
        guard !searchText.isEmpty else {
            alertItem = AlertItem(title: "Error", message: "Please enter an address.")
            return
        }
        
        let geocoder = CLGeocoder()
        geocoder.geocodeAddressString(searchText) { placemarks, error in
            if let error = error {
                alertItem = AlertItem(title: "Error", message: "Could not find location: \(error.localizedDescription)")
                return
            }
            
            if let coordinate = placemarks?.first?.location?.coordinate {
                region.center = coordinate
                pinnedLocation = PinLocation(coordinate: coordinate)
            } else {
                alertItem = AlertItem(title: "Error", message: "No matching location found.")
            }
        }
    }
}
