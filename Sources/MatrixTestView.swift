import SwiftUI

struct MatrixTestView: View {
    enum Palette: String, CaseIterable, Identifiable {
        case matrixGreen = "Matrix Green"
        case cyan = "Cyan"
        case magenta = "Magenta"
        case yellow = "Yellow"
        case white = "White"
        case red = "Red"

        var id: String { rawValue }

        var color: SIMD3<Float> {
            switch self {
            case .matrixGreen: return SIMD3<Float>(0.0, 1.0, 0.0)
            case .cyan: return SIMD3<Float>(0.0, 1.0, 1.0)
            case .magenta: return SIMD3<Float>(1.0, 0.0, 1.0)
            case .yellow: return SIMD3<Float>(1.0, 1.0, 0.0)
            case .white: return SIMD3<Float>(1.0, 1.0, 1.0)
            case .red: return SIMD3<Float>(1.0, 0.0, 0.0)
            }
        }

        var swatchColor: Color {
            Color(red: Double(color.x), green: Double(color.y), blue: Double(color.z))
        }
    }

    enum Background: String, CaseIterable, Identifiable {
        case black = "Black"
        case darkGray = "Dark Gray"
        case navy = "Navy"
        case darkBlue = "Dark Blue"

        var id: String { rawValue }

        var color: SIMD3<Float> {
            switch self {
            case .black: return SIMD3<Float>(0.0, 0.0, 0.0)
            case .darkGray: return SIMD3<Float>(0.13, 0.13, 0.13)
            case .navy: return SIMD3<Float>(0.0, 0.0, 0.2)
            case .darkBlue: return SIMD3<Float>(0.0, 0.0, 0.4)
            }
        }

        var swatchColor: Color {
            Color(red: Double(color.x), green: Double(color.y), blue: Double(color.z))
        }
    }

    @Environment(\.dismiss) private var dismiss
    @State private var isMinimized = false
    @State private var textColor: Palette = .matrixGreen
    @State private var backgroundColor: Background = .black
    @State private var fontSize: Double = 30
    @State private var speed: Double = 50
    @State private var controlsHidden = false
    
    // Shader start time
    @State private var startDate = Date()

    var body: some View {
        TimelineView(.animation) { timeline in
            GeometryReader { proxy in
                Rectangle()
                    .fill(.black)
                    .colorEffect(ShaderLibrary.matrix_rain(
                        .float2(proxy.size),
                        .float(Float(timeline.date.timeIntervalSince(startDate))),
                        .float3(Float(textColor.color.x), Float(textColor.color.y), Float(textColor.color.z)),
                        .float3(Float(backgroundColor.color.x), Float(backgroundColor.color.y), Float(backgroundColor.color.z)),
                        .float(Float(speed) / 20.0),
                        .float(Float(fontSize))
                    ))
            }
            .ignoresSafeArea()
        }
        .toolbar(.hidden, for: .navigationBar)
        .testControls(controlsHidden: $controlsHidden, dismiss: dismiss)
        .onAppear {
            loadSettings()
        }
    }

    private func saveSettings() {
        SettingsManager.shared.saveSetting(testId: "Matrix", key: "textColor", value: textColor.rawValue)
        SettingsManager.shared.saveSetting(testId: "Matrix", key: "backgroundColor", value: backgroundColor.rawValue)
        SettingsManager.shared.saveSetting(testId: "Matrix", key: "fontSize", value: fontSize)
        SettingsManager.shared.saveSetting(testId: "Matrix", key: "speed", value: speed)
    }

    private func loadSettings() {
        if let textRaw = SettingsManager.shared.getSetting(testId: "Matrix", key: "textColor", defaultValue: "Matrix Green") as String?,
           let text = Palette(rawValue: textRaw) {
            textColor = text
        }
        
        if let bgRaw = SettingsManager.shared.getSetting(testId: "Matrix", key: "backgroundColor", defaultValue: "Black") as String?,
           let bg = Background(rawValue: bgRaw) {
            backgroundColor = bg
        }
        
        fontSize = SettingsManager.shared.getSetting(testId: "Matrix", key: "fontSize", defaultValue: 30.0)
        speed = SettingsManager.shared.getSetting(testId: "Matrix", key: "speed", defaultValue: 50.0)
    }
}

#Preview {
    MatrixTestView()
}