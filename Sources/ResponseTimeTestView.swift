import SwiftUI

struct ResponseTimeTestView: View {
    enum TestType: String, CaseIterable, Identifiable {
        case movingBlock = "Block"
        case pursuitBar = "Moving Bar" // Renamed from Pursuit Text
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
        case cyan = "Cyan"
        var id: String { rawValue }

        var color: Color {
            switch self {
            case .black: return .black
            case .white: return .white
            case .cyan: return .cyan
            }
        }
    }

    enum BackgroundColor: String, CaseIterable, Identifiable {
        case gray = "Gray"
        case darkGray = "Dark"
        case black = "Black"
        case white = "White"

        var id: String { rawValue }

        var color: Color {
            switch self {
            case .gray: return Color(white: 0.5)
            case .darkGray: return Color(white: 0.25)
            case .black: return .black
            case .white: return .white
            }
        }
    }

    @Environment(\.dismiss) private var dismiss
    @State private var isMinimized = false
    @State private var testType: TestType = .pursuitBar // Default to the better test
    @State private var speed: Double = 960 // Faster default for modern TVs
    @State private var blockSize: Double = 100
    @State private var backgroundColor: BackgroundColor = .gray
    @State private var objectColor: MotionColor = .cyan
    @State private var direction: Direction = .horizontal
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
                        MovingBlock(
                            time: time,
                            size: CGFloat(blockSize),
                            speed: speed,
                            direction: direction,
                            objectColor: objectColor,
                            width: width,
                            height: height
                        )
                    } else {
                        MovingBarPattern(
                            time: time,
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
                        Text("Track the moving object. Look for trailing shadows (ghosting) or color fringes.")
                            .font(.callout)
                            .foregroundStyle(.secondary)

                        SectionHeader(title: "Test Pattern")
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

                        SectionHeader(title: "Speed (PPS)")
                        LabeledSlider(value: $speed, range: 100...2000, step: 100, suffix: "px/s")

                        SectionHeader(title: "Object Color")
                        HStack(spacing: 10) {
                            ForEach(MotionColor.allCases) { option in
                                ColorOptionChip(title: option.rawValue, color: option.color, isSelected: objectColor == option) {
                                    objectColor = option
                                }
                            }
                        }

                        SectionHeader(title: "Background")
                        HStack(spacing: 10) {
                            ForEach(BackgroundColor.allCases) { option in
                                ColorOptionChip(title: option.rawValue, color: option.color, isSelected: backgroundColor == option) {
                                    backgroundColor = option
                                }
                            }
                        }

                        Button {
                            testType = .pursuitBar
                            speed = 960
                            blockSize = 100
                            backgroundColor = .gray
                            objectColor = .cyan
                            direction = .horizontal
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
    let size: CGFloat
    let speed: Double
    let direction: ResponseTimeTestView.Direction
    let objectColor: ResponseTimeTestView.MotionColor
    let width: CGFloat
    let height: CGFloat

    var body: some View {
        let travelDimension = direction == .horizontal ? width : height
        let span = travelDimension + size
        let offset = CGFloat((time * speed).truncatingRemainder(dividingBy: span)) - size / 2

        RoundedRectangle(cornerRadius: 12, style: .continuous)
            .fill(objectColor.color)
            .frame(width: size, height: size)
            .position(
                x: direction == .horizontal ? offset : width / 2,
                y: direction == .horizontal ? height / 2 : offset
            )
            .shadow(color: objectColor.color.opacity(0.3), radius: 10)
    }
}

struct MovingBarPattern: View {
    let time: TimeInterval
    let size: CGFloat
    let speed: Double
    let direction: ResponseTimeTestView.Direction
    let objectColor: ResponseTimeTestView.MotionColor
    let width: CGFloat
    let height: CGFloat

    var body: some View {
        let travelDimension = direction == .horizontal ? width : height
        let barWidth = size * 0.2 // Thin vertical bar
        let span = travelDimension + barWidth * 2
        let offset = CGFloat((time * speed).truncatingRemainder(dividingBy: span)) - barWidth

        // Draw a group of 3 bars for ghosting check
        // Central one is objectColor, side ones are dimmed
        ZStack {
            ForEach(-1...1, id: \.self) { i in
                Rectangle()
                    .fill(i == 0 ? objectColor.color : objectColor.color.opacity(0.3))
                    .frame(
                        width: direction == .horizontal ? barWidth : size * 2,
                        height: direction == .horizontal ? size * 2 : barWidth
                    )
                    .offset(
                        x: direction == .horizontal ? CGFloat(i) * barWidth * 2 : 0,
                        y: direction == .horizontal ? 0 : CGFloat(i) * barWidth * 2
                    )
            }
        }
        .position(
            x: direction == .horizontal ? offset : width / 2,
            y: direction == .horizontal ? height / 2 : offset
        )
    }
}

#Preview {
    ResponseTimeTestView()
}