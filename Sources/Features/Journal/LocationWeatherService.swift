import Foundation
import CoreLocation
import OSLog
#if canImport(WeatherKit)
import WeatherKit
#endif

@Observable @MainActor
final class LocationWeatherService: NSObject {
    static let shared = LocationWeatherService()

    var currentLocation: String?
    var currentWeather: String?
    var currentLatitude: Double?
    var currentLongitude: Double?
    var isLoading = false
    var authorizationStatus: CLAuthorizationStatus = .notDetermined

    private let locationManager = CLLocationManager()
    private let geocoder = CLGeocoder()
    private let logger = Logger(subsystem: "com.jasonye.kinen", category: "LocationWeather")
    private var locationContinuation: CheckedContinuation<CLLocation?, Never>?

    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        authorizationStatus = locationManager.authorizationStatus
    }

    func requestPermission() {
        locationManager.requestWhenInUseAuthorization()
    }

    @discardableResult
    func fetchLocationAndWeather() async -> (location: String?, weather: String?) {
        #if os(iOS)
        guard authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways else {
            return (nil, nil)
        }
        #else
        guard authorizationStatus == .authorizedAlways || authorizationStatus == .authorized else {
            return (nil, nil)
        }
        #endif

        // Clear stale data from previous fetch
        currentLocation = nil
        currentWeather = nil
        currentLatitude = nil
        currentLongitude = nil

        isLoading = true
        defer { isLoading = false }

        // Serialize: if a fetch is already in flight, skip
        guard locationContinuation == nil else { return (nil, nil) }

        // Get location
        let location = await withCheckedContinuation { continuation in
            locationContinuation = continuation
            locationManager.requestLocation()
        }

        guard let location else { return (nil, nil) }

        currentLatitude = location.coordinate.latitude
        currentLongitude = location.coordinate.longitude

        // Reverse geocode
        do {
            let placemarks = try await geocoder.reverseGeocodeLocation(location)
            if let placemark = placemarks.first {
                let parts = [placemark.locality, placemark.administrativeArea, placemark.country].compactMap { $0 }
                currentLocation = parts.joined(separator: ", ")
            }
        } catch {
            logger.error("Geocoding failed: \(error)")
        }

        // Get weather
        #if canImport(WeatherKit)
        do {
            let weather = try await WeatherService.shared.weather(for: location)
            let temp = weather.currentWeather.temperature
            let condition = weather.currentWeather.condition.description
            let tempStr = temp.formatted(.measurement(width: .abbreviated))
            currentWeather = "\(condition), \(tempStr)"
        } catch {
            logger.error("Weather fetch failed: \(error)")
        }
        #endif

        return (currentLocation, currentWeather)
    }
}

extension LocationWeatherService: @preconcurrency CLLocationManagerDelegate {
    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        Task { @MainActor in
            locationContinuation?.resume(returning: locations.first)
            locationContinuation = nil
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Task { @MainActor in
            logger.error("Location failed: \(error)")
            locationContinuation?.resume(returning: nil)
            locationContinuation = nil
        }
    }

    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus
        Task { @MainActor in
            authorizationStatus = status
        }
    }
}
