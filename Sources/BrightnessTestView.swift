import SwiftUI

struct BrightnessTestView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var controlsHidden = false
    @State private var isMinimized = false
    @State private var hasStarted = false

    var body: some View {
        ZStack {
            // Background must be Reference Black (RGB 0)
            Color.black.ignoresSafeArea()

            if !hasStarted {
                // Instructional Overlay
                VStack(spacing: 40) {
                    Image(systemName: "sun.max.fill")
                        .font(.system(size: 100))
                        .foregroundStyle(.white)
                        .shadow(color: .white.opacity(0.5), radius: 20)
                    
                    VStack(spacing: 16) {
                        Text("Black Level Calibration")
                            .font(.system(size: 52, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                        
                        Text("Calibrate your TV's 'Brightness' setting for perfect blacks.")
                            .font(.title3)
                            .foregroundStyle(.white.opacity(0.7))
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: 800)
                    }
                    
                    VStack(alignment: .leading, spacing: 20) {
                        InstructionRow(icon: "eye.slash.fill", text: "Strip 10 & 16 should be INVISIBLE (Black).")
                        InstructionRow(icon: "eye.fill", text: "Strip 20 should be BARELY visible.")
                        InstructionRow(icon: "lightbulb.fill", text: "Strip 24 should be VISIBLE.")
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
                            Text("Start Calibration")
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
                // Test Pattern
                GeometryReader { proxy in
                    let width = proxy.size.width
                    
                    HStack(spacing: 0) {
                        // Bar 1: RGB 10 (3.9%)
                        Rectangle()
                            .fill(Color(red: 10/255, green: 10/255, blue: 10/255))
                            .overlay(Text("10").font(.caption).foregroundColor(.gray).padding(.bottom, 20), alignment: .bottom)
                            .frame(width: width * 0.15)
                        
                        // Bar 2: RGB 16 (6.2%) - Video Black Ref
                        Rectangle()
                            .fill(Color(red: 16/255, green: 16/255, blue: 16/255))
                            .overlay(Text("16 (Ref)").font(.caption).foregroundColor(.gray).padding(.bottom, 20), alignment: .bottom)
                            .frame(width: width * 0.15)
                        
                        // Bar 3: RGB 20 (7.8%) - Near Black
                        Rectangle()
                            .fill(Color(red: 20/255, green: 20/255, blue: 20/255))
                            .overlay(Text("20").font(.caption).foregroundColor(.gray).padding(.bottom, 20), alignment: .bottom)
                            .frame(width: width * 0.15)
                        
                        // Bar 4: RGB 24 (9.4%) - Visible Dark Gray
                        Rectangle()
                            .fill(Color(red: 24/255, green: 24/255, blue: 24/255))
                            .overlay(Text("24").font(.caption).foregroundColor(.gray).padding(.bottom, 20), alignment: .bottom)
                            .frame(width: width * 0.15)
                        
                        Spacer()
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                
                ControlPanelDock(title: "Instructions", isMinimized: $isMinimized, controlsHidden: controlsHidden) {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("If you see strip 16, lower Brightness.")
                            .font(.callout)
                            .foregroundStyle(.secondary)
                        Text("If you can't see strip 20, raise Brightness.")
                            .font(.callout)
                            .foregroundStyle(.secondary)
                        
                        Button {
                            withAnimation { hasStarted = false }
                        } label: {
                            Text("Show Intro Again")
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
        }
        .toolbar(.hidden, for: .navigationBar)
        .testControls(controlsHidden: $controlsHidden, dismiss: dismiss)
    }
}

#Preview {
    BrightnessTestView()
}
