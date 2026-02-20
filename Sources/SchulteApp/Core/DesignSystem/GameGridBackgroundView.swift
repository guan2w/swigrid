import SwiftUI

/// A decorative background built from randomly scattered, randomly sized and
/// slightly rotated large colour blocks drawn from a curated palette.  Every
/// time the view appears the whole composition is re‑randomised, giving each
/// game session a unique look.  A slow breathing animation keeps the scene
/// alive without distracting from gameplay.
struct GameGridBackgroundView: View {

    // -----------------------------------------------------------------------
    // MARK: – Types
    // -----------------------------------------------------------------------

    /// One randomly placed colour shard.
    struct Shard: Identifiable {
        let id: Int
        /// Centre position, expressed as a fraction of (width, height).
        let cx: CGFloat
        let cy: CGFloat
        /// Dimensions in points.
        let w: CGFloat
        let h: CGFloat
        /// Rotation in radians.
        let angle: CGFloat
        /// Corner radius (0 = sharp rectangle, larger = more pill‑like).
        let radius: CGFloat
        let color: Color
    }

    // -----------------------------------------------------------------------
    // MARK: – Palette
    // -----------------------------------------------------------------------

    private static let paletteSets: [[Color]] = [
        // Coral / teal / gold
        [
            Color(hue: 0.02, saturation: 0.72, brightness: 0.96),
            Color(hue: 0.52, saturation: 0.64, brightness: 0.90),
            Color(hue: 0.13, saturation: 0.80, brightness: 0.97),
            Color(hue: 0.58, saturation: 0.40, brightness: 0.85),
            Color(hue: 0.04, saturation: 0.50, brightness: 0.99),
        ],
        // Purple / mint / amber
        [
            Color(hue: 0.76, saturation: 0.60, brightness: 0.90),
            Color(hue: 0.43, saturation: 0.58, brightness: 0.88),
            Color(hue: 0.12, saturation: 0.75, brightness: 0.97),
            Color(hue: 0.80, saturation: 0.40, brightness: 0.95),
            Color(hue: 0.45, saturation: 0.35, brightness: 0.96),
        ],
        // Sky / rose / lime
        [
            Color(hue: 0.59, saturation: 0.65, brightness: 0.95),
            Color(hue: 0.95, saturation: 0.58, brightness: 0.98),
            Color(hue: 0.26, saturation: 0.62, brightness: 0.88),
            Color(hue: 0.61, saturation: 0.38, brightness: 0.90),
            Color(hue: 0.00, saturation: 0.45, brightness: 0.99),
        ],
        // Deep ocean / peach / chartreuse
        [
            Color(hue: 0.55, saturation: 0.80, brightness: 0.78),
            Color(hue: 0.07, saturation: 0.65, brightness: 0.99),
            Color(hue: 0.22, saturation: 0.72, brightness: 0.90),
            Color(hue: 0.57, saturation: 0.50, brightness: 0.70),
            Color(hue: 0.10, saturation: 0.40, brightness: 0.98),
        ],
    ]

    // -----------------------------------------------------------------------
    // MARK: – State
    // -----------------------------------------------------------------------

    @State private var shards: [Shard] = []
    @State private var breathe = false

    // -----------------------------------------------------------------------
    // MARK: – Body
    // -----------------------------------------------------------------------

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height

            Canvas { ctx, _ in
                for shard in shards {
                    // Convert fractional centre → real coordinates.
                    let px = shard.cx * w
                    let py = shard.cy * h
                    let rect = CGRect(
                        x: -shard.w / 2,
                        y: -shard.h / 2,
                        width:  shard.w,
                        height: shard.h
                    )
                    let roundedRect = Path(
                        roundedRect: rect,
                        cornerRadius: shard.radius
                    )

                    // Build an affine: translate to centre then rotate.
                    var transform = CGAffineTransform(translationX: px, y: py)
                    transform = transform.rotated(by: shard.angle)

                    ctx.fill(
                        roundedRect.applying(transform),
                        with: .color(shard.color)
                    )
                }
            }
            // Slow breathing opacity: 0.20 ↔ 0.30
            .opacity(breathe ? 0.30 : 0.20)
            .animation(
                .easeInOut(duration: 3.5).repeatForever(autoreverses: true),
                value: breathe
            )
            .onAppear {
                shards = Self.makeShards(in: CGSize(width: w, height: h))
                breathe = true
            }
        }
        .ignoresSafeArea()
    }

    // -----------------------------------------------------------------------
    // MARK: – Shard generation
    // -----------------------------------------------------------------------

    /// Generates ~30–40 randomly scattered, sized and rotated shards that
    /// together cover the full screen area without any regular grid pattern.
    private static func makeShards(in size: CGSize) -> [Shard] {
        let palette = paletteSets.randomElement()!
        let minDim = min(size.width, size.height)

        // Shard size range: 0.12 … 0.42 of the shorter screen dimension.
        let minSize: CGFloat = minDim * 0.18
        let maxSize: CGFloat = minDim * 0.55

        // Rotation range: ±28°
        let maxAngle: CGFloat = 28 * .pi / 180

        // We'll scatter points in a slightly over‑extended grid (−15 % … +115 %)
        // so shards visually bleed off all four edges.
        let count = 36
        var result: [Shard] = []
        result.reserveCapacity(count)

        var prevColorIdx: Int = -1

        for i in 0 ..< count {
            // Avoid repeating the same colour consecutively.
            var colorIdx: Int
            repeat { colorIdx = Int.random(in: 0 ..< palette.count) }
            while colorIdx == prevColorIdx && palette.count > 1
            prevColorIdx = colorIdx

            // Random centre in [−0.1, 1.1] so pieces hang off edges.
            let cx = CGFloat.random(in: -0.12 ... 1.12)
            let cy = CGFloat.random(in: -0.08 ... 1.08)

            // Width and height are independently random → square or oblong.
            let tw = CGFloat.random(in: minSize ... maxSize)
            let th = CGFloat.random(in: minSize ... maxSize)

            // Slight rounding: 8–28 % of the shorter side.
            let r = min(tw, th) * CGFloat.random(in: 0.08 ... 0.28)

            let angle = CGFloat.random(in: -maxAngle ... maxAngle)

            result.append(Shard(
                id: i,
                cx: cx, cy: cy,
                w: tw, h: th,
                angle: angle,
                radius: r,
                color: palette[colorIdx]
            ))
        }
        return result
    }
}

// ---------------------------------------------------------------------------
// MARK: – Preview
// ---------------------------------------------------------------------------

#Preview {
    ZStack {
        GameGridBackgroundView()
            .overlay(Color(uiColor: .systemBackground).opacity(0.55))
        Text("Challenge")
            .font(.system(size: 34, weight: .heavy, design: .rounded))
            .foregroundStyle(Color.primary)
    }
}
