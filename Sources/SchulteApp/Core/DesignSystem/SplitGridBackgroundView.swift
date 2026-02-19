import SwiftUI

struct SplitGridBackgroundView: View {
    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { context in
            Canvas { ctx, size in
                let t = context.date.timeIntervalSinceReferenceDate
                let animVal = CGFloat(fmod(t / 3.0, 1.0))
                let sq: CGFloat = 60
                let dark = Color(white: 0.74)
                let light = Color(white: 0.98)
                let w = size.width
                let h = size.height

                // Background: left light, right dark
                ctx.fill(Path(CGRect(x: 0, y: 0, width: w / 2, height: h)), with: .color(light))
                ctx.fill(Path(CGRect(x: w / 2, y: 0, width: w / 2, height: h)), with: .color(dark))

                // Origin at center
                let cx = w / 2
                let cy = h / 2

                var startIX: CGFloat = 0
                var startIY: CGFloat = 0.5
                while sq * startIX > -w / 2 { startIX -= 1 }
                while 0.5 * sq * startIY > -h / 2 { startIY -= 1 }

                var iy = startIY
                while 0.5 * sq * (iy - 1) < h / 2 {
                    let yAmt = 2 * 0.5 * sq * iy / h
                    let typeFlag = posMod(iy, 2) < 1
                    let color = typeFlag ? dark : light
                    let rowOffset: CGFloat = typeFlag ? 0 : 0.5

                    var ix = startIX + rowOffset + animVal - 1
                    while sq * (ix - 1) < w / 2 {
                        let xAmt = 2 * sq * ix / w

                        if xAmt > 0.15 && typeFlag { ix += 1; continue }
                        if xAmt < -0.15 && !typeFlag { ix += 1; continue }

                        var splitAmt = abs(xAmt) - 0.3
                        if splitAmt < 0 { splitAmt = 0 }
                        splitAmt *= splitAmt

                        var rotAmt = splitAmt * yAmt
                        if xAmt < 0 { rotAmt = -rotAmt }

                        let xPos = cx + sq * ix
                        let yPos = cy + 0.5 * sq * iy * (2 * splitAmt + 1)
                        let angle = 4 * .pi * rotAmt
                        let r = sq / 2

                        var path = Path()
                        for i in 0..<4 {
                            let a = angle + 2 * .pi * CGFloat(i) / 4
                            let px = xPos + r * cos(a)
                            let py = yPos + r * sin(a)
                            if i == 0 { path.move(to: CGPoint(x: px, y: py)) }
                            else { path.addLine(to: CGPoint(x: px, y: py)) }
                        }
                        path.closeSubpath()
                        ctx.fill(path, with: .color(color))

                        ix += 1
                    }
                    iy += 1
                }
            }
        }
        .ignoresSafeArea()
    }

    private func posMod(_ a: CGFloat, _ b: CGFloat) -> CGFloat {
        var out = a.truncatingRemainder(dividingBy: b)
        if out < 0 { out += b }
        return out
    }
}
