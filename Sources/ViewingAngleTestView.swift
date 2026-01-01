import SwiftUI

struct ViewingAngleTestView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var isMinimized = false
    @State private var circleSize: Double = 100
    @State private var controlsHidden = false

    var body: some View {
        GeometryReader { proxy in
            let gap = max(4, proxy.size.height * 0.005)
            let circle = CGFloat(circleSize)
            let columns = max(1, Int(proxy.size.width / circle))
            let rows = max(1, Int(proxy.size.height / circle))

            ZStack {
                Color.black.ignoresSafeArea()

                LazyVGrid(
                    columns: Array(repeating: GridItem(.flexible(), spacing: gap), count: columns),
                    spacing: gap
                ) {
                    ForEach(0..<(rows * columns), id: \.self) { _ in
                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [
                                        Color.white,
                                        Color.white.opacity(0.7),
                                        Color.white.opacity(0.3),
                                        Color.white.opacity(0)
                                    ],
                                    center: .center,
                                    startRadius: 0,
                                    endRadius: circleSize / 2
                                )
                            )
                            .frame(width: circle, height: circle)
                    }
                }
                .padding(gap)

                ControlPanelDock(title: "Viewing Angle", isMinimized: $isMinimized, controlsHidden: controlsHidden) {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Evaluate brightness and color shifts from different angles.")
                            .font(.callout)
                            .foregroundStyle(.secondary)

                        SectionHeader(title: "Circle Size")
                        LabeledSlider(value: $circleSize, range: 50...400, step: 10, suffix: "px")

                        Text("Grid: \(columns) x \(rows)")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        Button {
                            circleSize = 100
                        } label: {
                            Text("Reset Settings")
                                .font(.callout.weight(.semibold))
                                .foregroundStyle(.black)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(Color.white)
                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        }
                        .buttonStyle(.glassFocus(cornerRadius: 12))
                    }
                }
            }
            .toolbar(.hidden, for: .navigationBar)
            .testControls(controlsHidden: $controlsHidden, dismiss: dismiss)
        }
    }
}

#Preview {
    ViewingAngleTestView()
}
