import SwiftUI

struct ViewingAngleTestView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var isMinimized = false
    @State private var controlsHidden = false
    @State private var hasStarted = false
    
    // Test sensitivity
    @State private var gammaSensitivity: Double = 0.05
    @State private var colorShiftMode: Bool = false

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            if !hasStarted {
                // Instructional Overlay (Initial State)
                VStack(spacing: 40) {
                    Image(systemName: "eye.fill")
                        .font(.system(size: 100))
                        .foregroundStyle(.white)
                        .shadow(color: .white.opacity(0.5), radius: 20)
                    
                    VStack(spacing: 16) {
                        Text("Viewing Angle Check")
                            .font(.system(size: 52, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                        
                        Text("This test evaluates color shift and contrast loss at extreme angles.")
                            .font(.title3)
                            .foregroundStyle(.white.opacity(0.7))
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: 800)
                    }
                    
                    VStack(alignment: .leading, spacing: 20) {
                        InstructionRow(icon: "arrow.left.and.right", text: "Move to the side of your TV while watching the screen.")
                        InstructionRow(icon: "paintpalette.fill", text: "Watch for skin tones turning yellow or blue (Color Shift).")
                        InstructionRow(icon: "shadow", text: "Check if dark gray squares disappear into black (Gamma Shift).")
                    }
                    .padding(40)
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                    
                    Button {
                        withAnimation {
                            hasStarted = true
                        }
                    } label: {
                        HStack(spacing: 12) {
                            Text("Start Test")
                            Image(systemName: "arrow.right")
                        }
                        .font(.title3.weight(.bold))
                        .padding(.horizontal, 40)
                        .padding(.vertical, 16)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.white)
                    .foregroundColor(.black)
                }
            } else {
                // Main Test Pattern
                GeometryReader { proxy in
                    HStack(spacing: 0) {
                        // Left Side: Gamma / Washout Test
                        // Dark grays on black (Shadow detail check)
                        VStack(spacing: 0) {
                            ForEach(0..<8) { i in
                                let brightness = Double(i) * gammaSensitivity + 0.01
                                Rectangle()
                                    .fill(Color(white: brightness))
                                    .overlay(
                                        Text("\(Int(brightness * 100))%")
                                            .font(.caption.weight(.bold))
                                            .foregroundStyle(.white.opacity(0.5))
                                    )
                            }
                        }
                        .frame(maxWidth: .infinity)
                        
                        // Center: Skin Tone & Pastel (Color Shift Check)
                        VStack(spacing: 0) {
                            let skinTones: [Color] = [
                                Color(red: 1.0, green: 0.8, blue: 0.6), // Light
                                Color(red: 0.8, green: 0.6, blue: 0.4), // Medium
                                Color(red: 0.4, green: 0.25, blue: 0.15), // Dark
                                Color(red: 0.9, green: 0.7, blue: 0.7)  // Rosy
                            ]
                            ForEach(0..<4) { i in
                                skinTones[i]
                                    .overlay(
                                        Text("COLOR CHECK")
                                            .font(.headline.weight(.heavy))
                                            .foregroundStyle(.white.opacity(0.2))
                                    )
                            }
                        }
                        .frame(maxWidth: .infinity)
                        
                        // Right Side: Contrast Washout
                        // Light grays on white (Highlight clipping check)
                        VStack(spacing: 0) {
                            ForEach(0..<8) { i in
                                let brightness = 1.0 - (Double(i) * gammaSensitivity + 0.01)
                                Rectangle()
                                    .fill(Color(white: brightness))
                                    .overlay(
                                        Text("\(Int(brightness * 100))%")
                                            .font(.caption.weight(.bold))
                                            .foregroundStyle(.black.opacity(0.5))
                                    )
                            }
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
                .ignoresSafeArea()
                
                ControlPanelDock(title: "Viewing Angle", isMinimized: $isMinimized, controlsHidden: controlsHidden) {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Adjust sensitivity to match your display's black/white levels.")
                            .font(.callout)
                            .foregroundStyle(.secondary)

                        SectionHeader(title: "Step Contrast")
                        LabeledSlider(value: $gammaSensitivity, range: 0.01...0.10, step: 0.01, suffix: "")
                        
                        Text("Lower value = Harder test (detects subtle shifts)")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .testControls(controlsHidden: $controlsHidden, dismiss: dismiss)
    }
}

#Preview {
    ViewingAngleTestView()
}