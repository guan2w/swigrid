import SwiftUI

struct SplitGridBackgroundView: View {

    // MARK: – Curated hue palette
    // Only hues that look genuinely beautiful as light pastels.
    // Deliberately avoids muddy yellow-green (0.17–0.22) and
    // washed-out brown-purple (0.79–0.88) bands.
    private static let hues: [Double] = [
        0.02,  // coral-red
        0.06,  // warm red
        0.09,  // peach-orange
        0.12,  // amber
        0.16,  // gold
        0.27,  // lime
        0.36,  // sage
        0.44,  // mint
        0.50,  // teal
        0.57,  // sky
        0.62,  // cornflower
        0.68,  // periwinkle
        0.73,  // violet
        0.78,  // indigo
        0.92,  // rose
        0.97,  // hot-pink
    ]

    // MARK: – Per-row style (hash-based)
    //
    // Returns (hue, saturation, brightness) for a given row index.
    // Uses LCG + xor-shift so adjacent rows look completely different
    // rather than cycling through a predictable gradient.
    private func rowStyle(iiyInt: Int) -> (h: Double, s: Double, b: Double) {
        var v = UInt32(bitPattern: Int32(truncatingIfNeeded: iiyInt &* 1664525 &+ 1013904223))
        v ^= v >> 13
        v  = v &* 1540483477
        v ^= v >> 15

        let hue = Self.hues[Int(v % UInt32(Self.hues.count))]

        // Saturation: light pastels (0.30–0.50) with row-level variety
        let sats: [Double] = [0.30, 0.36, 0.42, 0.48, 0.50]
        let sat = sats[Int((v >> 8) % UInt32(sats.count))]

        // Brightness: nearly-white range (0.95–0.99)
        let bris: [Double] = [0.95, 0.96, 0.97, 0.98, 0.99]
        let bri = bris[Int((v >> 16) % UInt32(bris.count))]

        return (hue, sat, bri)
    }

    // MARK: – Body

    var body: some View {
        ZStack {
            // Smooth gradient background – provides the warm/cool split.
            LinearGradient(
                colors: [
                    Color(hue: 0.08, saturation: 0.07, brightness: 0.99),
                    Color(hue: 0.60, saturation: 0.09, brightness: 0.92),
                ],
                startPoint: .leading,
                endPoint: .trailing
            )

            TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { context in
                Canvas { ctx, size in
                    let t = context.date.timeIntervalSinceReferenceDate
                    let animVal = CGFloat(fmod(t / 3.0, 1.0))
                    let sq: CGFloat = 60
                    let w = size.width
                    let h = size.height
                    let cx = w / 2
                    let cy = h / 2

                    var startIX: CGFloat = 0
                    var startIY: CGFloat = 0.5
                    while sq * startIX > -w / 2 { startIX -= 1 }
                    while 0.5 * sq * startIY > -h / 2 { startIY -= 1 }

                    var iy = startIY
                    while 0.5 * sq * (iy - 1) < h / 2 {
                        let yAmt     = 2 * 0.5 * sq * iy / h
                        let typeFlag = posMod(iy, 2) < 1
                        let rowOffset: CGFloat = typeFlag ? 0 : 0.5
                        let iiyInt   = Int(iy.rounded())

                        var ix = startIX + rowOffset + animVal - 1
                        while sq * (ix - 1) < w / 2 {
                            let xAmt = 2 * sq * ix / w

                            if xAmt >  0.15 && typeFlag  { ix += 1; continue }
                            if xAmt < -0.15 && !typeFlag { ix += 1; continue }

                            var splitAmt = abs(xAmt) - 0.3
                            if splitAmt < 0 { splitAmt = 0 }
                            splitAmt *= splitAmt

                            var rotAmt = splitAmt * yAmt
                            if xAmt < 0 { rotAmt = -rotAmt }

                            let xPos  = cx + sq * ix
                            let yPos  = cy + 0.5 * sq * iy * (2 * splitAmt + 1)
                            let angle = 4 * .pi * rotAmt
                            let r     = sq / 2

                            // Colour: row-hash gives random hue/sat/bri;
                            // tiny ix coefficient (0.009 ≈ 3°/tile) makes
                            // the wrap-induced colour shift imperceptible.
                            let style  = rowStyle(iiyInt: iiyInt)
                            let rawHue = style.h + Double(ix) * 0.009
                            let hue    = rawHue - floor(rawHue)
                            let color  = Color(hue: hue, saturation: style.s, brightness: style.b)

                            // Alpha: smooth fade toward the centre boundary.
                            let alpha: Double
                            if typeFlag {
                                alpha = smoothStep(0.15, -0.40, Double(xAmt))
                            } else {
                                alpha = smoothStep(-0.15, 0.40, Double(xAmt))
                            }

                            var path = Path()
                            for i in 0..<4 {
                                let a  = angle + 2 * .pi * CGFloat(i) / 4
                                let px = xPos + r * cos(a)
                                let py = yPos + r * sin(a)
                                if i == 0 { path.move(to: CGPoint(x: px, y: py)) }
                                else       { path.addLine(to: CGPoint(x: px, y: py)) }
                            }
                            path.closeSubpath()
                            ctx.fill(path, with: .color(color.opacity(alpha)))

                            ix += 1
                        }
                        iy += 1
                    }
                }
            }
        }
        .ignoresSafeArea()
    }

    // MARK: – Utilities

    private func smoothStep(_ edge0: Double, _ edge1: Double, _ x: Double) -> Double {
        let t = max(0, min(1, (x - edge0) / (edge1 - edge0)))
        return t * t * (3 - 2 * t)
    }

    private func posMod(_ a: CGFloat, _ b: CGFloat) -> CGFloat {
        var out = a.truncatingRemainder(dividingBy: b)
        if out < 0 { out += b }
        return out
    }
}
