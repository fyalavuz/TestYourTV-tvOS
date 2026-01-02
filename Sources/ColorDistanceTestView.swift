import SwiftUI

struct ColorDistanceTestView: View {
    struct RGBColor {
        var r: Double
        var g: Double
        var b: Double

        var color: Color {
            Color(red: r / 255, green: g / 255, blue: b / 255)
        }

        var hex: String {
            String(format: "#%02X%02X%02X", Int(r), Int(g), Int(b))
        }
    }

    @Environment(\.dismiss) private var dismiss
    @State private var isMinimized = false
    @State private var background = RGBColor(r: 128, g: 128, b: 128)
    @State private var foreground = RGBColor(r: 160, g: 160, b: 160)
    @State private var controlsHidden = false

    // Contrast calculation helpers (WCAG 2.x)
    private func relativeLuminance(for color: RGBColor) -> Double {
        func channel(_ c: Double) -> Double {
            let srgb = c / 255.0
            return srgb <= 0.03928 ? (srgb / 12.92) : pow((srgb + 0.055) / 1.055, 2.4)
        }
        let r = channel(color.r)
        let g = channel(color.g)
        let b = channel(color.b)
        return 0.2126 * r + 0.7152 * g + 0.0722 * b
    }

    private func contrastRatio(bg: RGBColor, fg: RGBColor) -> Double {
        let L1 = max(relativeLuminance(for: bg), relativeLuminance(for: fg))
        let L2 = min(relativeLuminance(for: bg), relativeLuminance(for: fg))
        return (L1 + 0.05) / (L2 + 0.05)
    }

    private var contrast: Double {
        contrastRatio(bg: background, fg: foreground)
    }

    private var contrastSuggestion: String {
        switch contrast {
        case ..<3.0: return "Very low contrast — increase separation. Aim for ≥ 4.5:1 (normal text) or ≥ 3:1 (large)."
        case 3.0..<4.5: return "Low contrast — acceptable for large text (≥ 18pt bold / 24pt), but improve if possible."
        default: return "Good contrast — meets WCAG AA for normal text (≥ 4.5:1)."
        }
    }

    var body: some View {
        ZStack {
            background.color
                .ignoresSafeArea()

            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(foreground.color)
                .frame(width: 220, height: 220)
                .shadow(color: Color.black.opacity(0.4), radius: 18, y: 8)

            ControlPanelDock(title: "Color Distance", isMinimized: $isMinimized, controlsHidden: controlsHidden) {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Adjust foreground and background colors to test subtle differences.")
                        .font(.callout)
                        .foregroundStyle(.secondary)

                    ColorControl(title: "Background", color: background) { channel, value in
                        switch channel {
                        case "R": background.r = value
                        case "G": background.g = value
                        case "B": background.b = value
                        default: break
                        }
                    }

                    ColorControl(title: "Foreground", color: foreground) { channel, value in
                        switch channel {
                        case "R": foreground.r = value
                        case "G": foreground.g = value
                        case "B": foreground.b = value
                        default: break
                        }
                    }

                    SectionHeader(title: "Contrast")
                    VStack(alignment: .leading, spacing: 6) {
                        Text(String(format: "Contrast ratio: %.2f:1", contrast))
                            .font(.callout.weight(.semibold))
                            .foregroundStyle(.white)
                        Text(contrastSuggestion)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Button {
                        background = RGBColor(r: 128, g: 128, b: 128)
                        foreground = RGBColor(r: 160, g: 160, b: 160)
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

    // Inline updates keep state mutations explicit in the view.
}

struct ColorControl: View {
    let title: String
    let color: ColorDistanceTestView.RGBColor
    let onChange: (String, Double) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: "\(title) \(color.hex)")
            ColorPreview(color: color.color)
            ChannelSlider(label: "R", value: color.r, onChange: onChange)
            ChannelSlider(label: "G", value: color.g, onChange: onChange)
            ChannelSlider(label: "B", value: color.b, onChange: onChange)
        }
    }
}

struct ColorPreview: View {
    let color: Color

    var body: some View {
        RoundedRectangle(cornerRadius: 12, style: .continuous)
            .fill(color)
            .frame(height: 44)
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
            )
    }
}

struct ChannelSlider: View {
    let label: String
    let value: Double
    let onChange: (String, Double) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("\(label): \(Int(value))")
                .font(.caption)
                .foregroundStyle(.secondary)

            HStack(spacing: 10) {
                StepButton(symbol: "minus") {
                    onChange(label, max(0, value - 1))
                }

                ProgressTrack(progress: value / 255)
                    .frame(height: 6)

                StepButton(symbol: "plus") {
                    onChange(label, min(255, value + 1))
                }
            }
        }
    }
}

#Preview {
    ColorDistanceTestView()
}
