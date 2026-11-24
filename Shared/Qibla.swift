import Foundation
import CoreLocation

/// حسابات القبلة — مشتركة بين التطبيق والـ Widget
enum Qibla {
    /// إحداثيات الكعبة المشرفة
    static let kaaba = CLLocationCoordinate2D(latitude: 21.422487, longitude: 39.826206)

    /// موقع افتراضي (الدوحة) لو الموقع مش متاح
    static let fallback = CLLocationCoordinate2D(latitude: 25.2854, longitude: 51.5310)

    /// زاوية القبلة من الشمال الحقيقي (0–360) بطريقة الدائرة العظمى
    static func bearing(from c: CLLocationCoordinate2D) -> Double {
        let lat1 = c.latitude * .pi / 180
        let lat2 = kaaba.latitude * .pi / 180
        let dLon = (kaaba.longitude - c.longitude) * .pi / 180
        let y = sin(dLon) * cos(lat2)
        let x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(dLon)
        let deg = atan2(y, x) * 180 / .pi
        return (deg + 360).truncatingRemainder(dividingBy: 360)
    }

    /// المسافة لمكة بالكيلومتر
    static func distanceKm(from c: CLLocationCoordinate2D) -> Double {
        let here = CLLocation(latitude: c.latitude, longitude: c.longitude)
        let mecca = CLLocation(latitude: kaaba.latitude, longitude: kaaba.longitude)
        return here.distance(from: mecca) / 1000
    }

    private static let names = [
        "شمال", "شمال شمال شرق", "شمال شرق", "شرق شمال شرق",
        "شرق", "شرق جنوب شرق", "جنوب شرق", "جنوب جنوب شرق",
        "جنوب", "جنوب جنوب غرب", "جنوب غرب", "غرب جنوب غرب",
        "غرب", "غرب شمال غرب", "شمال غرب", "شمال شمال غرب"
    ]

    /// اسم الاتجاه بالعربي (16 اتجاه)
    static func directionName(_ degrees: Double) -> String {
        let i = Int(((degrees + 11.25) / 22.5).rounded(.down)) % 16
        return names[(i + 16) % 16]
    }

    /// الفرق بين القبلة واتجاه معين (اتجاه الموبايل أو اتجاه سير العربية)
    /// الناتج بين -180 و 180: موجب = القبلة على اليمين، سالب = على الشمال
    static func relative(bearing: Double, to heading: Double) -> Double {
        var d = (bearing - heading).truncatingRemainder(dividingBy: 360)
        if d > 180 { d -= 360 }
        if d < -180 { d += 360 }
        return d
    }

    static func degreesText(_ d: Double) -> String {
        "\(Int(d.rounded()) % 360)°"
    }

    static func kmText(_ km: Double) -> String {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.maximumFractionDigits = 0
        f.locale = Locale(identifier: "en_US")
        return (f.string(from: NSNumber(value: km)) ?? "\(Int(km))") + " كم"
    }
}
