import SwiftUI

struct UniformityTestView: View {
    enum PatternType: String, CaseIterable, Identifiable {
        case solid = "Solid"
        case checkerboard = "Checkerboard"

        var id: String { rawValue }
    }

    enum BaseColor: String, CaseIterable, Identifiable {
        case white = "White"
        case red = "Red"
        case green = "Green"
        case blue = "Blue"

        var id: String { rawValue }

        func color(brightness: Double) -> Color {
            let value = brightness / 100
            switch self {
            case .white:
                return Color(red: value, green: value, blue: value)
            case .red:
                return Color(red: value, green: 0, blue: 0)
            case .green:
                return Color(red: 0, green: value, blue: 0)
            case .blue:
                return Color(red: 0, green: 0, blue: value)
            }
        }
    }

    @Environment(\.dismiss) private var dismiss
    @State private var isMinimized = false
    @State private var brightness: Double = 50
    @State private var patternType: PatternType = .solid
    @State private var selectedColor: BaseColor = .white
    @State private var showGridLines = false
    @State private var gridSize: Double = 3
    @State private var showCrosshair = false
    @State private var checkerboardSize: Double = 60
    @State private var controlsHidden = false

    var body: some View {
        GeometryReader { proxy in
            let baseColor = selectedColor.color(brightness: brightness)

            ZStack {
                baseColor.ignoresSafeArea()

                if patternType == .checkerboard {
                    CheckerboardView(
                        color1: baseColor,
                        color2: baseColor.opacity(0.6),
                        squareSize: checkerboardSize
                    )
                }

                if showGridLines {
                    GridOverlay(rows: Int(gridSize), columns: Int(gridSize))
                        .stroke(Color.white.opacity(0.4), lineWidth: 1)
                }

                if showCrosshair {
                    CrosshairView()
                }

                ControlPanelDock(title: "Uniformity", isMinimized: $isMinimized, controlsHidden: controlsHidden) {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Check backlight uniformity and color consistency across the panel.")
                            .font(.callout)
                            .foregroundStyle(.secondary)

                        SectionHeader(title: "Base Color")
                        HStack(spacing: 10) {
                            ForEach(BaseColor.allCases) { option in
                                ToggleChip(title: option.rawValue, isSelected: selectedColor == option) {
                                    selectedColor = option
                                }
                            }
                        }

                        SectionHeader(title: "Brightness")
                        LabeledSlider(value: $brightness, range: 10...100, step: 5, suffix: "%")

                        SectionHeader(title: "Pattern Type")
                        HStack(spacing: 10) {
                            ForEach(PatternType.allCases) { pattern in
                                ToggleChip(title: pattern.rawValue, isSelected: patternType == pattern) {
                                    patternType = pattern
                                }
                            }
                        }

                        if patternType == .checkerboard {
                            SectionHeader(title: "Checker Size")
                            LabeledSlider(value: $checkerboardSize, range: 20...160, step: 10, suffix: "px")
                        }

                        SectionHeader(title: "Grid Overlay")
                        ToggleRow(title: "Show grid lines", isOn: showGridLines) {
                            showGridLines.toggle()
                        }

                        if showGridLines {
                            LabeledSlider(value: $gridSize, range: 2...8, step: 1, suffix: "x")
                        }

                        SectionHeader(title: "Crosshair")
                        ToggleRow(title: "Show center crosshair", isOn: showCrosshair) {
                            showCrosshair.toggle()
                        }

                        Button {
                            brightness = 50
                            patternType = .solid
                            selectedColor = .white
                            showGridLines = false
                            gridSize = 3
                            showCrosshair = false
                            checkerboardSize = 60
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

struct CheckerboardView: View {
    let color1: Color
    let color2: Color
    let squareSize: Double

    var body: some View {
        Canvas { context, size in
            let square = CGFloat(squareSize)
            let columns = Int(ceil(size.width / square))
            let rows = Int(ceil(size.height / square))

            for row in 0..<rows {
                for column in 0..<columns {
                    let rect = CGRect(
                        x: CGFloat(column) * square,
                        y: CGFloat(row) * square,
                        width: square,
                        height: square
                    )
                    let isEven = (row + column).isMultiple(of: 2)
                    context.fill(Path(rect), with: .color(isEven ? color1 : color2))
                }
            }
        }
        .ignoresSafeArea()
    }
}

struct GridOverlay: Shape {
    let rows: Int
    let columns: Int

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let rowCount = max(rows, 1)
        let columnCount = max(columns, 1)
        let rowHeight = rect.height / CGFloat(rowCount)
        let columnWidth = rect.width / CGFloat(columnCount)

        for row in 1..<rowCount {
            let y = CGFloat(row) * rowHeight
            path.move(to: CGPoint(x: rect.minX, y: y))
            path.addLine(to: CGPoint(x: rect.maxX, y: y))
        }

        for column in 1..<columnCount {
            let x = CGFloat(column) * columnWidth
            path.move(to: CGPoint(x: x, y: rect.minY))
            path.addLine(to: CGPoint(x: x, y: rect.maxY))
        }

        return path
    }
}

struct CrosshairView: View {
    var body: some View {
        ZStack {
            Rectangle()
                .fill(Color.yellow)
                .frame(width: 4, height: 60)
                .overlay(Rectangle().stroke(Color.black, lineWidth: 1))
            Rectangle()
                .fill(Color.yellow)
                .frame(width: 60, height: 4)
                .overlay(Rectangle().stroke(Color.black, lineWidth: 1))
        }
        .shadow(color: Color.black.opacity(0.6), radius: 6)
    }
}

#Preview {
    UniformityTestView()
}
