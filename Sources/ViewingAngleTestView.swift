import SwiftUI

struct ViewingAngleTestView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var isMinimized = false
    @State private var controlsHidden = false
    
    // Sensitivity: Difference in brightness (0.0 to 0.2)
    // Lower means harder to see (more sensitive to viewing angle shifts)
    @State private var sensitivity: Double = 0.05
    @State private var invert: Bool = false
    
    let colors: [ColorData] = [
        ColorData(name: "Red", color: .red),
        ColorData(name: "Green", color: .green),
        ColorData(name: "Blue", color: .blue),
        ColorData(name: "White", color: .white),
        ColorData(name: "Cyan", color: .cyan),
        ColorData(name: "Magenta", color: Color(red: 1.0, green: 0.0, blue: 1.0)),
        ColorData(name: "Yellow", color: .yellow),
        ColorData(name: "Gray", color: .gray)
    ]

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            GeometryReader { proxy in
                let columns = [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())]
                
                LazyVGrid(columns: columns, spacing: 0) {
                    ForEach(colors) { item in
                        ColorShiftCard(
                            baseColor: item.color,
                            sensitivity: sensitivity,
                            invert: invert,
                            height: proxy.size.height / 2
                        )
                    }
                }
            }
            .ignoresSafeArea()
            
            ControlPanelDock(title: "Viewing Angle", isMinimized: $isMinimized, controlsHidden: controlsHidden) {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Check for color or gamma shifts by viewing the screen from the side.")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                    
                    Text("Ideally, the text visibility should remain consistent from all angles. If text disappears or inverts, the display has viewing angle limitations.")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    SectionHeader(title: "Difference Strength")
                    LabeledSlider(value: $sensitivity, range: 0.01...0.15, step: 0.01, suffix: "")
                    
                    Toggle(isOn: $invert) {
                        Text("Darker Text")
                            .font(.callout.weight(.semibold))
                            .foregroundStyle(.white)
                    }
                }
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .testControls(controlsHidden: $controlsHidden, dismiss: dismiss)
    }
}

struct ColorShiftCard: View {
    let baseColor: Color
    let sensitivity: Double
    let invert: Bool
    let height: CGFloat
    
    var body: some View {
        ZStack {
            baseColor
            
            // The "Test" text or shape that is slightly different
            VStack(spacing: 8) {
                Text("VIEW")
                    .font(.system(size: 80, weight: .bold, design: .rounded))
                Image(systemName: "eye.fill")
                    .font(.system(size: 60))
            }
            // Apply the shift
            // If invert is true, we darken the text. If false, we lighten (or create opacity difference).
            // Using brightness is the most reliable way to create gamma shift targets.
            .foregroundStyle(baseColor)
            .brightness(invert ? -sensitivity : sensitivity)
        }
        .frame(height: height)
    }
}

struct ColorData: Identifiable {
    let id = UUID()
    let name: String
    let color: Color
}

#Preview {
    ViewingAngleTestView()
}