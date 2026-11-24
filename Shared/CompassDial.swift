import SwiftUI

/// قرص البوصلة مع سهم القبلة
/// - bearing: زاوية القبلة من الشمال
/// - heading: اتجاه الجهاز (لو nil القرص ثابت والشمال لفوق)
struct CompassDial: View {
    var bearing: Double
    var heading: Double? = nil
    var aligned: Bool = false
    var showTicks: Bool = true

    private var dialRotation: Double { -(heading ?? 0) }

    var body: some View {
        GeometryReader { geo in
            let size = min(geo.size.width, geo.size.height)
            ZStack {
                Circle()
                    .stroke(Color.primary.opacity(0.25), lineWidth: max(1.5, size * 0.03))

                if showTicks {
                    ForEach(0..<12) { i in
                        Rectangle()
                            .fill(Color.primary.opacity(i % 3 == 0 ? 0.6 : 0.25))
                            .frame(width: max(1, size * 0.012), height: size * (i % 3 == 0 ? 0.08 : 0.05))
                            .offset(y: -size * 0.44)
                            .rotationEffect(.degrees(Double(i) * 30))
                    }
                }

                // علامة الشمال
                Text("ش")
                    .font(.system(size: size * 0.14, weight: .bold, design: .rounded))
                    .foregroundStyle(.red)
                    .offset(y: -size * 0.31)
                    .rotationEffect(.degrees(0))

                // سهم القبلة
                QiblaArrow()
                    .fill(aligned ? Color.green : Color.accentColor)
                    .frame(width: size * 0.22, height: size * 0.62)
                    .offset(y: -size * 0.05)
                    .rotationEffect(.degrees(bearing))

                // مكعب الكعبة عند طرف السهم
                RoundedRectangle(cornerRadius: size * 0.02)
                    .fill(Color.primary)
                    .overlay(
                        Rectangle()
                            .fill(Color.yellow.opacity(0.85))
                            .frame(height: size * 0.018)
                            .offset(y: -size * 0.02)
                    )
                    .frame(width: size * 0.1, height: size * 0.1)
                    .offset(y: -size * 0.43)
                    .rotationEffect(.degrees(bearing))

                Circle()
                    .fill(Color.primary)
                    .frame(width: size * 0.06, height: size * 0.06)
            }
            .frame(width: size, height: size)
            .rotationEffect(.degrees(dialRotation))
            .position(x: geo.size.width / 2, y: geo.size.height / 2)
        }
        .aspectRatio(1, contentMode: .fit)
    }
}

/// شكل السهم
struct QiblaArrow: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: r.midX, y: r.minY))
        p.addLine(to: CGPoint(x: r.maxX, y: r.minY + r.height * 0.32))
        p.addLine(to: CGPoint(x: r.midX + r.width * 0.16, y: r.minY + r.height * 0.28))
        p.addLine(to: CGPoint(x: r.midX + r.width * 0.12, y: r.maxY))
        p.addLine(to: CGPoint(x: r.midX - r.width * 0.12, y: r.maxY))
        p.addLine(to: CGPoint(x: r.midX - r.width * 0.16, y: r.minY + r.height * 0.28))
        p.addLine(to: CGPoint(x: r.minX, y: r.minY + r.height * 0.32))
        p.closeSubpath()
        return p
    }
}
