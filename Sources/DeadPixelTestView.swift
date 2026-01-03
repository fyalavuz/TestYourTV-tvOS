import SwiftUI

struct DeadPixelTestView: View {
    struct ColorOption: Identifiable {
        let id = UUID()
        let name: String
        let color: Color
    }

    private let colors: [ColorOption] = [
        ColorOption(name: "White", color: .white),
        ColorOption(name: "Black", color: .black),
        ColorOption(name: "Red", color: .red),
        ColorOption(name: "Green", color: .green),
        ColorOption(name: "Blue", color: .blue),
        ColorOption(name: "Yellow", color: .yellow),
        ColorOption(name: "Magenta", color: Color(red: 1, green: 0, blue: 1)),
        ColorOption(name: "Cyan", color: Color(red: 0, green: 1, blue: 1)),
        ColorOption(name: "Gray", color: Color(white: 0.5))
    ]

    @Environment(\.dismiss) private var dismiss
    @State private var selectedIndex = 8
    @State private var isMinimized = false
    @State private var autoCycle = false
    @State private var controlsHidden = false

    private let timer = Timer.publish(every: 2.0, on: .main, in: .common).autoconnect()

    var body: some View {
        let selected = colors[selectedIndex]

        ZStack {
            selected.color
                .ignoresSafeArea()

            ControlPanelDock(title: "Dead Pixel", isMinimized: $isMinimized, controlsHidden: controlsHidden) {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Cycle through colors to identify stuck or dead pixels.")
                        .font(.callout)
                        .foregroundStyle(.secondary)

                    SectionHeader(title: "Background Color")
                    // Updated to single-row ScrollView
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(colors.indices, id: \.self) { index in
                                ColorSwatch(color: colors[index].color, isSelected: selectedIndex == index) {
                                    selectedIndex = index
                                    autoCycle = false
                                }
                            }
                        }
                        .padding(.vertical, 4)
                        .padding(.horizontal, 2)
                    }

                    SectionHeader(title: "Auto Cycle")
                    ToggleRow(title: "Change every 2 seconds", isOn: autoCycle) {
                        autoCycle.toggle()
                    }

                    Button {
                        selectedIndex = 8
                        autoCycle = false
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
        .onReceive(timer) { _ in
            guard autoCycle else { return }
            selectedIndex = (selectedIndex + 1) % colors.count
        }
        .toolbar(.hidden, for: .navigationBar)
        .testControls(controlsHidden: $controlsHidden, dismiss: dismiss)
    }
}

#Preview {
    DeadPixelTestView()
}