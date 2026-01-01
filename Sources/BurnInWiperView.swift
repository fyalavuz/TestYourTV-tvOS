import SwiftUI

struct BurnInWiperView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var mode = 0 // 0: Noise, 1: Sweeper
    @State private var isMinimized = false
    @State private var controlsHidden = false
    @State private var startDate = Date()
    
    var body: some View {
        ZStack {
            TimelineView(.animation) { timeline in
                let time = Float(timeline.date.timeIntervalSince(startDate))
                
                if mode == 0 {
                    Color.black
                        .colorEffect(ShaderLibrary.color_noise(
                            .float(time)
                        ))
                        .ignoresSafeArea()
                } else {
                    GeometryReader { proxy in
                        // Scrolling White Bar logic (Manual simplified without new shader for now, or reuse gradient)
                        // Let's use a moving gradient
                        Rectangle()
                            .fill(
                                LinearGradient(
                                    colors: [.black, .white, .black],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .offset(x: CGFloat((time * 500).remainder(dividingBy: Float(proxy.size.width + 400))) - 200)
                            .frame(width: 400)
                    }
                    .background(Color.black)
                    .ignoresSafeArea()
                }
            }
            
            ControlPanelDock(title: "OLED Refresher", isMinimized: $isMinimized, controlsHidden: controlsHidden) {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Professional tools to clear image retention and exercise sub-pixels.")
                        .font(.callout)
                        .foregroundStyle(.secondary)

                    SectionHeader(title: "Mode")
                    HStack(spacing: 10) {
                        ToggleChip(title: "RGB Noise", isSelected: mode == 0) {
                            mode = 0
                        }
                        ToggleChip(title: "Luma Sweep", isSelected: mode == 1) {
                            mode = 1
                        }
                    }
                    
                    Text(mode == 0 ? "Uses high-frequency RGB noise to evenly wear all sub-pixels." : "Scrolls a high-contrast bar to wash out static retention.")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.6))
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .testControls(controlsHidden: $controlsHidden, dismiss: dismiss)
    }
}

#Preview {
    BurnInWiperView()
}
