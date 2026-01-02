import SwiftUI

struct AmbientBackground: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    DS.ColorPalette.backgroundTop,
                    DS.ColorPalette.backgroundBottom
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            RadialGradient(
                colors: [
                    DS.ColorPalette.accentA.opacity(0.35),
                    Color.clear
                ],
                center: .topLeading,
                startRadius: 80,
                endRadius: 520
            )
            .blendMode(.screen)

            Circle()
                .fill(DS.ColorPalette.accentB.opacity(0.20))
                .frame(width: 520, height: 520)
                .blur(radius: 80)
                .offset(x: -360, y: 180)

            Circle()
                .fill(DS.ColorPalette.accentA.opacity(0.20))
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
                    .stroke(DS.ColorPalette.surfaceStroke.opacity(strokeOpacity / 0.18), lineWidth: 1)
            )
    }
}

struct FocusGlow: ViewModifier {
    @Environment(\.isFocused) private var isFocused
    let cornerRadius: CGFloat
    private let focusRingColor = DS.ColorPalette.accentA

    func body(content: Content) -> some View {
        content
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(focusRingColor.opacity(isFocused ? 0.95 : 0), lineWidth: isFocused ? 3 : 0)
            )
            .shadow(color: focusRingColor.opacity(isFocused ? 0.55 : 0), radius: isFocused ? 18 : 0)
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
                    .fill(DS.ColorPalette.surface.opacity(0.08))
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(DS.ColorPalette.surfaceStroke.opacity(0.1), lineWidth: 1)
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
            .font(DS.Typography.caption.weight(.semibold))
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(.ultraThinMaterial)
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(DS.ColorPalette.surfaceStroke, lineWidth: 1)
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
                    .fill(DS.ColorPalette.surface)
                Capsule()
                    .fill(DS.ColorPalette.textPrimary.opacity(0.7))
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

enum ControlPanelDockSide {
    case leading
    case trailing

    var alignment: Alignment {
        self == .leading ? .topLeading : .topTrailing
    }

    var transitionEdge: Edge {
        self == .leading ? .leading : .trailing
    }
}

struct ControlPanel<Content: View>: View {
    let title: String
    @Binding var isMinimized: Bool
    let fillsHeight: Bool
    let transitionEdge: Edge
    let content: Content

    init(
        title: String,
        isMinimized: Binding<Bool>,
        fillsHeight: Bool = true,
        transitionEdge: Edge = .leading,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self._isMinimized = isMinimized
        self.fillsHeight = fillsHeight
        self.transitionEdge = transitionEdge
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: isMinimized ? 0 : 16) {
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
                .frame(maxHeight: fillsHeight ? .infinity : nil, alignment: .topLeading)
                .scrollIndicators(.visible)
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 24)
        .padding(.bottom, isMinimized ? 16 : 24)
        .frame(maxWidth: .infinity, maxHeight: fillsHeight ? .infinity : nil, alignment: .topLeading)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .fill(.ultraThinMaterial)
                RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .fill(Color.black.opacity(0.25))
            }
        )
        .overlay(
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .stroke(Color.white.opacity(0.18), lineWidth: 1)
        )
        .transition(.move(edge: transitionEdge).combined(with: .opacity))
    }
}

struct ControlPanelDock<Content: View>: View {
    let title: String
    @Binding var isMinimized: Bool
    let controlsHidden: Bool
    let fillsHeight: Bool
    let dockSide: ControlPanelDockSide
    let content: Content

    init(
        title: String,
        isMinimized: Binding<Bool>,
        controlsHidden: Bool,
        fillsHeight: Bool = true,
        dockSide: ControlPanelDockSide = .leading,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self._isMinimized = isMinimized
        self.controlsHidden = controlsHidden
        self.fillsHeight = fillsHeight
        self.dockSide = dockSide
        self.content = content()
    }

    var body: some View {
        GeometryReader { proxy in
            let panelWidth = proxy.size.width * 0.35
            let panelHeight: CGFloat? = isMinimized ? min(proxy.size.height, 88) : (fillsHeight ? proxy.size.height : nil)
            HStack(alignment: .top, spacing: 0) {
                if dockSide == .trailing {
                    Spacer(minLength: 0)
                }
                if !controlsHidden {
                    ControlPanel(title: title, isMinimized: $isMinimized, fillsHeight: fillsHeight, transitionEdge: dockSide.transitionEdge) {
                        content
                    }
                    .frame(
                        width: panelWidth,
                        height: panelHeight,
                        alignment: .topLeading
                    )
                }
                if dockSide == .leading {
                    Spacer(minLength: 0)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: dockSide.alignment)
        }
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
            let shape = RoundedRectangle(cornerRadius: 14, style: .continuous)
            shape
                .fill(color)
                .overlay(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.35),
                            Color.clear,
                            Color.black.opacity(0.35)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .clipShape(shape)
                )
                .overlay(
                    shape
                        .stroke(Color.white.opacity(isSelected ? 0.9 : 0.3), lineWidth: isSelected ? 3 : 1)
                )
                .frame(minWidth: 72, maxWidth: .infinity, minHeight: 48)
        }
        .buttonStyle(.glassFocus(cornerRadius: 14))
        .accessibilityLabel(Text(title))
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

struct CheckboxRow: View {
    let title: String
    let isOn: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(isOn ? Color.white : Color.white.opacity(0.1))
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .stroke(Color.white.opacity(isOn ? 0.9 : 0.4), lineWidth: 1)
                    if isOn {
                        Image(systemName: "checkmark")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(.black)
                    }
                }
                .frame(width: 22, height: 22)

                Text(title)
                    .font(.callout.weight(.semibold))
                    .foregroundStyle(.white)

                Spacer(minLength: 0)
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color.white.opacity(isOn ? 0.14 : 0.06))
            )
        }
        .buttonStyle(.glassFocus(cornerRadius: 12))
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
struct GlassCheckboxToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        Button {
            configuration.isOn.toggle()
        } label: {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(configuration.isOn ? Color.white : Color.white.opacity(0.1))
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .stroke(Color.white.opacity(configuration.isOn ? 0.9 : 0.4), lineWidth: 1)
                    if configuration.isOn {
                        Image(systemName: "checkmark")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(.black)
                    }
                }
                .frame(width: 22, height: 22)

                configuration.label

                Spacer(minLength: 0)
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color.white.opacity(configuration.isOn ? 0.14 : 0.06))
            )
        }
        .buttonStyle(.glassFocus(cornerRadius: 12))
        .accessibilityValue(configuration.isOn ? "On" : "Off")
    }
}
