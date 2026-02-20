import SwiftUI
import SchulteDomain

struct GridConfiguratorView: View {
    @Binding var scale: Int
    @Binding var dual: Bool
    let width: CGFloat

    @State private var scrolledID: Int?

    // itemW = width/2 guarantees visible adjacent text = textW/2 (half of "N × N")
    private var itemW: CGFloat { width / 2 }
    private var peekW: CGFloat { width / 4 }

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 0) {
                ForEach(GridConfig.allowedScales, id: \.self) { s in
                    let isSelected = s == scale
                    Text("\(s) × \(s)")
                        .font(.system(size: 18, weight: dual ? .bold : .regular))
                        .foregroundStyle(
                            Color(red: 0.05, green: 0.34, blue: 0.49)
                                .opacity(isSelected ? 1.0 : 0.38)
                        )
                        // 选中项放大，未选中项缩小，布局 frame 保持不变避免回流
                        .scaleEffect(isSelected ? 1.18 : 0.88)
                        .animation(.spring(response: 0.35, dampingFraction: 0.7), value: isSelected)
                        .animation(.spring(response: 0.35, dampingFraction: 0.7), value: dual)
                        .frame(width: itemW, height: 44)
                        .id(s)
                }
            }
            .scrollTargetLayout()
        }
        .frame(width: width, height: 44)
        .contentMargins(.horizontal, peekW, for: .scrollContent)
        .scrollTargetBehavior(.viewAligned)
        .scrollPosition(id: $scrolledID)
        .onChange(of: scrolledID) { _, newValue in
            if let v = newValue { scale = v }
        }
        .onTapGesture {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                dual.toggle()
            }
        }
        .onAppear { scrolledID = scale }
        .onChange(of: scale) { _, newValue in
            // 星星区域滑动触发 scale 变化时，scroll 也带弹性动画
            withAnimation(.spring(response: 0.4, dampingFraction: 0.72)) {
                scrolledID = newValue
            }
        }
    }
}
