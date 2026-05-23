import SwiftUI

struct IslamicPatternView: View {
    var opacity: Double = 0.06

    var body: some View {
        GeometryReader { geo in
            let patternImage = UIImage(named: "islamic_pattern_bg")
            if let img = patternImage {
                Image(uiImage: img)
                    .resizable(resizingMode: .tile)
                    .opacity(opacity)
                    .ignoresSafeArea()
            } else {
                GeometricPatternFallback(opacity: opacity)
                    .ignoresSafeArea()
            }
        }
    }
}

struct GeometricPatternFallback: View {
    var opacity: Double

    var body: some View {
        Canvas { context, size in
            let spacing: CGFloat = 40
            let cols = Int(size.width / spacing) + 2
            let rows = Int(size.height / spacing) + 2

            for row in 0..<rows {
                for col in 0..<cols {
                    let x = CGFloat(col) * spacing
                    let y = CGFloat(row) * spacing

                    var path = Path()
                    path.move(to: CGPoint(x: x, y: y - 8))
                    path.addLine(to: CGPoint(x: x + 8, y: y))
                    path.addLine(to: CGPoint(x: x, y: y + 8))
                    path.addLine(to: CGPoint(x: x - 8, y: y))
                    path.closeSubpath()

                    context.stroke(
                        path,
                        with: .color(NafsTheme.gold.opacity(opacity)),
                        lineWidth: 0.5
                    )
                }
            }
        }
    }
}
