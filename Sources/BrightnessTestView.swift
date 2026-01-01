import SwiftUI

struct BrightnessTestView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var isMinimized = false
    @State private var windowSize: Double = 15
    @State private var controlsHidden = false

    var body: some View {
        GeometryReader { proxy in
            let size = min(proxy.size.width, proxy.size.height) * CGFloat(windowSize / 100)

            ZStack {
                Color.black.ignoresSafeArea()

                Rectangle()
                    .fill(Color.white)
                    .frame(width: size, height: size)

                ControlPanelDock(title: "Brightness", isMinimized: $isMinimized, controlsHidden: controlsHidden) {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Adjust the white window size to evaluate brightness uniformity.")
                            .font(.callout)
                            .foregroundStyle(.secondary)

                        SectionHeader(title: "Window Size")
                        LabeledSlider(value: $windowSize, range: 5...100, step: 1, suffix: "%")

                        Button {
                            windowSize = 15
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
    BrightnessTestView()
}
