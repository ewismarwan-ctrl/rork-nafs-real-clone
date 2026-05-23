import SwiftUI

struct CrescentStarMark: View {
    var size: CGFloat = 80
    var color: Color = NafsTheme.gold

    var body: some View {
        Canvas { context, canvasSize in
            let cx = canvasSize.width / 2
            let cy = canvasSize.height / 2
            let radius = min(canvasSize.width, canvasSize.height) * 0.38

            var fullCircle = Path()
            fullCircle.addEllipse(in: CGRect(
                x: cx - radius,
                y: cy - radius,
                width: radius * 2,
                height: radius * 2
            ))

            let cutoutRadius = radius * 0.78
            let cutoutOffsetX = radius * 0.45
            let cutoutOffsetY = -radius * 0.35
            var cutout = Path()
            cutout.addEllipse(in: CGRect(
                x: cx + cutoutOffsetX - cutoutRadius,
                y: cy + cutoutOffsetY - cutoutRadius,
                width: cutoutRadius * 2,
                height: cutoutRadius * 2
            ))

            var crescent = fullCircle
            crescent = crescent.subtracting(cutout)

            context.fill(crescent, with: .color(color))

            let starSize = radius * 0.22
            let starX = cx + radius * 0.58
            let starY = cy - radius * 0.62
            let starPath = fivePointedStar(center: CGPoint(x: starX, y: starY), radius: starSize)
            context.fill(starPath, with: .color(color))
        }
        .frame(width: size, height: size)
    }

    private func fivePointedStar(center: CGPoint, radius: CGFloat) -> Path {
        var path = Path()
        let innerRadius = radius * 0.4
        let points = 5
        let angleOffset = -CGFloat.pi / 2

        for i in 0..<(points * 2) {
            let isOuter = i % 2 == 0
            let r = isOuter ? radius : innerRadius
            let angle = angleOffset + CGFloat(i) * .pi / CGFloat(points)
            let point = CGPoint(
                x: center.x + r * cos(angle),
                y: center.y + r * sin(angle)
            )
            if i == 0 {
                path.move(to: point)
            } else {
                path.addLine(to: point)
            }
        }
        path.closeSubpath()
        return path
    }
}

struct NafsWordmark: View {
    var fontSize: CGFloat = 16
    var color: Color = NafsTheme.text

    var body: some View {
        Text("NAFS")
            .font(.system(size: fontSize, weight: .medium, design: .serif))
            .foregroundStyle(color)
            .tracking(fontSize * 0.6)
    }
}

struct NafsHeaderBrand: View {
    var body: some View {
        HStack(spacing: 10) {
            CrescentStarMark(size: 28, color: NafsTheme.gold)
            Text("NAFS")
                .font(.system(size: 14, weight: .medium, design: .serif))
                .foregroundStyle(NafsTheme.text)
                .tracking(8)
        }
    }
}
