import SwiftUI

struct CloudingTestView: View {
    @State private var step = 0

    private let screens: [(label: String, color: Color)] = [
        ("Tam Siyah", .black),
        ("Koyu Gri", Color(white: 0.05)),
        ("Gri", Color(white: 0.1))
    ]

    var body: some View {
        let screen = screens[step]

        ZStack {
            screen.color
                .edgesIgnoringSafeArea(.all)

            VStack(spacing: 8) {
                Text("Bulutlanma Testi")
                    .font(.system(size: 46, weight: .bold))
                Text("\(screen.label) - degistirmek icin dokunun")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.8))
            }
            .foregroundColor(.white)
        }
        .onTapGesture {
            step = (step + 1) % screens.count
        }
    }
}

#Preview {
    CloudingTestView()
}
