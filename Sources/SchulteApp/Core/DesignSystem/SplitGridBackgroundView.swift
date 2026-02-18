import SwiftUI

struct SplitGridBackgroundView: View {
    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { context in
            Canvas { canvas, size in
                let t = context.date.timeIntervalSinceReferenceDate
                let columns = 12
                let rows = 24
                let cellW = size.width / CGFloat(columns)
                let cellH = size.height / CGFloat(rows)

                for row in 0 ..< rows {
                    for col in 0 ..< columns {
                        let shift = sin(t * 0.6 + Double(row) * 0.25) * 4.0
                        let x = CGFloat(col) * cellW + CGFloat(shift)
                        let y = CGFloat(row) * cellH

                        let isDark = (row + col) % 2 == 0
                        let base = isDark
                            ? Color(red: 0.85, green: 0.92, blue: 0.96)
                            : Color(red: 0.95, green: 0.98, blue: 1.0)

                        canvas.fill(
                            Path(CGRect(x: x, y: y, width: cellW + 1, height: cellH + 1)),
                            with: .color(base)
                        )
                    }
                }
            }
        }
        .ignoresSafeArea()
    }
}
