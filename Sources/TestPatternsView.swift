import SwiftUI
import UIKit

struct TestPatternsView: View {
    enum PatternKind: String, CaseIterable, Identifiable {
        case testCard
        case checkerboard
        case fineLines
        case grayscaleRamp
        case rgbRamps
        case nearBlack
        case saturationPatches
        case banding
        case dualCircles

        var id: String { rawValue }

        var title: String {
            switch self {
            case .testCard: return "Test Card"
            case .checkerboard: return "1px Checkerboard"
            case .fineLines: return "Fine Lines"
            case .grayscaleRamp: return "Grayscale Ramp"
            case .rgbRamps: return "RGB Ramps"
            case .nearBlack: return "Near Black 0-5%"
            case .saturationPatches: return "Saturation Patches"
            case .banding: return "Gradient Banding"
            case .dualCircles: return "Dual Circles"
            }
        }
    }

    @State private var selectedIndex = 0

    private let patterns = PatternKind.allCases

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            if let current = currentPattern {
                PatternRenderer(kind: current)
                    .ignoresSafeArea()
            }

            VStack {
                Spacer()
                HStack(spacing: 12) {
                    GlassIconButton(symbol: "chevron.left", size: 48) {
                        handleMove(.left)
                    }
                    Text("\(currentPattern?.title ?? "None")  •  \(patternIndexLabel)")
                        .glassHUD()
                    GlassIconButton(symbol: "chevron.right", size: 48) {
                        handleMove(.right)
                    }
                }
                .padding(.bottom, 40)
            }
        }
        .onMoveCommand { direction in
            handleMove(direction)
        }
        .toolbar(.hidden, for: .navigationBar)
    }

    private var currentPattern: PatternKind? {
        guard patterns.indices.contains(selectedIndex) else { return nil }
        return patterns[selectedIndex]
    }

    private var patternIndexLabel: String {
        guard !patterns.isEmpty else { return "0 / 0" }
        return "\(selectedIndex + 1) / \(patterns.count)"
    }

    private func handleMove(_ direction: MoveCommandDirection) {
        guard !patterns.isEmpty else { return }
        switch direction {
        case .left:
            selectedIndex = (selectedIndex - 1 + patterns.count) % patterns.count
        case .right:
            selectedIndex = (selectedIndex + 1) % patterns.count
        default:
            break
        }
    }
}

private struct PatternRenderer: View {
    let kind: TestPatternsView.PatternKind

    var body: some View {
        switch kind {
        case .testCard:
            TestCardPattern()
        case .checkerboard:
            CheckerboardPattern()
        case .fineLines:
            FineLinesPattern()
        case .grayscaleRamp:
            GrayscaleRampPattern()
        case .rgbRamps:
            RGBRampsPattern()
        case .nearBlack:
            NearBlackPattern()
        case .saturationPatches:
            SaturationPatchesPattern()
        case .banding:
            BandingPattern()
        case .dualCircles:
            DualCirclesPattern()
        }
    }
}

private struct CheckerboardPattern: View {
    var body: some View {
        TiledPatternView(image: PatternImages.checkerboard)
    }
}

private struct FineLinesPattern: View {
    var body: some View {
        HStack(spacing: 0) {
            TiledPatternView(image: PatternImages.verticalLines)
            TiledPatternView(image: PatternImages.horizontalLines)
        }
    }
}

private struct GrayscaleRampPattern: View {
    var body: some View {
        GeometryReader { proxy in
            let rampHeight = proxy.size.height * 0.82
            VStack(spacing: 0) {
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [Color.black, Color.white],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(height: rampHeight)

                NearBlackSteps(count: 10)
                    .frame(height: proxy.size.height - rampHeight)
            }
        }
    }
}

private struct RGBRampsPattern: View {
    var body: some View {
        GeometryReader { proxy in
            let stripeHeight = proxy.size.height / 3
            VStack(spacing: 0) {
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [Color.black, Color.red],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(height: stripeHeight)
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [Color.black, Color.green],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(height: stripeHeight)
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [Color.black, Color.blue],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(height: stripeHeight)
            }
        }
    }
}

private struct NearBlackPattern: View {
    var body: some View {
        ZStack(alignment: .bottom) {
            Color.black
            VStack(spacing: 24) {
                Text("Near Black Detail")
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.8))

                NearBlackSteps(count: 12)
                    .frame(height: 120)
                    .padding(.horizontal, 80)

                Spacer(minLength: 0)
            }
            .padding(.top, 80)
        }
    }
}

private struct SaturationPatchesPattern: View {
    private let rows: [[Color]] = [
        [Color.red, Color.green, Color.blue, Color.cyan, Color(red: 1, green: 0, blue: 1), Color.yellow],
        [Color(red: 0.75, green: 0.25, blue: 0.25), Color(red: 0.25, green: 0.75, blue: 0.25), Color(red: 0.25, green: 0.25, blue: 0.75), Color(red: 0.25, green: 0.75, blue: 0.75), Color(red: 0.75, green: 0.25, blue: 0.75), Color(red: 0.75, green: 0.75, blue: 0.25)],
        [Color(red: 0.5, green: 0.25, blue: 0.25), Color(red: 0.25, green: 0.5, blue: 0.25), Color(red: 0.25, green: 0.25, blue: 0.5), Color(red: 0.25, green: 0.5, blue: 0.5), Color(red: 0.5, green: 0.25, blue: 0.5), Color(red: 0.5, green: 0.5, blue: 0.25)]
    ]

    var body: some View {
        GeometryReader { proxy in
            VStack(spacing: 0) {
                ForEach(rows.indices, id: \.self) { rowIndex in
                    HStack(spacing: 0) {
                        ForEach(rows[rowIndex].indices, id: \.self) { colIndex in
                            rows[rowIndex][colIndex]
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                        }
                    }
                    .frame(height: proxy.size.height / CGFloat(rows.count))
                }
            }
        }
    }
}

private struct BandingPattern: View {
    var body: some View {
        Canvas { context, size in
            let steps = 64
            let stripeWidth = size.width / CGFloat(steps)
            for index in 0..<steps {
                let value = Double(index) / Double(max(steps - 1, 1))
                let rect = CGRect(x: CGFloat(index) * stripeWidth, y: 0, width: stripeWidth + 1, height: size.height)
                context.fill(Path(rect), with: .color(Color(white: value)))
            }
        }
    }
}

private struct DualCirclesPattern: View {
    var body: some View {
        GeometryReader { proxy in
            let circleSize = min(proxy.size.width * 0.25, proxy.size.height * 0.5)
            HStack(spacing: proxy.size.width * 0.08) {
                Circle()
                    .stroke(Color.white, lineWidth: pixel)
                    .background(Circle().fill(Color.black))
                    .frame(width: circleSize, height: circleSize)
                Circle()
                    .stroke(Color.white, lineWidth: pixel)
                    .background(Circle().fill(Color.black))
                    .frame(width: circleSize, height: circleSize)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .background(Color.black)
    }
}

private struct TestCardPattern: View {
    private let bars: [Color] = [.yellow, .cyan, .green, Color(red: 1, green: 0, blue: 1), .red, .blue]
    private let grayscale: [Color] = [
        Color.black,
        Color(white: 0.2),
        Color(white: 0.4),
        Color(white: 0.6),
        Color(white: 0.8),
        Color.white
    ]

    var body: some View {
        GeometryReader { proxy in
            let size = proxy.size
            let barHeight = size.height * 0.08
            let grayHeight = size.height * 0.06
            let cardWidth = size.width * 0.7
            let cardHeight = size.height * 0.7

            ZStack {
                TiledPatternView(image: PatternImages.grid)

                Rectangle()
                    .stroke(Color.white.opacity(0.4), lineWidth: pixel)
                    .frame(width: size.width * 0.94, height: size.height * 0.94)

                VStack(spacing: size.height * 0.04) {
                    HStack(spacing: 0) {
                        ForEach(bars.indices, id: \.self) { index in
                            bars[index]
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                        }
                    }
                    .frame(width: cardWidth, height: barHeight)

                    ZStack {
                        Circle()
                            .stroke(Color.white, lineWidth: pixel)
                            .frame(width: min(cardWidth, cardHeight) * 0.55, height: min(cardWidth, cardHeight) * 0.55)

                        Rectangle()
                            .fill(Color.white.opacity(0.4))
                            .frame(width: pixel, height: cardHeight * 0.45)
                        Rectangle()
                            .fill(Color.white.opacity(0.4))
                            .frame(width: cardWidth * 0.45, height: pixel)

                        TiledPatternView(image: PatternImages.verticalLines)
                            .frame(width: cardWidth * 0.35, height: cardHeight * 0.12)
                            .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
                            .offset(y: cardHeight * 0.18)
                    }

                    HStack(spacing: 0) {
                        ForEach(grayscale.indices, id: \.self) { index in
                            grayscale[index]
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                        }
                    }
                    .frame(width: cardWidth, height: grayHeight)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)

                CornerTarget(position: CGPoint(x: size.width * 0.08, y: size.height * 0.12))
                CornerTarget(position: CGPoint(x: size.width * 0.92, y: size.height * 0.12))
                CornerTarget(position: CGPoint(x: size.width * 0.08, y: size.height * 0.88))
                CornerTarget(position: CGPoint(x: size.width * 0.92, y: size.height * 0.88))
            }
        }
    }
}

private struct CornerTarget: View {
    let position: CGPoint

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.white.opacity(0.7), lineWidth: pixel)
                .frame(width: 40, height: 40)
            Circle()
                .stroke(Color.white.opacity(0.7), lineWidth: pixel)
                .frame(width: 18, height: 18)
            Rectangle()
                .fill(Color.white.opacity(0.6))
                .frame(width: pixel, height: 50)
            Rectangle()
                .fill(Color.white.opacity(0.6))
                .frame(width: 50, height: pixel)
        }
        .position(position)
    }
}

private struct NearBlackSteps: View {
    let count: Int

    var body: some View {
        GeometryReader { proxy in
            HStack(spacing: 0) {
                ForEach(0..<count, id: \.self) { index in
                    let value = Double(index) / Double(max(count - 1, 1))
                    Color(white: value * 0.08)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(Color.white.opacity(0.2), lineWidth: pixel)
            )
        }
    }
}

private struct TiledPatternView: View {
    let image: UIImage

    var body: some View {
        GeometryReader { proxy in
            Image(uiImage: image)
                .resizable(resizingMode: .tile)
                .interpolation(.none)
                .frame(width: proxy.size.width, height: proxy.size.height)
                .clipped()
        }
    }
}

private enum PatternImages {
    private static let scale = UIScreen.main.nativeScale

    static let checkerboard = makePatternImage(size: CGSize(width: 2, height: 2), scale: scale) { context in
        context.setFillColor(UIColor.black.cgColor)
        context.fill(CGRect(x: 0, y: 0, width: 1, height: 1))
        context.fill(CGRect(x: 1, y: 1, width: 1, height: 1))
        context.setFillColor(UIColor.white.cgColor)
        context.fill(CGRect(x: 1, y: 0, width: 1, height: 1))
        context.fill(CGRect(x: 0, y: 1, width: 1, height: 1))
    }

    static let verticalLines = makePatternImage(size: CGSize(width: 2, height: 2), scale: scale) { context in
        context.setFillColor(UIColor.black.cgColor)
        context.fill(CGRect(x: 0, y: 0, width: 1, height: 2))
        context.setFillColor(UIColor.white.cgColor)
        context.fill(CGRect(x: 1, y: 0, width: 1, height: 2))
    }

    static let horizontalLines = makePatternImage(size: CGSize(width: 2, height: 2), scale: scale) { context in
        context.setFillColor(UIColor.black.cgColor)
        context.fill(CGRect(x: 0, y: 0, width: 2, height: 1))
        context.setFillColor(UIColor.white.cgColor)
        context.fill(CGRect(x: 0, y: 1, width: 2, height: 1))
    }

    static let grid = makePatternImage(size: CGSize(width: 10, height: 10), scale: scale) { context in
        context.setFillColor(UIColor(white: 0.5, alpha: 1).cgColor)
        context.fill(CGRect(x: 0, y: 0, width: 10, height: 10))
        context.setStrokeColor(UIColor(white: 0.15, alpha: 1).cgColor)
        context.setLineWidth(1)
        context.stroke(CGRect(x: 0.5, y: 0.5, width: 9, height: 9))
    }

    private static func makePatternImage(size: CGSize, scale: CGFloat, draw: (CGContext) -> Void) -> UIImage {
        let width = max(Int(size.width.rounded(.up)), 1)
        let height = max(Int(size.height.rounded(.up)), 1)
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bytesPerRow = width * 4

        guard let context = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: bytesPerRow,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else {
            return UIImage()
        }

        context.setAllowsAntialiasing(false)
        context.interpolationQuality = .none
        draw(context)

        guard let image = context.makeImage() else {
            return UIImage()
        }
        return UIImage(cgImage: image, scale: scale, orientation: .up)
    }
}

private var pixel: CGFloat {
    1.0 / UIScreen.main.nativeScale
}

#Preview {
    TestPatternsView()
}
