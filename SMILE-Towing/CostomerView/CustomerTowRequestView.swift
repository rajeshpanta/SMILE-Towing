import SwiftUI
import MapKit
import CoreLocation

struct CustomerTowRequestView: View {
    @State private var location: String = "" // User-entered location
    @State private var issueDescription: String = "" // Issue description
    @State private var towingPreference: String = "Immediate" // Default preference
    @State private var isValidLocation: Bool = false // Tracks if the location is valid
    @State private var showConfirmButton: Bool = false // Tracks if "Confirm Address" should appear
    
    @State private var navigateToImmediateRequest: Bool = false
    @State private var navigateToScheduleRequest: Bool = false

    
    @State private var region = MKCoordinateRegion( // Initial region of the map
        center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194), // Default to SF
        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
    )
    @State private var pinnedLocations: [PinLocation] = [] // Holds pinned locations
    @State private var alertItem: AlertItem? // Holds alert messages
    @ObservedObject private var locationManager = LocationManager() // Handles location updates

    let towingPreferences = ["Immediate", "Scheduled"] // Towing options
    
    init(initialLocation: String) {
        _location = State(initialValue: initialLocation) // Initialize location with the value passed
    }

    var body: some View {
        BaseView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Request Towing Service")
                    .font(.largeTitle)
                    .fontWeight(.bold)
//                    .padding(.top, UIDevice.current.orientation.isLandscape ? 16 : 50) // Adjust padding based on orientation
                    .padding(.top, 54)
                
                    .frame(maxWidth: .infinity, alignment: .leading) // Align to the left
                    .padding(.bottom, 16)

                // Location Input Section
                VStack(alignment: .leading, spacing: 10) {
                    Text("Enter Your Location (Required:")
                        .font(.headline)
                    HStack {
                        TextField("Auto-detect or enter manually", text: $location)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .onSubmit {
                                hideKeyboard()
                            }
                        Button(action: {
                            searchLocation()
                            hideKeyboard()
                        }) {
                            Text(isValidLocation ? "Change" : "Search")
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding()
                                .background(isValidLocation ? Color.green : Color.blue)
                                .cornerRadius(10)
                        }
                        .disabled(location.isEmpty)
                    }
                    .padding(.horizontal)
                }

                // Map Section
                Map(coordinateRegion: $region, annotationItems: pinnedLocations) { location in
                    MapAnnotation(coordinate: location.coordinate) {
                        Image(systemName: "mappin.and.ellipse")
                            .resizable()
                            .frame(width: 30, height: 30)
                            .foregroundColor(.red)
                            .shadow(radius: 5)
                    }
                }
                .frame(height: 300)
                .cornerRadius(10)
                .padding(.horizontal)

                // Issue Description Section
                VStack(alignment: .leading, spacing: 10) {
                    Text("Describe Your Issue (Required:")
                        .font(.headline)
                    TextField("e.g., Flat tire, Engine failure", text: $issueDescription)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding(.horizontal)
                }

                // Towing Preference Picker
                VStack(alignment: .leading, spacing: 10) {
                    Text("Towing Preference:")
                        .font(.headline)
                    Picker("Towing Preference", selection: $towingPreference) {
                        ForEach(towingPreferences, id: \.self) { preference in
                            Text(preference)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .padding(.horizontal)
                }
                
                // Add Navigation Links here
                NavigationLink(destination: ImmediateRequest(), isActive: $navigateToImmediateRequest) {
                    EmptyView()
                }

                NavigationLink(destination: ScheduleRequest(), isActive: $navigateToScheduleRequest) {
                    EmptyView()
                }

                // Dynamic Button Based on Towing Preference
                Button(action: {
//                    handleTowingPreferenceAction()
                    if towingPreference == "Immediate" {
                        navigateToImmediateRequest = true
                    } else if towingPreference == "Scheduled" {
                        navigateToScheduleRequest = true
                    }
                }) {
                    Text(towingPreference == "Immediate" ? "Choose Tow Truck Type" : "Choose Date or Time")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(location.isEmpty || issueDescription.isEmpty ? Color.gray.opacity(0.6) : Color.green) // Use gray with opacity when disabled
                        .cornerRadius(10)
                }
                .padding(.horizontal)
                .disabled(location.isEmpty || issueDescription.isEmpty) // Disable if location or issueDescription is empty
                

                Spacer()
            }
            
            .padding()
            .alert(item: $alertItem) { alertItem in
                Alert(title: Text(alertItem.title), message: Text(alertItem.message), dismissButton: .default(Text("OK")))
            }
            .onAppear {
                locationManager.requestLocation()
            }
            .onChange(of: locationManager.lastLocation) { newLocation in
                if let newLocation = newLocation {
                    region.center = newLocation.coordinate
                }
            }
        }
    }

    // MARK: - Functions

    // Search for location using geocoding
    func searchLocation() {
        guard !location.isEmpty else {
            alertItem = AlertItem(title: "Error", message: "Please enter a location.")
            return
        }

        let geocoder = CLGeocoder()
        geocoder.geocodeAddressString(location) { placemarks, error in
            if let error = error {
                alertItem = AlertItem(title: "Error", message: "Could not find location: \(error.localizedDescription)")
                isValidLocation = false
                showConfirmButton = false
                return
            }

            if let coordinate = placemarks?.first?.location?.coordinate {
                // Pin the location and zoom in
                pinnedLocations = [PinLocation(coordinate: coordinate)]
                region = MKCoordinateRegion(
                    center: coordinate,
                    span: MKCoordinateSpan(latitudeDelta: 0.0025, longitudeDelta: 0.0025) // Zoomed-in region
                )
                isValidLocation = true
                showConfirmButton = true
            } else {
                alertItem = AlertItem(title: "Error", message: "No matching location found.")
                isValidLocation = false
                showConfirmButton = false
            }
        }
    }
    
    // Handle action for towing preference
    func handleTowingPreferenceAction() {
        if towingPreference == "Immediate" {
            print("Navigating to choose tow truck type")
            // Add navigation logic here
        } else if towingPreference == "Scheduled" {
            print("Navigating to choose date or time")
            // Add navigation logic here
        }
    }
    
    // Hide keyboard
    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
    // Navigate to the next page
    func navigateToNextPage() {
        // Placeholder logic for navigation
        print("Navigating to next page with:")
        print("Location: \(location)")
        print("Pinned Location: \(String(describing: pinnedLocations.first))")
//        print("Issue: \(issueDescription)")
        print("Preference: \(towingPreference)")
    }
}

// MARK: - Preview
struct CustomerTowRequestView_Previews: PreviewProvider {
    static var previews: some View {
        CustomerTowRequestView(initialLocation: "Sample Address, San Francisco, CA")
    }
}
