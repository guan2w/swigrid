import SwiftUI

struct StarRowView: View {
    let count: Int
    let dual: Bool
    let showColorful: Bool
    let size: CGFloat

    @State private var hue = 0.0

    var body: some View {
        HStack(spacing: 4) {
            ForEach(0 ..< max(0, min(count, 5)), id: \.self) { _ in
                Image(systemName: dual ? "star.fill" : "star")
                    .font(.system(size: size))
                    .foregroundStyle(starColor)
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
        .onAppear {
            guard showColorful, count == 5 else {
                return
            }
            withAnimation(.linear(duration: 2.0).repeatForever(autoreverses: false)) {
                hue = 1.0
            }
        }
    }

    private var starColor: Color {
        if showColorful, count == 5 {
            return Color(hue: hue, saturation: 0.9, brightness: 1.0)
        }

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
