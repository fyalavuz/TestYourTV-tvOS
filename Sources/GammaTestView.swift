import SwiftUI

struct GammaTestView: View {
    private let gammaValues: [Double] = [1.8, 2.0, 2.2, 2.4]
    private let brightnessLevels: [Double] = [0, 0.2, 0.4, 0.6, 0.8, 1.0]

    @State private var boxSize: Double = 100
    @State private var background: BackgroundOption = .gray
    @State private var showValues = true

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
            .overlay {
                VStack {
                    Spacer()
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Gamma")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)

                        // Box Size
                        SectionHeader(title: "Box Size")
                        LabeledSlider(value: $boxSize, range: 50...200, step: 5, suffix: "px")

                        // Background Picker (native)
                        SectionHeader(title: "Background")
                        Picker("Background", selection: $background) {
                            ForEach(BackgroundOption.allCases) { option in
                                Text(option.rawValue).tag(option)
                            }
                        }
                        .pickerStyle(.segmented)

                        // Show Values Toggle (native)
                        Toggle(isOn: $showValues) {
                            Text("Show values")
                                .font(.callout.weight(.semibold))
                                .foregroundStyle(.white)
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
        }
        .toolbar(.hidden, for: .navigationBar)
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
