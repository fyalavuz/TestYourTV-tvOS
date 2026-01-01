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
    @State private var fontSize: Double = 18
    @State private var lineHeight: Double = 1.5
    @State private var letterSpacing: Double = 0
    @State private var fontOption: FontOption = .monospaced
    @State private var useDarkMode = true
    @State private var showSmoothing = false

    var body: some View {
        GeometryReader { proxy in
            let background = useDarkMode ? Color.black : Color.white
            let foreground = useDarkMode ? Color.white : Color.black
            let sampleText = repeatingText(in: proxy.size)

            ZStack {
                background.ignoresSafeArea()

                ScrollView(.vertical, showsIndicators: false) {
                    Text(sampleText)
                        .font(fontOption.font(size: CGFloat(fontSize)))
                        .foregroundStyle(foreground)
                        .lineSpacing(CGFloat(fontSize * (lineHeight - 1)))
                        .kerning(CGFloat(letterSpacing))
                        .padding(.horizontal, 80)
                        .padding(.vertical, 120)
                }
                .scrollDisabled(true)

                ControlPanelDock(title: "Text Clarity", isMinimized: $isMinimized, controlsHidden: controlsHidden) {
                    VStack(alignment: .leading, spacing: 16) {
                        SectionHeader(title: "Font Family")
                        Picker("Font", selection: $fontOption) {
                            ForEach(FontOption.allCases) { option in
                                Text(option.rawValue).tag(option)
                            }
                        }
                        .pickerStyle(.menu)
                        .glassInput(cornerRadius: 12)

                        SectionHeader(title: "Font Size")
                        LabeledSlider(value: $fontSize, range: 8...72, step: 1, suffix: "pt")

                        SectionHeader(title: "Line Height")
                        LabeledSlider(value: $lineHeight, range: 1.0...2.0, step: 0.1, suffix: "x")

                        SectionHeader(title: "Letter Spacing")
                        LabeledSlider(value: $letterSpacing, range: -2...10, step: 0.5, suffix: "pt")

                        SectionHeader(title: "Color Mode")
                        HStack(spacing: 12) {
                            ToggleChip(title: "Dark", isSelected: useDarkMode) {
                                useDarkMode = true
                            }
                            ToggleChip(title: "Light", isSelected: !useDarkMode) {
                                useDarkMode = false
                            }
                        }

                        SectionHeader(title: "Smoothing Preview")
                        Button {
                            showSmoothing.toggle()
                        } label: {
                            HStack {
                                Text(showSmoothing ? "Hide Comparison" : "Show Comparison")
                                    .font(.callout.weight(.semibold))
                                Spacer()
                                Image(systemName: showSmoothing ? "chevron.up" : "chevron.down")
                            }
                            .foregroundStyle(.white)
                            .padding(.vertical, 10)
                            .padding(.horizontal, 12)
                            .background(Color.white.opacity(0.12))
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        }
                        .buttonStyle(.glassFocus(cornerRadius: 12))

                        if showSmoothing {
                            HStack(spacing: 12) {
                                SmoothingBox(title: "Sharp", text: "Quick brown fox\nABCDEFGHIJKLM\n1234567890", foreground: foreground, background: background, blur: 0)
                                SmoothingBox(title: "Soft", text: "Quick brown fox\nABCDEFGHIJKLM\n1234567890", foreground: foreground, background: background, blur: 0.8)
                            }
                        }

                        Button {
                            fontSize = 18
                            lineHeight = 1.5
                            letterSpacing = 0
                            fontOption = .monospaced
                            useDarkMode = true
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

    private func repeatingText(in size: CGSize) -> String {
        let base = "The quick brown fox jumps over the lazy dog. "
        let line = String(repeating: base, count: 12)
        let linesNeeded = Int(size.height / CGFloat(fontSize * lineHeight)) + 4
        return Array(repeating: line, count: linesNeeded).joined(separator: "\n")
    }
}

struct SmoothingBox: View {
    let title: String
    let text: String
    let foreground: Color
    let background: Color
    let blur: CGFloat

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            Text(text)
                .font(.system(size: 14, design: .monospaced))
                .foregroundStyle(foreground)
                .lineSpacing(3)
                .blur(radius: blur)
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(background.opacity(0.2))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
    }
}

#Preview {
    TextClarityView()
}
