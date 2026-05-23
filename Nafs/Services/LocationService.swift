import CoreLocation

@MainActor
@Observable
class LocationService: NSObject {
    var authorizationStatus: CLAuthorizationStatus = .notDetermined
    var lastLatitude: Double?
    var lastLongitude: Double?
    var locationError: String?

    private let manager = CLLocationManager()
    private var bestAccuracy: CLLocationAccuracy = .greatestFiniteMagnitude

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        authorizationStatus = manager.authorizationStatus
        restoreCachedLocation()
    }

    func requestPermission() {
        manager.requestWhenInUseAuthorization()
    }

    func requestLocation() {
        bestAccuracy = .greatestFiniteMagnitude
        manager.requestLocation()
    }

    private func restoreCachedLocation() {
        let defaults = UserDefaults.standard
        let lat = defaults.double(forKey: "nafs_cachedLat")
        let lon = defaults.double(forKey: "nafs_cachedLon")
        if lat != 0 || lon != 0 {
            lastLatitude = lat
            lastLongitude = lon
        }
    }

    private func cacheLocation(lat: Double, lon: Double) {
        UserDefaults.standard.set(lat, forKey: "nafs_cachedLat")
        UserDefaults.standard.set(lon, forKey: "nafs_cachedLon")
    }

    fileprivate func acceptLocation(_ location: CLLocation) {
        // Reject invalid samples
        guard location.horizontalAccuracy >= 0 else { return }
        // Reject wildly inaccurate samples that cause prayer-time jumps
        guard location.horizontalAccuracy <= 5000 else { return }
        // Reject stale cached samples
        let age = -location.timestamp.timeIntervalSinceNow
        guard age < 120 else { return }

        // Only accept if it's better than previous sample in this fetch cycle, or close to it
        if location.horizontalAccuracy > bestAccuracy + 200 { return }
        bestAccuracy = location.horizontalAccuracy

        lastLatitude = location.coordinate.latitude
        lastLongitude = location.coordinate.longitude
        cacheLocation(lat: location.coordinate.latitude, lon: location.coordinate.longitude)
    }
}

extension LocationService: CLLocationManagerDelegate {
    nonisolated func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        Task { @MainActor in
            authorizationStatus = status
            if status == .authorizedWhenInUse || status == .authorizedAlways {
                bestAccuracy = .greatestFiniteMagnitude
                manager.requestLocation()
            }
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let snapshot = locations
        Task { @MainActor in
            for location in snapshot {
                acceptLocation(location)
            }
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Task { @MainActor in
            locationError = error.localizedDescription
        }
    }
}
