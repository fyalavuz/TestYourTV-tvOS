import SwiftUI

struct ColorGradientTestView: View {
    enum TargetColor: String, CaseIterable, Identifiable {
        case white = "White"
        case red = "Red"
        case green = "Green"
        case blue = "Blue"
        case magenta = "Magenta"
        case yellow = "Yellow"
        case cyan = "Cyan"
        case orange = "Orange"

        var id: String { rawValue }

        var rgb: (Double, Double, Double) {
            switch self {
            case .white: return (1, 1, 1)
            case .red: return (1, 0, 0)
            case .green: return (0, 1, 0)
            case .blue: return (0, 0, 1)
            case .magenta: return (1, 0, 1)
            case .yellow: return (1, 1, 0)
            case .cyan: return (0, 1, 1)
            case .orange: return (1, 0.65, 0)
            }
        }
    }

    enum GradientDirection: String, CaseIterable, Identifiable {
        case horizontal = "Horizontal"
        case vertical = "Vertical"
        case diagonalOne = "Diagonal 1"
        case diagonalTwo = "Diagonal 2"
        case diagonalThree = "Diagonal 3"
        case diagonalFour = "Diagonal 4"

        var id: String { rawValue }

        var points: (UnitPoint, UnitPoint) {
            switch self {
            case .horizontal: return (.leading, .trailing)
            case .vertical: return (.top, .bottom)
            case .diagonalOne: return (.topLeading, .bottomTrailing)
            case .diagonalTwo: return (.bottomLeading, .topTrailing)
            case .diagonalThree: return (.topTrailing, .bottomLeading)
            case .diagonalFour: return (.bottomTrailing, .topLeading)
            }
        }
    }

    enum GradientType: String, CaseIterable, Identifiable {
        case linear = "Linear"
        case radial = "Radial"
        var id: String { rawValue }
    }

    enum Distribution: String, CaseIterable, Identifiable {
        case linear = "Linear"
        case nonLinear = "Non-Linear"
        var id: String { rawValue }
    }

    @Environment(\.dismiss) private var dismiss
    @State private var steps: Double = 32
    @State private var targetColor: TargetColor = .white
    @State private var direction: GradientDirection = .horizontal
    @State private var gradientType: GradientType = .linear
    @State private var distribution: Distribution = .linear
    @State private var isMinimized = false
    @State private var controlsHidden = false

    var body: some View {
        ZStack {
            GeometryReader { proxy in
                Rectangle()
                    .fill(.black) // Base color, shader will overwrite
                    .colorEffect(ShaderLibrary.pro_gradient(
                        .float2(proxy.size),
                        .float(steps),
                        .float(gradientType == .linear ? 0 : 1),
                        .float(directionIndex),
                        .float3(vectorColor.x, vectorColor.y, vectorColor.z),
                        .float(distribution == .linear ? 0 : 1)
                    ))
            }
            .ignoresSafeArea()

            ControlPanelDock(title: "Color Gradient", isMinimized: $isMinimized, controlsHidden: controlsHidden) {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Evaluate color banding and gradient smoothness using GPU shaders.")
                        .font(.callout)
                        .foregroundStyle(.secondary)

                    SectionHeader(title: "Target Color")
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 120), spacing: 10)], spacing: 10) {
                        ForEach(TargetColor.allCases) { option in
                            ToggleChip(title: option.rawValue, isSelected: targetColor == option) {
                                targetColor = option
                            }
                        }
                    }

                    SectionHeader(title: "Gradient Steps")
                    LabeledSlider(value: $steps, range: 8...256, step: 8, suffix: "steps")

                    SectionHeader(title: "Direction")
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 140), spacing: 10)], spacing: 10) {
                        ForEach(GradientDirection.allCases) { option in
                            ToggleChip(title: option.rawValue, isSelected: direction == option) {
                                direction = option
                            }
                        }
                    }

                    SectionHeader(title: "Gradient Type")
                    HStack(spacing: 10) {
                        ForEach(GradientType.allCases) { option in
                            ToggleChip(title: option.rawValue, isSelected: gradientType == option) {
                                gradientType = option
                            }
                        }
                    }

                    SectionHeader(title: "Step Distribution")
                    HStack(spacing: 10) {
                        ForEach(Distribution.allCases) { option in
                            ToggleChip(title: option.rawValue, isSelected: distribution == option) {
                                distribution = option
                            }
                        }
                    }

                    Button {
                        steps = 256
                        targetColor = .white
                        direction = .horizontal
                        gradientType = .linear
                        distribution = .linear
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
        .onAppear {
            loadSettings()
        }
        .onChange(of: steps) { _, _ in saveSettings() }
        .onChange(of: targetColor) { _, _ in saveSettings() }
        .onChange(of: direction) { _, _ in saveSettings() }
        .onChange(of: gradientType) { _, _ in saveSettings() }
        .onChange(of: distribution) { _, _ in saveSettings() }
    }

    private var directionIndex: Float {
        switch direction {
        case .horizontal: return 0
        case .vertical: return 1
        case .diagonalOne: return 2
        case .diagonalTwo: return 3
        case .diagonalThree: return 4
        case .diagonalFour: return 5
        }
    }
    
    private var vectorColor: SIMD3<Float> {
        let (r, g, b) = targetColor.rgb
        return SIMD3<Float>(Float(r), Float(g), Float(b))
    }

    private func saveSettings() {
        SettingsManager.shared.saveSetting(testId: "ColorGradient", key: "steps", value: steps)
        SettingsManager.shared.saveSetting(testId: "ColorGradient", key: "targetColor", value: targetColor.rawValue)
        SettingsManager.shared.saveSetting(testId: "ColorGradient", key: "direction", value: direction.rawValue)
        SettingsManager.shared.saveSetting(testId: "ColorGradient", key: "gradientType", value: gradientType.rawValue)
        SettingsManager.shared.saveSetting(testId: "ColorGradient", key: "distribution", value: distribution.rawValue)
    }

    private func loadSettings() {
        steps = SettingsManager.shared.getSetting(testId: "ColorGradient", key: "steps", defaultValue: 32)
        
        if let colorRaw = SettingsManager.shared.getSetting(testId: "ColorGradient", key: "targetColor", defaultValue: "White") as String?,
           let color = TargetColor(rawValue: colorRaw) {
            targetColor = color
        }
        
        if let dirRaw = SettingsManager.shared.getSetting(testId: "ColorGradient", key: "direction", defaultValue: "Horizontal") as String?,
           let dir = GradientDirection(rawValue: dirRaw) {
            direction = dir
        }

        if let typeRaw = SettingsManager.shared.getSetting(testId: "ColorGradient", key: "gradientType", defaultValue: "Linear") as String?,
           let type = GradientType(rawValue: typeRaw) {
            gradientType = type
        }

        if let distRaw = SettingsManager.shared.getSetting(testId: "ColorGradient", key: "distribution", defaultValue: "Linear") as String?,
           let dist = Distribution(rawValue: distRaw) {
            distribution = dist
        }
    }
}

#Preview {
    ColorGradientTestView()
}
