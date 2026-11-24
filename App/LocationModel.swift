import Foundation
import CoreLocation
import WidgetKit

/// بيتابع الموقع واتجاه الموبايل واتجاه سير العربية
final class LocationModel: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published var location: CLLocation?
    @Published var heading: Double?          // اتجاه الموبايل
    @Published var headingAccuracy: Double = -1
    @Published var status: CLAuthorizationStatus = .notDetermined

    private let manager = CLLocationManager()
    private var lastWidgetReload: CLLocation?

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.headingFilter = 1
        status = manager.authorizationStatus
    }

    var coordinate: CLLocationCoordinate2D { location?.coordinate ?? Qibla.fallback }
    var bearing: Double { Qibla.bearing(from: coordinate) }

    /// اتجاه سير العربية (لو بتتحرك أسرع من ~11 كم/س)
    var drivingCourse: Double? {
        guard let l = location, l.speed > 3, l.course >= 0 else { return nil }
        return l.course
    }

    func requestPermission() {
        manager.requestWhenInUseAuthorization()
    }

    func start() {
        guard status == .authorizedWhenInUse || status == .authorizedAlways else { return }
        manager.startUpdatingLocation()
        if CLLocationManager.headingAvailable() {
            manager.startUpdatingHeading()
        }
    }

    func stop() {
        manager.stopUpdatingLocation()
        manager.stopUpdatingHeading()
    }

    // MARK: Delegate

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        status = manager.authorizationStatus
        start()
        WidgetCenter.shared.reloadAllTimelines()
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let l = locations.last else { return }
        location = l
        // حدّث الـ Widget لو اتحركنا أكتر من 2 كم
        if lastWidgetReload == nil || l.distance(from: lastWidgetReload!) > 2000 {
            lastWidgetReload = l
            WidgetCenter.shared.reloadAllTimelines()
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        heading = newHeading.trueHeading >= 0 ? newHeading.trueHeading : newHeading.magneticHeading
        headingAccuracy = newHeading.headingAccuracy
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {}
}
