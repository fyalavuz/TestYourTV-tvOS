import SwiftUI

struct ContentView: View {
    @AppStorage("hasLaunched") private var hasLaunched = false
    @State private var showOnboarding = false

    var body: some View {
        NavigationStack {
            HomeHubView()
        }
        .overlay {
            if !hasLaunched {
                OnboardingView(onComplete: {
                    withAnimation {
                        hasLaunched = true
                    }
                })
                .transition(.opacity)
                .zIndex(100)
            }
        }
    }
}

struct OnboardingView: View {
    let onComplete: () -> Void
    @FocusState private var isFocused: Bool
    
    var body: some View {
        ZStack {
            AmbientBackground()
                .overlay(.black.opacity(0.4))
            
            VStack(spacing: 50) {
                Image(systemName: "tv.and.mediabox")
                    .font(.system(size: 120))
                    .foregroundStyle(.white)
                    .shadow(color: .white.opacity(0.5), radius: 30)
                    .padding(.bottom, 20)
                
                VStack(spacing: 16) {
                    Text("Welcome to ProDisplay TV")
                        .font(.system(size: 60, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                    
                    Text("The professional calibration suite for your home theater.")
                        .font(.title2)
                        .foregroundStyle(.white.opacity(0.7))
                }
                
                HStack(spacing: 40) {
                    FeatureItem(icon: "sparkles.tv", title: "OLED Care", desc: "Prevent burn-in")
                    FeatureItem(icon: "slider.horizontal.3", title: "Calibration", desc: "Perfect colors")
                    FeatureItem(icon: "waveform", title: "Audio Check", desc: "Surround test")
                }
                .padding(.vertical, 40)
                
                Button(action: onComplete) {
                    Text("Get Started")
                        .font(.title3.weight(.bold))
                        .foregroundStyle(.black)
                        .padding(.horizontal, 60)
                        .padding(.vertical, 20)
                        .background(Color.white)
                        .clipShape(Capsule())
                }
                .focused($isFocused)
                .buttonStyle(.card)
                .hoverEffect(.lift)
            }
            .padding(60)
        }
        .ignoresSafeArea()
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                isFocused = true
            }
        }
    }
}

struct FeatureItem: View {
    let icon: String
    let title: String
    let desc: String
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.largeTitle)
                .foregroundStyle(.white)
            
            VStack(spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                Text(desc)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.6))
                    .multilineTextAlignment(.center)
            }
        }
        .frame(width: 260)
        .padding(24)
        .glassSurface(cornerRadius: 24, strokeOpacity: 0.1)
    }
}

struct HomeHubView: View {
    @StateObject private var monitor = DeviceMonitor()
    
    // Netflix-style Navigation Data
    let menuSections: [MenuSection] = [
        MenuSection(
            id: "core-tests",
            title: "Core Tests",
            subtitle: "Pixel defects, uniformity, gradients, and contrast checks.",
            items: [
                MenuOption(title: "Dead Pixel", icon: "dot.squareshape.split.2x2", color: .red, destination: .deadPixel),
                MenuOption(title: "Uniformity", icon: "circle.grid.3x3.fill", color: .mint, destination: .uniformity),
                MenuOption(title: "Color Gradient", icon: "circle.lefthalf.filled", color: .blue, destination: .colorGradient),
                MenuOption(title: "Color Distance", icon: "eyedropper.halffull", color: .cyan, destination: .colorDistance),
                MenuOption(title: "Contrast", icon: "checkerboard.rectangle", color: .gray, destination: .contrast),
                MenuOption(title: "Brightness", icon: "sun.max.fill", color: .yellow, destination: .brightness)
            ]
        ),
        MenuSection(
            id: "calibration",
            title: "Calibration",
            subtitle: "Text clarity, gamma, and reference patterns.",
            items: [
                MenuOption(title: "Text Clarity", icon: "textformat.size", color: .indigo, destination: .textClarity),
                MenuOption(title: "Gamma", icon: "circle.righthalf.filled", color: .purple, destination: .gamma),
                MenuOption(title: "Test Patterns", icon: "square.grid.3x3.square", color: .orange, destination: .testPatterns),
                MenuOption(title: "Calibration", icon: "slider.horizontal.3", color: .teal, destination: .calibration)
            ]
        ),
        MenuSection(
            id: "motion-angle",
            title: "Motion & Angle",
            subtitle: "Response time, viewing angle, and motion behavior.",
            items: [
                MenuOption(title: "Response Time", icon: "move.3d", color: .pink, destination: .responseTime),
                MenuOption(title: "Viewing Angle", icon: "eye.fill", color: .green, destination: .viewingAngle),
                MenuOption(title: "Motion Test", icon: "wind", color: .orange, destination: .motion)
            ]
        ),
        MenuSection(
            id: "tools-extras",
            title: "Tools & Extras",
            subtitle: "Audio channel checks, OLED care, and diagnostics.",
            items: [
                MenuOption(title: "Audio Test", icon: "hifispeaker.2.fill", color: .green, destination: .audio),
                MenuOption(title: "OLED Wiper", icon: "wand.and.stars", color: .purple, destination: .wiper),
                MenuOption(title: "Matrix", icon: "text.and.command.macwindow", color: .white, destination: .matrix)
            ]
        )
    ]
    
    var body: some View {
        ZStack {
            AmbientBackground()

            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 40) {
                    
                    // --- HERO HEADER ---
                    VStack(alignment: .leading, spacing: 20) {
                        HStack(alignment: .bottom) {
                            // Info Badges on Header
                            HStack(spacing: 20) {
                                InfoBadge(title: "Quality", value: monitor.displayQuality)
                                InfoBadge(title: "Resolution", value: monitor.resolution)
                                InfoBadge(title: "HDR", value: monitor.hdrStatus)
                            }

                            Spacer()

                            Text("ProDisplay TV")
                                .font(.system(size: 70, weight: .bold, design: .default))
                                .foregroundStyle(.white)
                                .tracking(-1)
                                .shadow(color: Color.black.opacity(0.3), radius: 10, x: 0, y: 5)
                        }
                    }
                    .padding(.top, 40)
                    .padding(.horizontal, 80) // Global padding for header

                    // --- SHELVES ---
                    LazyVStack(alignment: .leading, spacing: 50) {
                        ForEach(menuSections) { section in
                            VStack(alignment: .leading, spacing: 20) {
                                // Section Title
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(section.title)
                                        .font(.title2.weight(.bold))
                                        .foregroundStyle(.white)
                                        .padding(.horizontal, 80) // Align with header
                                    
                                    Text(section.subtitle)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                        .padding(.horizontal, 80)
                                }
                                
                                // Horizontal Scroll Row (The Shelf)
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 40) {
                                        // Leading spacer for content offset
                                        Spacer().frame(width: 40)
                                        
                                        ForEach(section.items) { item in
                                            NavigationLink(destination: destinationView(for: item.destination)) {
                                                ShelfCard(item: item)
                                            }
                                            .buttonStyle(.card) // tvOS scaling effect
                                        }
                                        
                                        // Trailing spacer
                                        Spacer().frame(width: 80)
                                    }
                                }
                                // Ensure focus clips correctly or extends
                                .scrollClipDisabled() 
                            }
                        }
                    }
                    .padding(.bottom, 80)
                }
            }
        }
    }
    
    // Yönlendirme Mantığı
    @ViewBuilder
    func destinationView(for destination: DestinationType) -> some View {
        switch destination {
        case .calibration: CalibrationPatternsView()
        case .deadPixel: DeadPixelTestView()
        case .uniformity: UniformityTestView()
        case .textClarity: TextClarityView()
        case .audio: AudioTestsView()
        case .motion: MotionTestView()
        case .wiper: BurnInWiperView()
        case .colorGradient: ColorGradientTestView()
        case .colorDistance: ColorDistanceTestView()
        case .testPatterns: TestPatternsView()
        case .gamma: GammaTestView()
        case .responseTime: ResponseTimeTestView()
        case .viewingAngle: ViewingAngleTestView()
        case .brightness: BrightnessTestView()
        case .contrast: ContrastTestView()
        case .matrix: MatrixTestView()
        }
    }
}

// --- YARDIMCI YAPILAR ---

enum DestinationType: Hashable {
    case calibration, deadPixel, uniformity, colorGradient, colorDistance
    case textClarity, gamma, testPatterns, responseTime, viewingAngle
    case brightness, contrast, matrix, audio, motion, wiper
}

struct MenuOption: Identifiable {
    let title: String
    let icon: String
    let color: Color
    let destination: DestinationType
    var id: DestinationType { destination }
}

struct ShelfCard: View {
    let item: MenuOption
    
    var body: some View {
        VStack(spacing: 0) {
            // Icon Area
            ZStack {
                Image(systemName: item.icon)
                    .font(.system(size: 80)) // Larger icon
                    .foregroundStyle(item.color.gradient)
                    .shadow(color: item.color.opacity(0.5), radius: 10)
            }
            .frame(width: 380, height: 220) // Standard landscape card ratio
            
            // Title Area
            HStack {
                Text(item.title)
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(.white)
                Spacer()
            }
            .padding(20)
            .background(.thinMaterial) // Glass bottom
        }
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        // No explicit frame here, NavigationLink buttonStyle handles scale
    }
}

struct InfoBadge: View {
    let title: String
    let value: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title.uppercased())
                .font(.caption2.weight(.bold))
                .foregroundStyle(.secondary)
            Text(value)
                .font(.headline.weight(.semibold))
                .foregroundStyle(.white)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct MenuSection: Identifiable {
    let id: String
    let title: String
    let subtitle: String
    let items: [MenuOption]
}

#Preview {
    ContentView()
}
