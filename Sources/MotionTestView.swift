import SwiftUI

struct MotionTestView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var speedPPS: Double = 960 // Pixels Per Second
    @State private var isMinimized = false
    @State private var controlsHidden = false
    
    // Speed presets: Pixels Per Second
    let speeds = [
        (name: "Slow (240 pps)", val: 240.0),
        (name: "Medium (480 pps)", val: 480.0),
        (name: "Fast (960 pps)", val: 960.0),
        (name: "Max (1920 pps)", val: 1920.0)
    ]
    
    var body: some View {
        TimelineView(.animation) { timeline in
            Canvas { context, size in
                let time = timeline.date.timeIntervalSinceReferenceDate
                let period = size.width / speedPPS // Time to cross screen
                let offset = (time.remainder(dividingBy: period)) * speedPPS
                
                // Draw multiple bars
                let barWidth: CGFloat = 40
                let spacing: CGFloat = 200
                let totalWidth = barWidth + spacing
                let count = Int(size.width / totalWidth) + 2
                
                let phase = offset.remainder(dividingBy: totalWidth)
                
                for i in -1...count {
                    let x = (CGFloat(i) * totalWidth) + phase
                    let rect = CGRect(x: x, y: 0, width: barWidth, height: size.height)
                    context.fill(Path(rect), with: .color(.white))
                }
            }
        }
        .ignoresSafeArea()
        .overlay {
            ControlPanelDock(title: "Motion Test", isMinimized: $isMinimized, controlsHidden: controlsHidden) {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Evaluate motion clarity and ghosting with precise scrolling.")
                        .font(.callout)
                        .foregroundStyle(.secondary)

                    SectionHeader(title: "Scroll Speed")
                    VStack(spacing: 10) {
                        ForEach(speeds, id: \.name) { item in
                            Button(action: {
                                speedPPS = item.val
                                saveSettings()
                            }) {
                                HStack {
                                    Text(item.name)
                                        .font(.callout.weight(.semibold))
                                        .padding(.vertical, 8) // Added vertical padding
                                    Spacer()
                                    if speedPPS == item.val {
                                        Image(systemName: "checkmark")
                                    }
                                }
                                .foregroundStyle(.white)
                                .padding(.horizontal, 16) // Added horizontal padding
                                .background(Color.white.opacity(speedPPS == item.val ? 0.2 : 0.08))
                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                            }
                            .buttonStyle(.glassFocus(cornerRadius: 12))
                        }
                    }
                }
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .testControls(controlsHidden: $controlsHidden, dismiss: dismiss)
        .onAppear {
            loadSettings()
        }
    }
    
    private func saveSettings() {
        SettingsManager.shared.saveSetting(testId: "MotionTest", key: "speedPPS", value: speedPPS)
    }

    private func loadSettings() {
        speedPPS = SettingsManager.shared.getSetting(testId: "MotionTest", key: "speedPPS", defaultValue: 960.0)
    }
}

#Preview {
    MotionTestView()
}