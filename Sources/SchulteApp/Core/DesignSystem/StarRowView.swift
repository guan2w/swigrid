import SwiftUI

// MARK: - 彩虹渐变流动效果（对应 Flutter 的 AnimatedGradientWidget）
// 渐变流动动画周期（对应 Flutter 的 3000ms）
private let colorfulAnimDuration: Double = 3.0

struct StarRowView: View {
    let count: Int
    let dual: Bool
    let showColorful: Bool
    let size: CGFloat
    /// 是否使用逐颗弹入动效（仅结算弹窗需要，其他场景直接全量显示）
    var animated: Bool = false

    // 实际渲染的星星数量，由 onAppear 逐步推进、onChange 直接跳变
    @State private var displayCount: Int = 0
    // 用于取消前一轮 onAppear 分批调度（快速 appear/disappear 场景）
    @State private var staggerID: UUID = UUID()

    var body: some View {
        starContent
            .onAppear {
                let target = max(0, min(count, 5))
                if animated {
                    // 结算弹窗：逐颗弹入
                    let id = UUID()
                    staggerID = id
                    displayCount = 0
                    for i in 0..<target {
                        DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.10) {
                            guard staggerID == id else { return }
                            withAnimation(.spring(response: 0.42, dampingFraction: 0.62)) {
                                displayCount = i + 1
                            }
                        }
                    }
                } else {
                    // 其他场景：立即全量显示，不 stagger
                    displayCount = target
                }
            }
            .onChange(of: count) { _, newValue in
                // count 变化（如划动切换网格）→ 平滑过渡，无需 stagger
                staggerID = UUID() // 取消尚未触发的 onAppear 批次
                withAnimation(.spring(response: 0.38, dampingFraction: 0.68)) {
                    displayCount = max(0, min(newValue, 5))
                }
            }
    }

    // MARK: - 内容分支：普通色 vs 彩虹渐变
    @ViewBuilder
    private var starContent: some View {
        if showColorful, count == 5 {
            TimelineView(.animation) { timeline in
                let phase = timeline.date.timeIntervalSinceReferenceDate
                    .truncatingRemainder(dividingBy: colorfulAnimDuration)
                    / colorfulAnimDuration
                starsRow
                    .foregroundStyle(.white)
                    .overlay(RainbowGradientBand(phase: phase))
                    .mask(starsRow.foregroundStyle(.white))
            }
        } else {
            starsRow
                .foregroundStyle(starColor)
        }
    }

    // MARK: - 星星行（由 displayCount 驱动，ForEach 变化触发 transition）
    private var starsRow: some View {
        HStack(spacing: 4) {
            ForEach(0..<max(0, displayCount), id: \.self) { _ in
                Image(systemName: dual ? "star.fill" : "star")
                    .font(.system(size: size))
                    .transition(.asymmetric(
                        insertion: .scale(scale: 0.3).combined(with: .opacity),
                        removal:   .scale(scale: 0.3).combined(with: .opacity)
                    ))
            }
        }
    }

    private var starColor: Color {
        switch count {
        case 5:    return .orange
        case 3...4: return .orange.opacity(0.9)
        case 1...2: return .yellow.opacity(0.9)
        default:   return .gray.opacity(0.5)
        }
    }
}

// MARK: - 流动彩虹渐变色带
/// 9 个精确色点（每段 RYGBR 各占 50%，间距 12.5%），消除拼接抖动。
private struct RainbowGradientBand: View {
    let phase: Double

    private static let gradient = Gradient(stops: [
        .init(color: .red,    location: 0.000),
        .init(color: .yellow, location: 0.125),
        .init(color: .green,  location: 0.250),
        .init(color: .blue,   location: 0.375),
        .init(color: .red,    location: 0.500),
        .init(color: .yellow, location: 0.625),
        .init(color: .green,  location: 0.750),
        .init(color: .blue,   location: 0.875),
        .init(color: .red,    location: 1.000),
    ])

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            LinearGradient(gradient: Self.gradient, startPoint: .leading, endPoint: .trailing)
                .frame(width: w * 2)
                .offset(x: w * phase - w)
        }
        .clipped()
    }
}
