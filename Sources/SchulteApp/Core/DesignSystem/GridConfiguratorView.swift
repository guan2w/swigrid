import SwiftUI
import SchulteDomain

struct GridConfiguratorView: View {
    @Binding var scale: Int
    @Binding var dual: Bool

    @State private var scrolledID: Int?

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 24) {
                ForEach(GridConfig.allowedScales, id: \.self) { s in
                    Text("\(s) × \(s)")
                        .font(.system(size: s == scale ? 18 : 15, weight: dual ? .bold : .regular))
                        .foregroundStyle(s == scale ? Color(red: 0.05, green: 0.34, blue: 0.49) : .secondary)
                        .id(s)
                }
            }
            .scrollTargetLayout()
            .padding(.horizontal, 40)
        }
        .scrollTargetBehavior(.viewAligned)
        .scrollPosition(id: $scrolledID)
        .onChange(of: scrolledID) { _, newValue in
            if let v = newValue { scale = v }
        }
        .onTapGesture { dual.toggle() }
        .onAppear { scrolledID = scale }
    }
}
