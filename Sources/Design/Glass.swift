import SwiftUI

struct AmbientBackground: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.05, green: 0.12, blue: 0.18),
                    Color(red: 0.03, green: 0.06, blue: 0.10),
                    Color(red: 0.02, green: 0.03, blue: 0.05)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            RadialGradient(
                colors: [
                    Color(red: 0.15, green: 0.35, blue: 0.40, opacity: 0.35),
                    Color.clear
                ],
                center: .topLeading,
                startRadius: 80,
                endRadius: 520
            )
            .blendMode(.screen)

            Circle()
                .fill(Color(red: 0.90, green: 0.45, blue: 0.15, opacity: 0.20))
                .frame(width: 520, height: 520)
                .blur(radius: 80)
                .offset(x: -360, y: 180)

            Circle()
                .fill(Color(red: 0.20, green: 0.65, blue: 0.85, opacity: 0.20))
                .frame(width: 640, height: 640)
                .blur(radius: 90)
                .offset(x: 380, y: -240)
        }
        .ignoresSafeArea()
    }
}

struct GlassSurface: ViewModifier {
    let cornerRadius: CGFloat
    let strokeOpacity: Double

    func body(content: Content) -> some View {
        content
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(.ultraThinMaterial)
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(Color.white.opacity(strokeOpacity), lineWidth: 1)
            )
    }
}

struct FocusGlow: ViewModifier {
    @Environment(\.isFocused) private var isFocused
    let cornerRadius: CGFloat

    func body(content: Content) -> some View {
        content
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(Color.white.opacity(isFocused ? 0.7 : 0), lineWidth: isFocused ? 2 : 0)
            )
            .shadow(color: Color.white.opacity(isFocused ? 0.3 : 0), radius: isFocused ? 10 : 0)
            .animation(.easeOut(duration: 0.2), value: isFocused)
            .zIndex(isFocused ? 1 : 0)
    }
}

struct GlassInput: ViewModifier {
    let cornerRadius: CGFloat

    func body(content: Content) -> some View {
        content
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(Color.white.opacity(0.08))
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
            )
            .modifier(FocusGlow(cornerRadius: cornerRadius))
    }
}

struct GlassFocusButtonStyle: ButtonStyle {
    let cornerRadius: CGFloat

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .modifier(FocusGlow(cornerRadius: cornerRadius))
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

struct GlassHUD: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.caption.weight(.semibold))
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(.ultraThinMaterial)
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.3), radius: 10, y: 5)
    }
}

extension View {
    func glassSurface(cornerRadius: CGFloat = 26, strokeOpacity: Double = 0.18) -> some View {
        modifier(GlassSurface(cornerRadius: cornerRadius, strokeOpacity: strokeOpacity))
    }

    func glassInput(cornerRadius: CGFloat = 12) -> some View {
        modifier(GlassInput(cornerRadius: cornerRadius))
    }
    
    func glassHUD() -> some View {
        modifier(GlassHUD())
    }
}

struct LabeledSlider: View {
    @Binding var value: Double
    let range: ClosedRange<Double>
    let step: Double
    let suffix: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("\(formattedValue)\(suffix)")
                .font(.caption)
                .foregroundStyle(.secondary)
            HStack(spacing: 10) {
                StepButton(symbol: "minus") {
                    value = max(range.lowerBound, value - step)
                }

                ProgressTrack(progress: progress)
                    .frame(height: 6)

                StepButton(symbol: "plus") {
                    value = min(range.upperBound, value + step)
                }
            }
        }
    }

    private var formattedValue: String {
        if step < 1 {
            return String(format: "%.1f", value)
        }
        return String(format: "%.0f", value)
    }

    private var progress: Double {
        guard range.upperBound > range.lowerBound else { return 0 }
        return (value - range.lowerBound) / (range.upperBound - range.lowerBound)
    }
}

struct GlassIconButton: View {
    let symbol: String
    let size: CGFloat
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            GlassIconButtonLabel(symbol: symbol, size: size)
        }
        .buttonStyle(.glassFocus(cornerRadius: size / 2))
    }
}

struct GlassIconButtonLabel: View {
    let symbol: String
    let size: CGFloat
    @Environment(\.isFocused) private var isFocused

    var body: some View {
        Image(systemName: symbol)
            .font(.system(size: size * 0.45, weight: .semibold))
            .foregroundStyle(.white)
            .frame(width: size, height: size)
            .background(
                Circle()
                    .fill(Color.white.opacity(isFocused ? 0.24 : 0.12))
            )
            .overlay(
                Circle()
                    .stroke(Color.white.opacity(isFocused ? 0.55 : 0.2), lineWidth: 1)
            )
    }
}

struct StepButton: View {
    let symbol: String
    let action: () -> Void

    var body: some View {
        GlassIconButton(symbol: symbol, size: 40, action: action)
    }
}

struct ProgressTrack: View {
    let progress: Double

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color.white.opacity(0.12))
                Capsule()
                    .fill(Color.white.opacity(0.7))
                    .frame(width: proxy.size.width * CGFloat(max(0, min(1, progress))))
            }
        }
    }
}

extension ButtonStyle where Self == GlassFocusButtonStyle {
    static func glassFocus(cornerRadius: CGFloat = 14) -> GlassFocusButtonStyle {
        GlassFocusButtonStyle(cornerRadius: cornerRadius)
    }
}

struct ControlPanel<Content: View>: View {
    let title: String
    @Binding var isMinimized: Bool
    let content: Content

    init(title: String, isMinimized: Binding<Bool>, @ViewBuilder content: () -> Content) {
        self.title = title
        self._isMinimized = isMinimized
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text(title.uppercased())
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)
                    .tracking(1.2)

                Spacer()

                GlassIconButton(
                    symbol: isMinimized ? "chevron.up" : "chevron.down",
                    size: 36,
                    action: { isMinimized.toggle() }
                )
            }

            if !isMinimized {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        content
                    }
                    .padding(.horizontal, 4)
                    .padding(.bottom, 4)
                }
                .frame(maxHeight: 460)
                .scrollIndicators(.visible)
            }
        }
        .glassSurface()
        .padding(30)
        .transition(.move(edge: .leading).combined(with: .opacity))
    }
}

struct ControlPanelDock<Content: View>: View {
    let title: String
    @Binding var isMinimized: Bool
    let controlsHidden: Bool
    let content: Content

    init(title: String, isMinimized: Binding<Bool>, controlsHidden: Bool, @ViewBuilder content: () -> Content) {
        self.title = title
        self._isMinimized = isMinimized
        self.controlsHidden = controlsHidden
        self.content = content()
    }

    var body: some View {
        HStack {
            if !controlsHidden {
                VStack {
                    Spacer()
                    ControlPanel(title: title, isMinimized: $isMinimized) {
                        content
                    }
                    Spacer()
                }
            }
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct SectionHeader: View {
    let title: String

    var body: some View {
        Text(title)
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(.secondary)
            .tracking(0.8)
    }
}

struct ToggleChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.callout.weight(.semibold))
                .lineLimit(1)
                .minimumScaleFactor(0.85)
                .allowsTightening(true)
                .foregroundStyle(isSelected ? .black : .white)
                .padding(.vertical, 10)
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(isSelected ? Color.white : Color.white.opacity(0.12))
                )
        }
        .buttonStyle(.glassFocus(cornerRadius: 14))
    }
}

struct ColorOptionChip: View {
    let title: String
    let color: Color
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Circle()
                    .fill(color)
                    .frame(width: 18, height: 18)
                    .overlay(
                        Circle()
                            .stroke(Color.white.opacity(0.6), lineWidth: 1)
                    )

                Text(title)
                    .font(.callout.weight(.semibold))
                    .foregroundStyle(isSelected ? .black : .white)

                Spacer(minLength: 0)
            }
            .padding(.vertical, 10)
            .padding(.horizontal, 12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(isSelected ? Color.white : Color.white.opacity(0.12))
            )
        }
        .buttonStyle(.glassFocus(cornerRadius: 14))
    }
}

struct ToggleRow: View {
    let title: String
    let isOn: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Text(title)
                    .font(.callout.weight(.semibold))
                    .foregroundStyle(.white)

                Spacer()

                Text(isOn ? "On" : "Off")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(isOn ? .black : .white)
                    .padding(.vertical, 6)
                    .padding(.horizontal, 12)
                    .background(
                        Capsule()
                            .fill(isOn ? Color.white : Color.white.opacity(0.12))
                    )
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color.white.opacity(isOn ? 0.18 : 0.06))
            )
        }
        .buttonStyle(.glassFocus(cornerRadius: 14))
    }
}

struct ColorSwatch: View {
    let color: Color
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Circle()
                .fill(color)
                .frame(width: 36, height: 36)
                .overlay(
                    Circle()
                        .stroke(Color.white.opacity(isSelected ? 0.9 : 0.3), lineWidth: isSelected ? 3 : 1)
                )
                .shadow(color: color.opacity(isSelected ? 0.6 : 0.2), radius: isSelected ? 8 : 3)
        }
        .buttonStyle(.glassFocus(cornerRadius: 18))
    }
}

struct TestControlsModifier: ViewModifier {
    @Binding var controlsHidden: Bool
    let dismiss: DismissAction

    func body(content: Content) -> some View {
        let base = content
            .onPlayPauseCommand {
                withAnimation(.easeInOut(duration: 0.2)) {
                    controlsHidden.toggle()
                }
            }
            .onExitCommand {
                if controlsHidden {
                    dismiss()
                } else {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        controlsHidden = true
                    }
                }
            }

        Group {
            if controlsHidden {
                base
                    .contentShape(Rectangle())
                    .highPriorityGesture(
                        TapGesture().onEnded {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                controlsHidden = false
                            }
                        }
                    )
            } else {
                base
            }
        }
    }
}

extension View {
    func testControls(controlsHidden: Binding<Bool>, dismiss: DismissAction) -> some View {
        modifier(TestControlsModifier(controlsHidden: controlsHidden, dismiss: dismiss))
    }
}
