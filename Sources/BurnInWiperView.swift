import SwiftUI

struct BurnInWiperView: View {
    @State private var mode = 0 // 0: Noise, 1: Sweeper, 2: Luma Sweep
    @State private var speed: Double = 1.0
    @State private var startDate = Date()
    
    var body: some View {
        ZStack {
            TimelineView(.animation) { timeline in
                let time = Float(timeline.date.timeIntervalSince(startDate))
                
                if mode == 0 {
                    // RGB Noise
                    Color.black
                        .colorEffect(ShaderLibrary.color_noise(
                            .float(time * Float(speed))
                        ))
                        .ignoresSafeArea()
                } else if mode == 1 {
                    // Luma Noise
                    Color.black
                        .colorEffect(ShaderLibrary.noise_animated(
                            .float(time * Float(speed))
                        ))
                        .ignoresSafeArea()
                } else {
                    // Luma Sweep
                    GeometryReader { proxy in
                        Rectangle()
                            .fill(
                                LinearGradient(
                                    colors: [.black, .white, .black],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .offset(x: CGFloat((time * 500 * Float(speed)).remainder(dividingBy: Float(proxy.size.width + 400))) - 200)
                            .frame(width: 400)
                    }
                    .background(Color.black)
                    .ignoresSafeArea()
                }
            }
            
            VStack {
                Spacer()
                VStack(alignment: .leading, spacing: 12) {
                    Text("OLED Refresher")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                    HStack(spacing: 10) {
                        ToggleChip(title: "RGB Noise", isSelected: mode == 0) { mode = 0 }
                        ToggleChip(title: "Luma Noise", isSelected: mode == 1) { mode = 1 }
                        ToggleChip(title: "Luma Sweep", isSelected: mode == 2) { mode = 2 }
                    }
                    LabeledSlider(value: $speed, range: 0.5...3.0, step: 0.1, suffix: "x")
                }
                .padding()
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(Color.white.opacity(0.18), lineWidth: 1)
                )
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .onAppear {
            #if os(iOS) || os(tvOS)
            UIApplication.shared.isIdleTimerDisabled = true
            #endif
        }
        .onDisappear {
            #if os(iOS) || os(tvOS)
            UIApplication.shared.isIdleTimerDisabled = false
            #endif
        }
    }
}

#Preview {
    BurnInWiperView()
}
