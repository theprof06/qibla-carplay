import WidgetKit
import SwiftUI
import CoreLocation

// MARK: - البيانات

struct QiblaEntry: TimelineEntry {
    let date: Date
    let bearing: Double
    let distanceKm: Double
    /// true لو مقدرناش نجيب الموقع واستخدمنا الدوحة
    let isFallback: Bool

    init(date: Date = Date(), location: CLLocation?) {
        let c = location?.coordinate ?? Qibla.fallback
        self.date = date
        self.bearing = Qibla.bearing(from: c)
        self.distanceKm = Qibla.distanceKm(from: c)
        self.isFallback = (location == nil)
    }

    static let sample = QiblaEntry(location: CLLocation(latitude: Qibla.fallback.latitude,
                                                        longitude: Qibla.fallback.longitude))
}

// MARK: - جلب الموقع داخل الـ Widget

final class WidgetLocationFetcher: NSObject, CLLocationManagerDelegate {
    private var manager: CLLocationManager?
    private var completion: ((CLLocation?) -> Void)?

    func fetch(_ completion: @escaping (CLLocation?) -> Void) {
        DispatchQueue.main.async {
            let m = CLLocationManager()
            m.delegate = self
            m.desiredAccuracy = kCLLocationAccuracyKilometer
            self.manager = m
            self.completion = completion

            guard m.isAuthorizedForWidgetUpdates else {
                self.finish(m.location)
                return
            }
            m.requestLocation()
            // حد أقصى 8 ثواني، بعدها نستخدم آخر موقع معروف
            DispatchQueue.main.asyncAfter(deadline: .now() + 8) { [weak self] in
                self?.finish(self?.manager?.location)
            }
        }
    }

    private func finish(_ location: CLLocation?) {
        guard let c = completion else { return }
        completion = nil
        c(location)
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        finish(locations.last)
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        finish(manager.location)
    }
}

// MARK: - مزوّد التحديثات

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> QiblaEntry { .sample }

    func getSnapshot(in context: Context, completion: @escaping (QiblaEntry) -> Void) {
        if context.isPreview {
            completion(.sample)
            return
        }
        let fetcher = WidgetLocationFetcher()
        fetcher.fetch { location in
            _ = fetcher
            completion(QiblaEntry(location: location))
        }
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<QiblaEntry>) -> Void) {
        let fetcher = WidgetLocationFetcher()
        fetcher.fetch { location in
            _ = fetcher
            let entry = QiblaEntry(location: location)
            // تحديث كل 15 دقيقة (في السفر الزاوية بتتغير)
            let next = Date().addingTimeInterval(15 * 60)
            completion(Timeline(entries: [entry], policy: .after(next)))
        }
    }
}

// MARK: - الشكل

struct QiblaWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: QiblaEntry

    var body: some View {
        switch family {
        case .accessoryCircular:
            ZStack {
                AccessoryWidgetBackground()
                VStack(spacing: 0) {
                    CompassDial(bearing: entry.bearing, showTicks: false)
                        .padding(6)
                }
            }
        case .accessoryRectangular:
            HStack(spacing: 6) {
                CompassDial(bearing: entry.bearing, showTicks: false)
                VStack(alignment: .leading, spacing: 0) {
                    Text("القبلة").font(.headline)
                    Text(Qibla.degreesText(entry.bearing)).font(.title3.bold())
                    Text(Qibla.directionName(entry.bearing)).font(.caption2)
                }
            }
        default:
            small
        }
    }

    private var small: some View {
        VStack(spacing: 2) {
            HStack(spacing: 4) {
                Text("القبلة")
                    .font(.system(.subheadline, design: .rounded).weight(.semibold))
                Spacer(minLength: 0)
                if entry.isFallback {
                    Image(systemName: "location.slash")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            CompassDial(bearing: entry.bearing)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            Text(Qibla.degreesText(entry.bearing))
                .font(.system(size: 26, weight: .bold, design: .rounded))
                .minimumScaleFactor(0.6)
                .lineLimit(1)
            Text(Qibla.directionName(entry.bearing))
                .font(.caption2)
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
    }
}

// MARK: - تعريف الـ Widget

struct QiblaWidget: Widget {
    let kind = "QiblaWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            QiblaWidgetView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("اتجاه القبلة")
        .description("زاوية القبلة من مكانك. قارنها باتجاه العربية في التابلوه.")
        // systemSmall هو المقاس اللي بيظهر على CarPlay
        .supportedFamilies([.systemSmall, .accessoryCircular, .accessoryRectangular])
    }
}

@main
struct QiblaWidgetBundle: WidgetBundle {
    var body: some Widget {
        QiblaWidget()
    }
}
