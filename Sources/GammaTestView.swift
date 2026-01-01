import SwiftUI

struct GammaTestView: View {
    private let gammaValues: [Double] = [1.8, 2.0, 2.2, 2.4]
    private let brightnessLevels: [Double] = [0, 0.2, 0.4, 0.6, 0.8, 1.0]

    @Environment(\.dismiss) private var dismiss
    @State private var isMinimized = false
    @State private var boxSize: Double = 100
    @State private var background: BackgroundOption = .gray
    @State private var showValues = true
    @State private var controlsHidden = false

    enum BackgroundOption: String, CaseIterable, Identifiable {
        case white = "White"
        case lightGray = "Light Gray"
        case gray = "Gray"
        case darkGray = "Dark Gray"
        case black = "Black"

        var id: String { rawValue }

        var color: Color {
            switch self {
            case .white: return .white
            case .lightGray: return Color(white: 0.88)
            case .gray: return Color(white: 0.5)
            case .darkGray: return Color(white: 0.25)
            case .black: return .black
            }
        }
    }

    var body: some View {
        ZStack {
            background.color
                .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    ForEach(gammaValues, id: \.self) { gamma in
                        GammaRow(
                            gamma: gamma,
                            levels: brightnessLevels,
                            boxSize: CGFloat(boxSize),
                            showValues: showValues
                        )
                    }
                }
                .padding(.horizontal, 60)
                .padding(.vertical, 80)
            }
            .scrollDisabled(true)

            ControlPanelDock(title: "Gamma", isMinimized: $isMinimized, controlsHidden: controlsHidden) {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Find the row where the steps look evenly spaced. That row matches your display gamma.")
                        .font(.callout)
                        .foregroundStyle(.secondary)

                    SectionHeader(title: "Box Size")
                    LabeledSlider(value: $boxSize, range: 50...200, step: 5, suffix: "px")

                    SectionHeader(title: "Background")
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 160), spacing: 10)], spacing: 10) {
                        ForEach(BackgroundOption.allCases) { option in
                            ColorOptionChip(title: option.rawValue, color: option.color, isSelected: background == option) {
                                background = option
                            }
                        }
                    }

                    SectionHeader(title: "Values")
                    HStack(spacing: 10) {
                        ToggleChip(title: "Show", isSelected: showValues) {
                            showValues = true
                        }
                        ToggleChip(title: "Hide", isSelected: !showValues) {
                            showValues = false
                        }
                    }

                    Button {
                        boxSize = 100
                        background = .gray
                        showValues = true
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

struct GammaRow: View {
    let gamma: Double
    let levels: [Double]
    let boxSize: CGFloat
    let showValues: Bool

    var body: some View {
        HStack(spacing: 12) {
            Text(String(format: "γ %.1f", gamma))
                .font(.callout.weight(.semibold))
                .frame(width: 70, alignment: .leading)
                .foregroundStyle(.white.opacity(0.7))

            ForEach(levels, id: \.self) { level in
                let value = Int(round(255 * pow(level, 1 / gamma)))
                VStack(spacing: 4) {
                    Rectangle()
                        .fill(Color(white: Double(value) / 255))
                        .frame(width: boxSize, height: boxSize)
                        .overlay(
                            RoundedRectangle(cornerRadius: 6, style: .continuous)
                                .stroke(Color.white.opacity(0.2), lineWidth: 1)
                        )

                    if showValues {
                        Text("\(Int(level * 100))%")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        Text("RGB \(value)")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }
}

#Preview {
    GammaTestView()
}
