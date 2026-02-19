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
                    Text("\(s) × \(s)")
                        .font(.system(size: 18, weight: dual ? .bold : .regular))
                        .foregroundStyle(Color(red: 0.05, green: 0.34, blue: 0.49))
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
        .onTapGesture { dual.toggle() }
        .onAppear { scrolledID = scale }
    }
}
