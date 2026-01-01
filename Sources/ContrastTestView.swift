import SwiftUI

struct ContrastTestView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var isMinimized = false
    @State private var gridSize: Double = 8
    @State private var controlsHidden = false

    var body: some View {
        ZStack {
            CheckerboardGrid(size: Int(gridSize))
                .ignoresSafeArea()

            ControlPanelDock(title: "Contrast", isMinimized: $isMinimized, controlsHidden: controlsHidden) {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Adjust the checkerboard density to test contrast at different scales.")
                        .font(.callout)
                        .foregroundStyle(.secondary)

                    SectionHeader(title: "Grid Size")
                    LabeledSlider(value: $gridSize, range: 2...50, step: 1, suffix: "x")

                    Button {
                        gridSize = 8
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

struct CheckerboardGrid: View {
    let size: Int

    var body: some View {
        Canvas { context, canvasSize in
            let rows = max(size, 2)
            let columns = max(size, 2)
            let cellWidth = canvasSize.width / CGFloat(columns)
            let cellHeight = canvasSize.height / CGFloat(rows)

            for row in 0..<rows {
                for column in 0..<columns {
                    let rect = CGRect(
                        x: CGFloat(column) * cellWidth,
                        y: CGFloat(row) * cellHeight,
                        width: cellWidth,
                        height: cellHeight
                    )
                    let isBlack = (row + column).isMultiple(of: 2)
                    context.fill(Path(rect), with: .color(isBlack ? .black : .white))
                }
            }
        }
        .ignoresSafeArea()
    }
}

#Preview {
    ContrastTestView()
}
