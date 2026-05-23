import SwiftUI

struct MizanScaleView: View {
    var tilt: Double = 0
    var size: CGFloat = 200
    @State private var swayAngle: Double = 0
    @State private var glowScale: CGFloat = 0.96

    private var tiltAngle: Double { tilt * 15 }
    private let lightGold = Color(hex: "D4AF37")
    private let midGold = Color(hex: "C8A96A")
    private let darkGold = Color(hex: "8B6F47")
    private let paleGold = Color(hex: "E8D5A3")

    var body: some View {
        let scaleFactor: CGFloat = size / 200.0

        ZStack {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [midGold.opacity(0.15), lightGold.opacity(0.06), .clear],
                        center: .center,
                        startRadius: 0,
                        endRadius: size * 0.65
                    )
                )
                .frame(width: size * 1.3, height: size * 1.3)
                .scaleEffect(glowScale)

            Canvas { context, canvasSize in
                let cx = canvasSize.width / 2
                let cy = canvasSize.height / 2
                let effectiveTilt = tiltAngle + swayAngle
                let radians = effectiveTilt * .pi / 180
                let s = scaleFactor

                drawBase(context: context, cx: cx, cy: cy, s: s)
                drawPillar(context: context, cx: cx, cy: cy, s: s)
                drawPivotOrnament(context: context, cx: cx, cy: cy, s: s)

                let pivotY = cy - 40 * s
                let beamLen: CGFloat = 74 * s
                let cosR = cos(radians)
                let sinR = sin(radians)
                let leftEnd = CGPoint(x: cx - beamLen * cosR, y: pivotY + beamLen * sinR)
                let rightEnd = CGPoint(x: cx + beamLen * cosR, y: pivotY - beamLen * sinR)

                drawBeam(context: context, cx: cx, pivotY: pivotY, left: leftEnd, right: rightEnd, s: s)
                drawBeamEndOrnaments(context: context, left: leftEnd, right: rightEnd, s: s)
                drawChains(context: context, from: leftEnd, s: s, isLeft: true)
                drawChains(context: context, from: rightEnd, s: s, isLeft: false)
                drawPan(context: context, at: leftEnd, s: s, isLeft: true)
                drawPan(context: context, at: rightEnd, s: s, isLeft: false)
            }
            .frame(width: size, height: size)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true)) {
                swayAngle = 3.0
            }
            withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                glowScale = 1.04
            }
        }
    }

    // MARK: - Base

    private func drawBase(context: GraphicsContext, cx: CGFloat, cy: CGFloat, s: CGFloat) {
        let baseY = cy + 54 * s
        let baseW: CGFloat = 52 * s
        let baseH: CGFloat = 9 * s
        let footW: CGFloat = 28 * s
        let footH: CGFloat = 4 * s

        var foot = Path()
        foot.addRoundedRect(
            in: CGRect(x: cx - footW / 2, y: baseY + baseH - 1 * s, width: footW, height: footH),
            cornerSize: CGSize(width: 2 * s, height: 2 * s)
        )
        context.fill(foot, with: .linearGradient(
            Gradient(colors: [darkGold, midGold.opacity(0.8)]),
            startPoint: CGPoint(x: cx - footW / 2, y: baseY + baseH),
            endPoint: CGPoint(x: cx + footW / 2, y: baseY + baseH + footH)
        ))
        context.stroke(foot, with: .color(darkGold.opacity(0.5)), lineWidth: 0.5 * s)

        var base = Path()
        base.move(to: CGPoint(x: cx - baseW / 2, y: baseY + baseH))
        base.addLine(to: CGPoint(x: cx - baseW * 0.38, y: baseY))
        base.addQuadCurve(
            to: CGPoint(x: cx + baseW * 0.38, y: baseY),
            control: CGPoint(x: cx, y: baseY - 4 * s)
        )
        base.addLine(to: CGPoint(x: cx + baseW / 2, y: baseY + baseH))
        base.closeSubpath()

        context.fill(base, with: .linearGradient(
            Gradient(colors: [lightGold, midGold, darkGold]),
            startPoint: CGPoint(x: cx - baseW / 2, y: baseY),
            endPoint: CGPoint(x: cx + baseW / 2, y: baseY + baseH)
        ))
        context.stroke(base, with: .color(darkGold), lineWidth: 0.8 * s)

        let scrollSize: CGFloat = 5 * s
        for dx in [-1.0, 1.0] as [CGFloat] {
            var scroll = Path()
            let sx = cx + dx * baseW * 0.22
            scroll.addEllipse(in: CGRect(
                x: sx - scrollSize / 2,
                y: baseY + baseH * 0.25,
                width: scrollSize,
                height: scrollSize * 0.55
            ))
            context.fill(scroll, with: .color(darkGold.opacity(0.25)))
            context.stroke(scroll, with: .color(paleGold.opacity(0.3)), lineWidth: 0.4 * s)
        }
    }

    // MARK: - Pillar

    private func drawPillar(context: GraphicsContext, cx: CGFloat, cy: CGFloat, s: CGFloat) {
        let topY = cy - 40 * s
        let botY = cy + 54 * s
        let pillarW: CGFloat = 5 * s
        let height = botY - topY

        var pillar = Path()
        pillar.addRoundedRect(
            in: CGRect(x: cx - pillarW / 2, y: topY, width: pillarW, height: height),
            cornerSize: CGSize(width: pillarW / 2, height: pillarW / 2)
        )
        context.fill(pillar, with: .linearGradient(
            Gradient(colors: [lightGold, midGold, darkGold]),
            startPoint: CGPoint(x: cx, y: topY),
            endPoint: CGPoint(x: cx, y: botY)
        ))
        context.stroke(pillar, with: .color(darkGold.opacity(0.4)), lineWidth: 0.5 * s)

        for fraction in [0.3, 0.5, 0.7] {
            let ringY = topY + height * fraction
            var ring = Path()
            ring.move(to: CGPoint(x: cx - pillarW * 0.8, y: ringY))
            ring.addLine(to: CGPoint(x: cx + pillarW * 0.8, y: ringY))
            context.stroke(ring, with: .color(paleGold.opacity(0.5)), lineWidth: 0.8 * s)
        }
    }

    // MARK: - Pivot Ornament (Diamond)

    private func drawPivotOrnament(context: GraphicsContext, cx: CGFloat, cy: CGFloat, s: CGFloat) {
        let pivotY = cy - 40 * s
        let ornH: CGFloat = 16 * s
        let ornW: CGFloat = 11 * s

        var diamond = Path()
        diamond.move(to: CGPoint(x: cx, y: pivotY - ornH * 0.55))
        diamond.addLine(to: CGPoint(x: cx + ornW * 0.5, y: pivotY))
        diamond.addLine(to: CGPoint(x: cx, y: pivotY + ornH * 0.38))
        diamond.addLine(to: CGPoint(x: cx - ornW * 0.5, y: pivotY))
        diamond.closeSubpath()

        context.fill(diamond, with: .linearGradient(
            Gradient(colors: [lightGold, midGold, lightGold]),
            startPoint: CGPoint(x: cx, y: pivotY - ornH * 0.55),
            endPoint: CGPoint(x: cx, y: pivotY + ornH * 0.38)
        ))
        context.stroke(diamond, with: .color(darkGold.opacity(0.5)), lineWidth: 0.8 * s)

        let innerScale: CGFloat = 0.45
        var innerDiamond = Path()
        innerDiamond.move(to: CGPoint(x: cx, y: pivotY - ornH * 0.55 * innerScale))
        innerDiamond.addLine(to: CGPoint(x: cx + ornW * 0.5 * innerScale, y: pivotY))
        innerDiamond.addLine(to: CGPoint(x: cx, y: pivotY + ornH * 0.38 * innerScale))
        innerDiamond.addLine(to: CGPoint(x: cx - ornW * 0.5 * innerScale, y: pivotY))
        innerDiamond.closeSubpath()
        context.fill(innerDiamond, with: .color(paleGold.opacity(0.55)))

        let finialR: CGFloat = 3.5 * s
        let finialY = pivotY - ornH * 0.55 - finialR * 0.8
        var finial = Path()
        finial.addEllipse(in: CGRect(x: cx - finialR, y: finialY - finialR, width: finialR * 2, height: finialR * 2))
        context.fill(finial, with: .linearGradient(
            Gradient(colors: [lightGold, midGold]),
            startPoint: CGPoint(x: cx, y: finialY - finialR),
            endPoint: CGPoint(x: cx, y: finialY + finialR)
        ))
        context.stroke(finial, with: .color(darkGold.opacity(0.4)), lineWidth: 0.5 * s)
    }

    // MARK: - Beam

    private func drawBeam(context: GraphicsContext, cx: CGFloat, pivotY: CGFloat, left: CGPoint, right: CGPoint, s: CGFloat) {
        let thickness: CGFloat = 3.8 * s
        let dx = right.x - left.x
        let dy = right.y - left.y
        let len = sqrt(dx * dx + dy * dy)
        guard len > 0 else { return }
        let nx = -dy / len * thickness / 2
        let ny = dx / len * thickness / 2

        var beam = Path()
        beam.move(to: CGPoint(x: left.x + nx, y: left.y + ny))
        beam.addLine(to: CGPoint(x: right.x + nx, y: right.y + ny))
        beam.addLine(to: CGPoint(x: right.x - nx, y: right.y - ny))
        beam.addLine(to: CGPoint(x: left.x - nx, y: left.y - ny))
        beam.closeSubpath()

        context.fill(beam, with: .linearGradient(
            Gradient(colors: [lightGold, midGold, lightGold]),
            startPoint: left,
            endPoint: right
        ))
        context.stroke(beam, with: .color(darkGold.opacity(0.35)), lineWidth: 0.5 * s)
    }

    private func drawBeamEndOrnaments(context: GraphicsContext, left: CGPoint, right: CGPoint, s: CGFloat) {
        for pt in [left, right] {
            let r: CGFloat = 4.5 * s
            var outer = Path()
            outer.addEllipse(in: CGRect(x: pt.x - r, y: pt.y - r, width: r * 2, height: r * 2))
            context.fill(outer, with: .linearGradient(
                Gradient(colors: [lightGold, midGold]),
                startPoint: CGPoint(x: pt.x, y: pt.y - r),
                endPoint: CGPoint(x: pt.x, y: pt.y + r)
            ))
            context.stroke(outer, with: .color(darkGold.opacity(0.4)), lineWidth: 0.6 * s)

            let ir: CGFloat = 2.2 * s
            var inner = Path()
            inner.addEllipse(in: CGRect(x: pt.x - ir, y: pt.y - ir, width: ir * 2, height: ir * 2))
            context.fill(inner, with: .color(paleGold.opacity(0.45)))
        }
    }

    // MARK: - Chains

    private func drawChains(context: GraphicsContext, from point: CGPoint, s: CGFloat, isLeft: Bool) {
        let panW: CGFloat = 36 * s
        let chainLen: CGFloat = 26 * s
        let halfW = panW / 2
        let offsets: [CGFloat] = [-halfW + 4 * s, 0, halfW - 4 * s]

        for offset in offsets {
            let bottomX = point.x + offset
            var chain = Path()
            chain.move(to: point)
            chain.addLine(to: CGPoint(x: bottomX, y: point.y + chainLen))
            context.stroke(chain, with: .color(midGold.opacity(0.6)), lineWidth: 0.8 * s)
        }
    }

    // MARK: - Pans

    private func drawPan(context: GraphicsContext, at point: CGPoint, s: CGFloat, isLeft: Bool) {
        let panW: CGFloat = 36 * s
        let panDepth: CGFloat = 16 * s
        let chainLen: CGFloat = 26 * s
        let halfW = panW / 2
        let panTop = point.y + chainLen

        var rim = Path()
        rim.addRoundedRect(
            in: CGRect(x: point.x - halfW - 2 * s, y: panTop - 2.5 * s, width: panW + 4 * s, height: 3.5 * s),
            cornerSize: CGSize(width: 1.5 * s, height: 1.5 * s)
        )
        context.fill(rim, with: .linearGradient(
            Gradient(colors: [lightGold, midGold]),
            startPoint: CGPoint(x: point.x - halfW, y: panTop),
            endPoint: CGPoint(x: point.x + halfW, y: panTop)
        ))
        context.stroke(rim, with: .color(darkGold.opacity(0.3)), lineWidth: 0.4 * s)

        var bowl = Path()
        bowl.move(to: CGPoint(x: point.x - halfW, y: panTop))
        bowl.addQuadCurve(
            to: CGPoint(x: point.x + halfW, y: panTop),
            control: CGPoint(x: point.x, y: panTop + panDepth)
        )
        bowl.closeSubpath()

        context.fill(bowl, with: .linearGradient(
            Gradient(colors: [lightGold, midGold, darkGold]),
            startPoint: CGPoint(x: point.x, y: panTop),
            endPoint: CGPoint(x: point.x, y: panTop + panDepth)
        ))
        context.stroke(bowl, with: .color(darkGold.opacity(0.5)), lineWidth: 1.0 * s)

        var highlight = Path()
        highlight.move(to: CGPoint(x: point.x - halfW * 0.55, y: panTop + 2.5 * s))
        highlight.addQuadCurve(
            to: CGPoint(x: point.x + halfW * 0.55, y: panTop + 2.5 * s),
            control: CGPoint(x: point.x, y: panTop + panDepth * 0.45)
        )
        context.stroke(highlight, with: .color(paleGold.opacity(0.35)), lineWidth: 0.6 * s)
    }
}
