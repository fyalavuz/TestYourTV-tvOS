import SwiftUI

struct OverscanTestView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var isMinimized = false
    @State private var showGrid = true
    @State private var showSafeAreaGuide = true
    @State private var showOverscanGuide = true
    @State private var controlsHidden = false

    var body: some View {
        GeometryReader { proxy in
            let screen = UIScreen.main
            let bounds = screen.bounds
            let nativeBounds = screen.nativeBounds
            let scale = screen.scale
            let nativeScale = screen.nativeScale
            let overscanInsets = screen.overscanCompensationInsets
            let safeInsets = proxy.safeAreaInsets

            ZStack {
                Color.black.ignoresSafeArea()

                if showGrid {
                    OverscanGrid()
                }

                if showOverscanGuide {
                    InsetGuide(
                        label: "Overscan Insets",
                        color: Color(red: 0.18, green: 0.90, blue: 0.95),
                        insets: overscanInsets
                    )
                }

                if showSafeAreaGuide {
                    InsetGuide(
                        label: "Safe Area",
                        color: .yellow,
                        insets: UIEdgeInsets(
                            top: safeInsets.top,
                            left: safeInsets.leading,
                            bottom: safeInsets.bottom,
                            right: safeInsets.trailing
                        ),
                        labelAlignment: .bottomLeading
                    )
                }

                ControlPanelDock(title: "Overscan", isMinimized: $isMinimized, controlsHidden: controlsHidden, dockSide: .trailing) {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Use these guides to verify if the TV is cropping edges and to read system overscan settings.")
                            .font(.callout)
                            .foregroundStyle(.secondary)

                        SectionHeader(title: "Display Metrics")
                        MetricRow(title: "Bounds (pt)", value: formatSize(bounds.size, suffix: "pt"))
                        MetricRow(title: "Native Bounds (px)", value: formatSize(nativeBounds.size, suffix: "px"))
                        MetricRow(title: "Scale", value: formatScale(scale))
                        MetricRow(title: "Native Scale", value: formatScale(nativeScale))

                        SectionHeader(title: "Overscan")
                        MetricRow(title: "Compensation", value: overscanLabel(screen.overscanCompensation))
                        MetricRow(title: "Insets (pt)", value: formatInsets(overscanInsets))

                        SectionHeader(title: "Safe Area")
                        MetricRow(title: "Insets (pt)", value: formatEdgeInsets(safeInsets))

                        SectionHeader(title: "Guides")
                        Toggle(isOn: $showGrid) {
                            Text("Show grid")
                                .font(.callout.weight(.semibold))
                                .foregroundStyle(.white)
                        }
                        .toggleStyle(GlassCheckboxToggleStyle())

                        Toggle(isOn: $showOverscanGuide) {
                            Text("Show overscan insets")
                                .font(.callout.weight(.semibold))
                                .foregroundStyle(.white)
                        }
                        .toggleStyle(GlassCheckboxToggleStyle())

                        Toggle(isOn: $showSafeAreaGuide) {
                            Text("Show safe area")
                                .font(.callout.weight(.semibold))
                                .foregroundStyle(.white)
                        }
                        .toggleStyle(GlassCheckboxToggleStyle())
                    }
                }
            }
            .toolbar(.hidden, for: .navigationBar)
            .testControls(controlsHidden: $controlsHidden, dismiss: dismiss)
        }
    }

    private func overscanLabel(_ compensation: UIScreen.OverscanCompensation) -> String {
        switch compensation {
        case .none:
            return "None"
        case .scale:
            return "Scale"
        case .insetBounds:
            return "Inset"
        @unknown default:
            return "Unknown"
        }
    }

    private func formatSize(_ size: CGSize, suffix: String) -> String {
        String(format: "%.0f x %.0f %@", size.width, size.height, suffix)
    }

    private func formatScale(_ scale: CGFloat) -> String {
        String(format: "%.2f", scale)
    }

    private func formatInsets(_ insets: UIEdgeInsets) -> String {
        String(format: "T %.0f  L %.0f  B %.0f  R %.0f", insets.top, insets.left, insets.bottom, insets.right)
    }

    private func formatEdgeInsets(_ insets: EdgeInsets) -> String {
        String(format: "T %.0f  L %.0f  B %.0f  R %.0f", insets.top, insets.leading, insets.bottom, insets.trailing)
    }
}

private struct MetricRow: View {
    let title: String
    let value: String

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 10) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)

            Spacer(minLength: 0)

            Text(value)
                .font(.callout.weight(.semibold))
                .foregroundStyle(.white)
        }
    }
}

private struct OverscanGrid: View {
    var body: some View {
        ZStack {
            Canvas { context, size in
            let rect = CGRect(origin: .zero, size: size)
            context.stroke(Path(rect), with: .color(.white.opacity(0.4)), lineWidth: 2)

            let guides: [CGFloat] = [0.01, 0.02, 0.03]
            for inset in guides {
                let xInset = size.width * inset
                let yInset = size.height * inset
                let guideRect = rect.insetBy(dx: xInset, dy: yInset)
                context.stroke(Path(guideRect), with: .color(.white.opacity(0.2)), lineWidth: 1)
            }

            let midX = size.width / 2
            let midY = size.height / 2
            var cross = Path()
            cross.move(to: CGPoint(x: midX, y: 0))
            cross.addLine(to: CGPoint(x: midX, y: size.height))
            cross.move(to: CGPoint(x: 0, y: midY))
            cross.addLine(to: CGPoint(x: size.width, y: midY))
            context.stroke(cross, with: .color(.white.opacity(0.2)), lineWidth: 1)
            }

            CornerMarkers()
        }
        .ignoresSafeArea()
    }
}

private struct CornerMarkers: View {
    var body: some View {
        GeometryReader { proxy in
            let insetX = proxy.size.width * 0.01
            let insetY = proxy.size.height * 0.01

            CornerLabel(text: "1")
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                .padding(.leading, insetX)
                .padding(.top, insetY)

            CornerLabel(text: "2")
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                .padding(.trailing, insetX)
                .padding(.top, insetY)

            CornerLabel(text: "3")
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
                .padding(.trailing, insetX)
                .padding(.bottom, insetY)

            CornerLabel(text: "4")
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
                .padding(.leading, insetX)
                .padding(.bottom, insetY)
        }
        .allowsHitTesting(false)
    }
}

private struct CornerLabel: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.caption.weight(.bold))
            .foregroundStyle(Color.white.opacity(0.85))
            .shadow(color: .black.opacity(0.45), radius: 2, y: 1)
    }
}

private struct InsetGuide: View {
    let label: String
    let color: Color
    let insets: UIEdgeInsets
    let labelAlignment: Alignment

    init(label: String, color: Color, insets: UIEdgeInsets, labelAlignment: Alignment = .topLeading) {
        self.label = label
        self.color = color
        self.insets = insets
        self.labelAlignment = labelAlignment
    }

    var body: some View {
        GeometryReader { proxy in
            let rect = CGRect(
                x: insets.left,
                y: insets.top,
                width: max(0, proxy.size.width - insets.left - insets.right),
                height: max(0, proxy.size.height - insets.top - insets.bottom)
            )

            ZStack {
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .stroke(color, style: StrokeStyle(lineWidth: 2, dash: [8, 6]))
                    .frame(width: rect.width, height: rect.height)
                    .position(x: rect.midX, y: rect.midY)

                if rect.width > 0 && rect.height > 0 {
                    Color.clear
                        .frame(width: rect.width, height: rect.height)
                        .position(x: rect.midX, y: rect.midY)
                        .overlay(alignment: labelAlignment) {
                            Text(label)
                                .font(.caption2.weight(.semibold))
                                .foregroundStyle(.black)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(color.opacity(0.9))
                                .clipShape(Capsule())
                                .padding(12)
                        }
                }
            }
        }
        .ignoresSafeArea()
    }
}

#Preview {
    OverscanTestView()
}
