import SwiftUI

struct TextClarityView: View {
    enum FontOption: String, CaseIterable, Identifiable {
        case monospaced = "Monospaced"
        case rounded = "Rounded"
        case serif = "Serif"
        case plain = "Plain"

        var id: String { rawValue }

        func font(size: CGFloat) -> Font {
            switch self {
            case .monospaced:
                return .system(size: size, weight: .regular, design: .monospaced)
            case .rounded:
                return .system(size: size, weight: .regular, design: .rounded)
            case .serif:
                return .system(size: size, weight: .regular, design: .serif)
            case .plain:
                return .system(size: size, weight: .regular, design: .default)
            }
        }
    }

    @Environment(\.dismiss) private var dismiss
    @State private var isMinimized = false
    @State private var controlsHidden = false
    @State private var fontSize: Double = 24
    @State private var lineHeight: Double = 1.5
    @State private var letterSpacing: Double = 0
    @State private var fontOption: FontOption = .monospaced
    @State private var useDarkMode = true
    @State private var showComparison = false

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                if showComparison {
                    HStack(spacing: 0) {
                        // Left: Current Settings
                        TextPatternView(
                            size: proxy.size,
                            fontSize: fontSize,
                            lineHeight: lineHeight,
                            letterSpacing: letterSpacing,
                            fontOption: fontOption,
                            foreground: useDarkMode ? .white : .black,
                            background: useDarkMode ? .black : .white
                        )
                        .frame(width: proxy.size.width / 2)
                        .clipped()
                        
                        // Right: Chroma Stress (Red on Blue)
                        // This combination is hardest for TVs to render clearly (4:2:0 compression artifacting)
                        TextPatternView(
                            size: proxy.size,
                            fontSize: fontSize,
                            lineHeight: lineHeight,
                            letterSpacing: letterSpacing,
                            fontOption: fontOption,
                            foreground: .red,
                            background: .blue
                        )
                        .frame(width: proxy.size.width / 2)
                        .clipped()
                    }
                    
                    // Divider
                    Rectangle()
                        .fill(Color.white)
                        .frame(width: 2, height: proxy.size.height)
                } else {
                    // Full Screen Current Settings
                    TextPatternView(
                        size: proxy.size,
                        fontSize: fontSize,
                        lineHeight: lineHeight,
                        letterSpacing: letterSpacing,
                        fontOption: fontOption,
                        foreground: useDarkMode ? .white : .black,
                        background: useDarkMode ? .black : .white
                    )
                }

                ControlPanelDock(title: "Text Clarity", isMinimized: $isMinimized, controlsHidden: controlsHidden) {
                    VStack(alignment: .leading, spacing: 16) {
                        SectionHeader(title: "Comparison Mode")
                        ToggleRow(title: "Split Screen (Chroma Check)", isOn: showComparison) {
                            showComparison.toggle()
                        }
                        
                        if showComparison {
                            Text("Left: Standard | Right: Red on Blue (Tests 4:4:4 capability)")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }

                        SectionHeader(title: "Font Family")
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(FontOption.allCases) {
                                    option in
                                    Button {
                                        fontOption = option
                                    } label: {
                                        Text(option.rawValue)
                                            .font(.callout.weight(.semibold))
                                            .foregroundStyle(fontOption == option ? .black : .white)
                                            .padding(.vertical, 10)
                                            .padding(.horizontal, 14)
                                            .background(
                                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                                    .fill(fontOption == option ? Color.white : Color.white.opacity(0.12))
                                            )
                                    }
                                    .buttonStyle(.glassFocus(cornerRadius: 14))
                                }
                            }
                            .padding(.vertical, 4)
                        }

                        SectionHeader(title: "Font Size")
                        LabeledSlider(value: $fontSize, range: 8...72, step: 1, suffix: "pt")

                        SectionHeader(title: "Line Height")
                        LabeledSlider(value: $lineHeight, range: 1.0...2.0, step: 0.1, suffix: "x")

                        SectionHeader(title: "Letter Spacing")
                        LabeledSlider(value: $letterSpacing, range: -2...10, step: 0.5, suffix: "pt")

                        SectionHeader(title: "Color Mode")
                        Picker("Color Mode", selection: $useDarkMode) {
                            Text("Dark").tag(true)
                            Text("Light").tag(false)
                        }
                        .pickerStyle(.segmented)

                        Button {
                            fontSize = 24
                            lineHeight = 1.5
                            letterSpacing = 0
                            fontOption = .monospaced
                            useDarkMode = true
                            showComparison = false
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
}

struct TextPatternView: View {
    let size: CGSize
    let fontSize: Double
    let lineHeight: Double
    let letterSpacing: Double
    let fontOption: TextClarityView.FontOption
    let foreground: Color
    let background: Color
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            background.ignoresSafeArea()
            
            Text(repeatingText(in: size))
                .font(fontOption.font(size: CGFloat(fontSize)))
                .foregroundStyle(foreground)
                .lineSpacing(CGFloat(fontSize * (lineHeight - 1)))
                .kerning(CGFloat(letterSpacing))
                .multilineTextAlignment(.leading)
                .padding(40)
        }
    }
    
    private func repeatingText(in size: CGSize) -> String {
        // High density text pattern
        let base = "The quick brown fox jumps over the lazy dog. 0123456789. !@#$%^&*()_+ "
        let line = String(repeating: base, count: 2)
        // Estimate lines
        let estimatedLineHeight = fontSize * lineHeight
        let linesNeeded = Int(size.height / estimatedLineHeight) + 2
        return Array(repeating: line, count: linesNeeded).joined(separator: "\n")
    }
}

#Preview {
    TextClarityView()
}