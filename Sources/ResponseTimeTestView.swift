import SwiftUI

struct ResponseTimeTestView: View {
    enum TestType: String, CaseIterable, Identifiable {
        case movingBlock = "Display"
        case pursuitText = "Pursuit Text"
        var id: String { rawValue }
    }

    enum Direction: String, CaseIterable, Identifiable {
        case horizontal = "Horizontal"
        case vertical = "Vertical"
        var id: String { rawValue }
    }

    enum MotionColor: String, CaseIterable, Identifiable {
        case black = "Dark"
        case white = "Light"
        var id: String { rawValue }

        var color: Color { self == .black ? .black : .white }
    }

    enum BackgroundColor: String, CaseIterable, Identifiable {
        case white = "White"
        case lightGray = "Light Gray"
        case gray = "Gray"
        case darkGray = "Dark Gray"
        case black = "Black"
        case navy = "Navy"
        case royalBlue = "Royal Blue"
        case teal = "Teal"
        case forestGreen = "Forest Green"
        case burgundy = "Burgundy"

        var id: String { rawValue }

        var color: Color {
            switch self {
            case .white: return .white
            case .lightGray: return Color(white: 0.88)
            case .gray: return Color(white: 0.5)
            case .darkGray: return Color(white: 0.25)
            case .black: return .black
            case .navy: return Color(red: 0.0, green: 0.0, blue: 0.5)
            case .royalBlue: return Color(red: 0.25, green: 0.41, blue: 0.88)
            case .teal: return Color(red: 0.0, green: 0.5, blue: 0.5)
            case .forestGreen: return Color(red: 0.13, green: 0.55, blue: 0.13)
            case .burgundy: return Color(red: 0.5, green: 0.0, blue: 0.13)
            }
        }
    }

    @Environment(\.dismiss) private var dismiss
    @State private var isMinimized = false
    @State private var testType: TestType = .movingBlock
    @State private var speed: Double = 35
    @State private var blockSize: Double = 100
    @State private var backgroundColor: BackgroundColor = .gray
    @State private var objectColor: MotionColor = .black
    @State private var direction: Direction = .horizontal
    @State private var objectCount: Int = 1
    @State private var controlsHidden = false

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                backgroundColor.color
                    .ignoresSafeArea()

                TimelineView(.animation) { timeline in
                    let time = timeline.date.timeIntervalSinceReferenceDate
                    let width = proxy.size.width
                    let height = proxy.size.height

                    if testType == .movingBlock {
                        ForEach(0..<objectCount, id: \.self) { index in
                            MovingBlock(
                                time: time,
                                index: index,
                                count: objectCount,
                                size: CGFloat(blockSize),
                                speed: speed,
                                direction: direction,
                                objectColor: objectColor,
                                width: width,
                                height: height
                            )
                        }
                    } else {
                        PursuitText(
                            time: time,
                            count: objectCount,
                            size: CGFloat(blockSize),
                            speed: speed,
                            direction: direction,
                            objectColor: objectColor,
                            width: width,
                            height: height
                        )
                    }
                }

                ControlPanelDock(title: "Response Time", isMinimized: $isMinimized, controlsHidden: controlsHidden) {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Follow the moving object to detect blur and ghosting.")
                            .font(.callout)
                            .foregroundStyle(.secondary)

                        SectionHeader(title: "Test Type")
                        HStack(spacing: 10) {
                            ForEach(TestType.allCases) { option in
                                ToggleChip(title: option.rawValue, isSelected: testType == option) {
                                    testType = option
                                }
                            }
                        }

                        SectionHeader(title: "Direction")
                        HStack(spacing: 10) {
                            ForEach(Direction.allCases) { option in
                                ToggleChip(title: option.rawValue, isSelected: direction == option) {
                                    direction = option
                                }
                            }
                        }

                        SectionHeader(title: "Speed")
                        LabeledSlider(value: $speed, range: 5...200, step: 5, suffix: "px/s")

                        SectionHeader(title: "Size")
                        LabeledSlider(value: $blockSize, range: 50...200, step: 10, suffix: "px")

                        SectionHeader(title: "Object Count")
                        LabeledSlider(value: Binding(
                            get: { Double(objectCount) },
                            set: { objectCount = Int($0) }
                        ), range: 1...5, step: 1, suffix: "")

                        SectionHeader(title: "Object Color")
                        HStack(spacing: 10) {
                            ForEach(MotionColor.allCases) { option in
                                ColorOptionChip(title: option.rawValue, color: option.color, isSelected: objectColor == option) {
                                    objectColor = option
                                }
                            }
                        }

                        SectionHeader(title: "Background")
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 160), spacing: 10)], spacing: 10) {
                            ForEach(BackgroundColor.allCases) { option in
                                ColorOptionChip(title: option.rawValue, color: option.color, isSelected: backgroundColor == option) {
                                    backgroundColor = option
                                }
                            }
                        }

                        Button {
                            testType = .movingBlock
                            speed = 35
                            blockSize = 100
                            backgroundColor = .gray
                            objectColor = .black
                            direction = .horizontal
                            objectCount = 1
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

struct MovingBlock: View {
    let time: TimeInterval
    let index: Int
    let count: Int
    let size: CGFloat
    let speed: Double
    let direction: ResponseTimeTestView.Direction
    let objectColor: ResponseTimeTestView.MotionColor
    let width: CGFloat
    let height: CGFloat

    var body: some View {
        let crossSize = direction == .horizontal ? height : width
        let laneSize = crossSize / CGFloat(max(count, 1))
        let laneCenter = laneSize * (CGFloat(index) + 0.5)
        let travelDimension = direction == .horizontal ? width : height
        let span = travelDimension + size
        let offset = CGFloat((time * speed).truncatingRemainder(dividingBy: span)) - size / 2

        RoundedRectangle(cornerRadius: 12, style: .continuous)
            .fill(objectColor.color)
            .frame(width: size, height: size)
            .position(
                x: direction == .horizontal ? offset : laneCenter,
                y: direction == .horizontal ? laneCenter : offset
            )
            .shadow(color: objectColor.color.opacity(0.2), radius: 8)
    }
}

struct PursuitText: View {
    let time: TimeInterval
    let count: Int
    let size: CGFloat
    let speed: Double
    let direction: ResponseTimeTestView.Direction
    let objectColor: ResponseTimeTestView.MotionColor
    let width: CGFloat
    let height: CGFloat

    var body: some View {
        let textSize = size * 0.5
        let travelDimension = direction == .horizontal ? width : height
        let span = travelDimension + size * 8
        let offset = CGFloat((time * speed).truncatingRemainder(dividingBy: span)) - size * 4

        Group {
            if direction == .horizontal {
                VStack(spacing: size / 2) {
                    ForEach(0..<count, id: \.self) { _ in
                        Text("PURSUIT TEST")
                            .font(.system(size: textSize, weight: .bold, design: .monospaced))
                            .foregroundStyle(objectColor.color)
                    }
                }
                .offset(x: offset)
            } else {
                HStack(spacing: size / 2) {
                    ForEach(0..<count, id: \.self) { _ in
                        Text("PURSUIT TEST")
                            .font(.system(size: textSize, weight: .bold, design: .monospaced))
                            .foregroundStyle(objectColor.color)
                            .rotationEffect(.degrees(90))
                    }
                }
                .offset(y: offset)
            }
        }
    }
}

#Preview {
    ResponseTimeTestView()
}
