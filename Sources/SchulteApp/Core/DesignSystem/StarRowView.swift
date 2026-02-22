import SwiftUI

// MARK: - 彩虹渐变流动效果（对应 Flutter 的 AnimatedGradientWidget）
// 渐变流动动画周期（对应 Flutter 的 3000ms）
private let colorfulAnimDuration: Double = 3.0

struct StarRowView: View {
    let count: Int
    let dual: Bool
    let showColorful: Bool
    let size: CGFloat

    var body: some View {
        let stars = HStack(spacing: 4) {
            ForEach(0 ..< max(0, min(count, 5)), id: \.self) { _ in
                Image(systemName: dual ? "star.fill" : "star")
                    .font(.system(size: size))
                    // 每颗星单独进出场动画
                    .transition(.asymmetric(
                        insertion: .scale(scale: 0.3).combined(with: .opacity),
                        removal:   .scale(scale: 0.3).combined(with: .opacity)
                    ))
            }
        }
        // count 或 dual 变化时触发弹性过渡
        .animation(.spring(response: 0.38, dampingFraction: 0.68), value: count)
        .animation(.spring(response: 0.35, dampingFraction: 0.7), value: dual)

        if showColorful, count == 5 {
            // 5 星彩色模式：流动彩虹渐变，等价于 Flutter ShaderMask + LinearGradient(tileMode: repeated)
            TimelineView(.animation) { timeline in
                let phase = timeline.date.timeIntervalSinceReferenceDate
                    .truncatingRemainder(dividingBy: colorfulAnimDuration)
                    / colorfulAnimDuration   // 0.0 ... 1.0，均匀推进
                stars
                    .foregroundStyle(.white)
                    .overlay(
                        RainbowGradientBand(phase: phase)
                    )
                    .mask(
                        stars
                            .foregroundStyle(.white)
                    )
            }
        } else {
            stars
                .foregroundStyle(starColor)
        }
    }

    private var starColor: Color {
        switch count {
        case 5:
            return .orange
        case 3...4:
            return .orange.opacity(0.9)
        case 1...2:
            return .yellow.opacity(0.9)
        default:
            return .gray.opacity(0.5)
        }
    }
}

// MARK: - 流动彩虹渐变色带
/// 用 GeometryReader + 精确 Gradient.Stop 模拟 tileMode: repeated：
/// 两段 RYGBR 各占 50%（间距 12.5%），保证 phase=1 与 phase=0 时可见区域完全对称，循环无跳变。
///
/// Bug 分析：若直接用 rygbrColors + rygbrColors（10 色等距），
/// SwiftUI 按 1/9 ≈ 11.1% 分配，中间两个 R 各在 44.4% 与 55.6%，
/// 两半颜色比例不一致，phase 归零时产生可见跳帧。
private struct RainbowGradientBand: View {
    let phase: Double   // 0.0 ... 1.0

    // 9 个色点，两段 RYGBR 各占精确 50%，共享中间的 R(0.5)
    // 每段内部间距 = 50% / 4 = 12.5%，与另一半完全对称
    private static let gradient = Gradient(stops: [
        .init(color: .red,    location: 0.000),  // 第1段起点
        .init(color: .yellow, location: 0.125),
        .init(color: .green,  location: 0.250),
        .init(color: .blue,   location: 0.375),
        .init(color: .red,    location: 0.500),  // 两段共享边界
        .init(color: .yellow, location: 0.625),
        .init(color: .green,  location: 0.750),
        .init(color: .blue,   location: 0.875),
        .init(color: .red,    location: 1.000),  // 第2段终点
    ])

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let offset = w * phase
            LinearGradient(gradient: Self.gradient, startPoint: .leading, endPoint: .trailing)
                .frame(width: w * 2)
                .offset(x: offset - w)
        }
        .clipped()  // 防止 2w 宽色带溢出到星星行外产生额外渲染瑕疵
    }
}
