import Foundation
import CoreLocation

// MARK: - LocationManager
class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    @Published var lastLocation: CLLocation? = nil
    @Published var locationError: String? = nil // To store error messages
    
    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.allowsBackgroundLocationUpdates = true
        manager.pausesLocationUpdatesAutomatically = false
    }
    
    func requestPermissions() {
        manager.requestAlwaysAuthorization() // Request Always Authorization
    }
    
    func requestLocation() {
        checkAuthorizationStatus()
        manager.startUpdatingLocation()
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else {
            print("No location data available.")
            return
        }
        print("Updated location: \(location.coordinate.latitude), \(location.coordinate.longitude)")
        DispatchQueue.main.async {
            self.lastLocation = location
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        switch (error as NSError).code {
        case CLError.locationUnknown.rawValue:
            print("Location unknown. Retrying...")
        case CLError.denied.rawValue:
            print("Location access denied. Inform user to enable permissions.")
            DispatchQueue.main.async {
                self.locationError = "Location access denied. Please enable location services in settings."
            }
        default:
            print("Error updating location: \(error.localizedDescription)")
            DispatchQueue.main.async {
                self.locationError = "Error updating location: \(error.localizedDescription)"
            }
        }
    }
    
    private func checkAuthorizationStatus() {
        let status = CLLocationManager.authorizationStatus() // Correct usage for authorization status
        switch status {
        case .notDetermined:
            manager.requestAlwaysAuthorization()
        case .restricted, .denied:
            print("Location access is restricted or denied.")
            DispatchQueue.main.async {
                self.locationError = "Location access is restricted or denied."
            }
        case .authorizedAlways, .authorizedWhenInUse:
            manager.startUpdatingLocation()
        @unknown default:
            print("Unknown location authorization status.")
        }
    }
}
