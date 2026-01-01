import SwiftUI

struct CalibrationPatternsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var pattern = 0
    @State private var controlsHidden = false
    let patterns = ["SMPTE Color Bars", "Sharpness Grid", "Overscan", "Contrast (PLUGE)"]
    
    var body: some View {
        ZStack {
            Color.black.edgesIgnoringSafeArea(.all)
            
            if pattern == 0 {
                SMPTEColorBars()
            } else if pattern == 1 {
                SharpnessGrid()
            } else if pattern == 2 {
                OverscanPattern()
            } else if pattern == 3 {
                ContrastPLUGE()
            }
            
            // Kontrol İpucu
            if !controlsHidden {
                VStack {
                    Spacer()
                    Text("Pattern: \(patterns[pattern])")
                        .glassHUD()
                        .padding(.bottom, 40)
                        .transition(.opacity)
                }
            }
        }
        .onTapGesture {
            withAnimation {
                pattern = (pattern + 1) % patterns.count
            }
        }
        .edgesIgnoringSafeArea(.all)
        .testControls(controlsHidden: $controlsHidden, dismiss: dismiss)
    }
}

// MARK: - SMPTE Color Bars
struct SMPTEColorBars: View {
    let colors: [Color] = [
        Color(red: 0.75, green: 0.75, blue: 0.75), // Gray
        Color(red: 0.75, green: 0.75, blue: 0.0),  // Yellow
        Color(red: 0.0, green: 0.75, blue: 0.75),  // Cyan
        Color(red: 0.0, green: 0.75, blue: 0.0),   // Green
        Color(red: 0.75, green: 0.0, blue: 0.75),  // Magenta
        Color(red: 0.75, green: 0.0, blue: 0.0),   // Red
        Color(red: 0.0, green: 0.0, blue: 0.75)    // Blue
    ]
    
    var body: some View {
        VStack(spacing: 0) {
            // Üst Barlar (2/3 oranında)
            HStack(spacing: 0) {
                ForEach(0..<7) { i in
                    colors[i]
                }
            }
            .frame(height: UIScreen.main.bounds.height * 0.67)
            
            // Alt Barlar (Castellation, Black/White blocks etc. - Basitleştirilmiş)
            HStack(spacing: 0) {
                Color(red: 0, green: 0.2, blue: 0.3) // I - Blue
                Color.white
                Color(red: 0.2, green: 0, blue: 0.4) // Q - Purple
                Color(white: 0.1) // Blackish
                Color(white: 0.05) // Blacker
                Color(white: 0.15) // Lighter Black
                Color(white: 0.5) // Grey
            }
        }
    }
}

// MARK: - Sharpness Grid
struct SharpnessGrid: View {
    var body: some View {
        GeometryReader { geometry in
            Path { path in
                let width = geometry.size.width
                let height = geometry.size.height
                let step: CGFloat = 100
                
                // Dikey Çizgiler
                for x in stride(from: 0, through: width, by: step) {
                    path.move(to: CGPoint(x: x, y: 0))
                    path.addLine(to: CGPoint(x: x, y: height))
                }
                
                // Yatay Çizgiler
                for y in stride(from: 0, through: height, by: step) {
                    path.move(to: CGPoint(x: 0, y: y))
                    path.addLine(to: CGPoint(x: width, y: y))
                }
                
                // Çaprazlar
                path.move(to: .zero)
                path.addLine(to: CGPoint(x: width, y: height))
                path.move(to: CGPoint(x: width, y: 0))
                path.addLine(to: CGPoint(x: 0, y: height))
                
                // Merkez Daire
                let center = CGPoint(x: width/2, y: height/2)
                path.addEllipse(in: CGRect(x: center.x - 200, y: center.y - 200, width: 400, height: 400))
            }
            .stroke(Color.white, lineWidth: 2)
            
            // 1-Piksel Keskinlik Kontrolü (Checkerboard)
            VStack(spacing: 2) {
                Text("1px Line Test")
                    .font(.caption)
                    .foregroundStyle(.white)
                Rectangle()
                    .fill(Color.white)
                    .frame(width: 200, height: 1)
                Rectangle()
                    .fill(Color.white)
                    .frame(width: 200, height: 2)
                Rectangle()
                    .fill(Color.white)
                    .frame(width: 200, height: 4)
            }
            .position(x: geometry.size.width/2, y: geometry.size.height/2)
        }
    }
}

// MARK: - Overscan Pattern
struct OverscanPattern: View {
    var body: some View {
        ZStack {
            Color.white
            Color.black.padding(40) // %5 Safe Area
            
            VStack {
                Text("Overscan Testi")
                    .font(.title)
                    .foregroundStyle(.white)
                Text("Eğer beyaz çerçeveyi göremiyorsanız TV ayarlarından 'Just Scan' veya 'Fit to Screen' seçin.")
                    .font(.caption)
                    .foregroundStyle(.gray)
                    .multilineTextAlignment(.center)
            }
            
            // Oklar
            VStack {
                Image(systemName: "arrow.up").foregroundColor(.red)
                Spacer()
                Image(systemName: "arrow.down").foregroundColor(.red)
            }.padding(10)
            
            HStack {
                Image(systemName: "arrow.left").foregroundColor(.red)
                Spacer()
                Image(systemName: "arrow.right").foregroundColor(.red)
            }.padding(10)
        }
    }
}

// MARK: - Contrast (PLUGE - Basitleştirilmiş)
struct ContrastPLUGE: View {
    var body: some View {
        HStack(spacing: 0) {
            Color.black // Reference Black (0)
            Color(white: 0.02) // Just Above Black (1) - Görünür olmalı
            Color(white: 0.04) // Just Above Black (2) - Net görünmeli
            Color(white: 0.5) // Grey
            Color(white: 0.96) // Just Below White
            Color(white: 0.98) // Just Below White
            Color.white // Reference White
        }
    }
}

#Preview {
    CalibrationPatternsView()
}
