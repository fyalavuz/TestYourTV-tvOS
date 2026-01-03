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
    @Namespace private var focusScope
    
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
                    Text("Welcome to Test Your TV")
                        .font(.largeTitle.weight(.bold))
                        .fontDesign(.rounded)
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
                
                Button("Get Started", action: onComplete)
                    .font(.title3.weight(.bold))
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .focused($isFocused)
                    .prefersDefaultFocus(true, in: focusScope)
            }
            .padding(60)
        }
        .ignoresSafeArea()
        .focusScope(focusScope)
        .onAppear {
            DispatchQueue.main.async {
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
            id: "picture-quality",
            title: "Picture Quality",
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
            id: "geometry",
            title: "Geometry & Sharpness",
            subtitle: "Gamma, text clarity, overscan and alignment.",
            items: [
                MenuOption(title: "Test Patterns", icon: "square.grid.3x3.square", color: .orange, destination: .testPatterns),
                MenuOption(title: "Text Clarity", icon: "textformat.size", color: .indigo, destination: .textClarity),
                MenuOption(title: "Gamma", icon: "circle.righthalf.filled", color: .purple, destination: .gamma),
                MenuOption(title: "Overscan", icon: "rectangle.inset.filled", color: .teal, destination: .overscan),
                MenuOption(title: "Calibration", icon: "slider.horizontal.3", color: .teal, destination: .calibration)
            ]
        ),
        MenuSection(
            id: "motion",
            title: "Motion Performance",
            subtitle: "Response time, refresh rate, and viewing angles.",
            items: [
                MenuOption(title: "Motion Test", icon: "wind", color: .orange, destination: .motion),
                MenuOption(title: "Response Time", icon: "move.3d", color: .pink, destination: .responseTime),
                MenuOption(title: "Viewing Angle", icon: "eye.fill", color: .green, destination: .viewingAngle)
            ]
        ),
        MenuSection(
            id: "visualizers",
            title: "Visualizers",
            subtitle: "Real-time procedural shaders for stress testing and aesthetics.",
            items: [
                MenuOption(title: "Infinite Cubes", icon: "cube.transparent", color: .indigo, destination: .rayMarching),
                MenuOption(title: "Fractal Stress", icon: "hexagon.fill", color: .cyan, destination: .fractal),
                MenuOption(title: "Synth Terrain", icon: "mountain.2.fill", color: .green, destination: .terrain),
                MenuOption(title: "Hyper Ring", icon: "circle.circle.fill", color: .blue, destination: .ring),
                MenuOption(title: "Spectral Flow", icon: "rainbow", color: .pink, destination: .spectral),
                MenuOption(title: "Nebula Flow", icon: "smoke.fill", color: .purple, destination: .cloud),
                MenuOption(title: "Matrix", icon: "text.and.command.macwindow", color: .green, destination: .matrix),
                MenuOption(title: "Neon Rain", icon: "cloud.rain.fill", color: .blue, destination: .rain),
                MenuOption(title: "Infinite Pipes", icon: "infinity.circle", color: .orange, destination: .noodles),
                MenuOption(title: "Color Twist", icon: "tornado.circle.fill", color: .red, destination: .twist),
                MenuOption(title: "Polar Lattice", icon: "snowflake", color: .mint, destination: .lattice),
                MenuOption(title: "Starfield", icon: "sparkles", color: .yellow, destination: .starfield),
                MenuOption(title: "Spiral", icon: "tornado", color: .orange, destination: .spiral)
            ]
        ),
        MenuSection(
            id: "audio",
            title: "Audio Suite",
            subtitle: "Speaker configuration checks and signal generation.",
            items: [
                MenuOption(title: "Audio Lab", icon: "waveform.circle.fill", color: .orange, destination: .audioLab)
            ]
        ),
        MenuSection(
            id: "utilities",
            title: "System & Utilities",
            subtitle: "Diagnostics, input testing, and panel maintenance.",
            items: [
                MenuOption(title: "System Info", icon: "cpu", color: .cyan, destination: .systemInfo),
                MenuOption(title: "Input Test", icon: "gamecontroller.fill", color: .teal, destination: .inputTest),
                MenuOption(title: "OLED Wiper", icon: "wand.and.stars", color: .purple, destination: .wiper)
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
                        // Info Badges on Header
                        HStack(spacing: 20) {
                            InfoBadge(title: "Quality", value: monitor.displayQuality)
                            InfoBadge(title: "Resolution", value: monitor.resolution)
                            InfoBadge(title: "HDR", value: monitor.hdrStatus)
                        }

                        HStack(spacing: 20) {
                            InfoBadge(title: "Device", value: monitor.deviceModel)
                            InfoBadge(title: monitor.systemName, value: monitor.systemVersion)
                            InfoBadge(title: "Name", value: monitor.deviceName)
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
                                        Spacer().frame(width: 40)
                                        
                                        ForEach(section.items) { item in
                                            VStack(alignment: .leading, spacing: 16) {
                                                NavigationLink(destination: destinationView(for: item.destination)) {
                                                    ShelfCardVisual(item: item)
                                                }
                                                .buttonStyle(.card)
                                                
                                                Text(item.title)
                                                    .font(.headline.weight(.semibold))
                                                    .foregroundStyle(.white.opacity(0.9))
                                                    .lineLimit(1)
                                                    .minimumScaleFactor(0.8)
                                                    .padding(.horizontal, 8)
                                                    .allowsHitTesting(false)
                                            }
                                            .frame(width: 380)
                                        }
                                        
                                        Spacer().frame(width: 80)
                                    }
                                }
                                .scrollClipDisabled() 
                            }
                        }
                    }
                    .padding(.bottom, 80)
                }
            }
        }
    }
    
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
        case .overscan: OverscanTestView()
        case .videoTests: VideoTestsView()
        case .videoBunny: VideoClipDetailView(clip: VideoData.bunny)
        case .videoTears: VideoClipDetailView(clip: VideoData.tears)
        case .technicalTests: VideoTestsView()
        case .inputTest: InputTestView()
        case .systemInfo: SystemInfoView()
        case .audioLab: AudioLabView()
        case .rayMarching: RayMarchingView()
        case .starfield: StarfieldView()
        case .spiral: SpiralView()
        case .fractal: FractalView()
        case .rain: RainView()
        case .noodles: NoodlesView()
        case .spectral: SpectralView()
        case .terrain: TerrainView()
        case .ring: RingView()
        case .twist: TwistView()
        case .lattice: LatticeView()
        case .cloud: CloudView()
        }
    }
}

// --- Visual Part Only for the Card ---
struct ShelfCardVisual: View {
    let item: MenuOption
    
    var body: some View {
        ZStack {
            if let url = item.thumbnailURL {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                    default:
                        ZStack {
                            item.color.opacity(0.2)
                            Image(systemName: item.icon)
                                .font(.system(size: 80))
                                .foregroundStyle(item.color.gradient)
                        }
                    }
                }
                .frame(width: 380, height: 214) // 16:9 ratio
                .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            } else {
                ZStack {
                    Color.white.opacity(0.05)
                    Image(systemName: item.icon)
                        .font(.system(size: 80))
                        .foregroundStyle(item.color.gradient)
                        .shadow(color: item.color.opacity(0.5), radius: 10)
                }
                .frame(width: 380, height: 260)
                .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            }
        }
    }
}

// --- YARDIMCI YAPILAR ---

enum DestinationType: Hashable {
    case calibration, deadPixel, uniformity, colorGradient, colorDistance
    case textClarity, gamma, testPatterns, responseTime, viewingAngle
    case brightness, contrast, matrix, audio, motion, wiper, overscan, videoTests, videoBunny, videoTears, technicalTests, inputTest, systemInfo, audioLab, rayMarching, starfield, spiral, fractal, rain, noodles, spectral, terrain, ring, twist, lattice, cloud
}

struct MenuOption: Identifiable {
    let title: String
    let icon: String
    let color: Color
    let destination: DestinationType
    let thumbnailURL: URL?
    var id: DestinationType { destination }
    
    init(title: String, icon: String, color: Color, destination: DestinationType, thumbnailURL: URL? = nil) {
        self.title = title
        self.icon = icon
        self.color = color
        self.destination = destination
        self.thumbnailURL = thumbnailURL
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
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .allowsTightening(true)
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
