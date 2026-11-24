import SwiftUI
import CoreLocation

@main
struct QiblaApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.layoutDirection, .rightToLeft)
        }
    }
}

struct ContentView: View {
    @StateObject private var model = LocationModel()
    @Environment(\.scenePhase) private var scenePhase

    private var relativeToPhone: Double? {
        guard let h = model.heading else { return nil }
        return Qibla.relative(bearing: model.bearing, to: h)
    }

    private var aligned: Bool {
        guard let r = relativeToPhone else { return false }
        return abs(r) < 4
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                header

                if model.status == .denied || model.status == .restricted {
                    deniedCard
                } else if model.status == .notDetermined {
                    Button {
                        model.requestPermission()
                    } label: {
                        Label("السماح بمعرفة الموقع", systemImage: "location.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                }

                CompassDial(bearing: model.bearing, heading: model.heading, aligned: aligned)
                    .frame(maxWidth: 320)
                    .animation(.easeOut(duration: 0.2), value: model.heading)
                    .padding(.horizontal)

                if aligned {
                    Label("إنت متوجه للقبلة", systemImage: "checkmark.circle.fill")
                        .font(.title3.bold())
                        .foregroundStyle(.green)
                } else if let r = relativeToPhone {
                    Text(r > 0 ? "لف يمين \(Int(abs(r).rounded()))°" : "لف شمال \(Int(abs(r).rounded()))°")
                        .font(.title3.bold())
                }

                infoGrid

                if let course = model.drivingCourse {
                    drivingCard(course: course)
                }

                if model.headingAccuracy > 20 {
                    Text("البوصلة محتاجة معايرة: حرّك الموبايل على شكل رقم 8، وبعّده عن العربية والحديد.")
                        .font(.footnote)
                        .foregroundStyle(.orange)
                        .multilineTextAlignment(.center)
                }

                carPlayHelp
            }
            .padding()
        }
        .onAppear { model.start() }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { model.start() } else { model.stop() }
        }
    }

    private var header: some View {
        VStack(spacing: 4) {
            Text("القبلة")
                .font(.largeTitle.bold())
            Text(model.location == nil ? "الموقع الافتراضي: الدوحة" : "حسب موقعك الحالي")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    private var infoGrid: some View {
        HStack(spacing: 12) {
            infoBox(title: "زاوية القبلة", value: Qibla.degreesText(model.bearing),
                    sub: Qibla.directionName(model.bearing))
            infoBox(title: "المسافة لمكة", value: Qibla.kmText(Qibla.distanceKm(from: model.coordinate)),
                    sub: "خط مستقيم")
        }
    }

    private func infoBox(title: String, value: String, sub: String) -> some View {
        VStack(spacing: 4) {
            Text(title).font(.caption).foregroundStyle(.secondary)
            Text(value).font(.title2.bold()).minimumScaleFactor(0.6).lineLimit(1)
            Text(sub).font(.caption2).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 14))
    }

    /// القبلة بالنسبة لاتجاه سير العربية (من الـ GPS، مش البوصلة)
    private func drivingCard(course: Double) -> some View {
        let r = Qibla.relative(bearing: model.bearing, to: course)
        let side: String
        if abs(r) < 10 { side = "القبلة قدامك" }
        else if abs(r) > 170 { side = "القبلة وراك" }
        else { side = r > 0 ? "القبلة على يمينك" : "القبلة على شمالك" }
        return VStack(spacing: 6) {
            Label("وضع العربية", systemImage: "car.fill").font(.headline)
            Text(side).font(.title3.bold())
            Text("بزاوية \(Int(abs(r).rounded()))° من اتجاه السير")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.accentColor.opacity(0.12), in: RoundedRectangle(cornerRadius: 14))
    }

    private var deniedCard: some View {
        VStack(spacing: 8) {
            Text("إذن الموقع مقفول، فبنحسب القبلة من الدوحة.")
            Button("افتح الإعدادات") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
        }
        .font(.footnote)
        .padding()
        .background(.orange.opacity(0.12), in: RoundedRectangle(cornerRadius: 12))
    }

    private var carPlayHelp: some View {
        VStack(alignment: .leading, spacing: 6) {
            Label("إظهار القبلة على CarPlay", systemImage: "car.rear.fill")
                .font(.headline)
            Text("١. الإعدادات ← عام ← CarPlay ← اختار عربيتك ← الأدوات (Widgets)")
            Text("٢. ضيف أداة «اتجاه القبلة»")
            Text("٣. على شاشة العربية اسحب يمين/شمال من الشاشة الرئيسية لحد ما تلاقيها")
            Text("قارن الرقم باتجاه العربية في التابلوه. مثال: لو القبلة 253° والعربية رايحة 253° يبقى القبلة قدامك.")
                .foregroundStyle(.secondary)
        }
        .font(.footnote)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 14))
    }
}
