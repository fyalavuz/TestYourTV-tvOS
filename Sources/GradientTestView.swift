import SwiftUI

struct GradientTestView: View {
    let gradients: [[Color]] = [
        [.black, .white],
        [.black, .red],
        [.black, .green],
        [.black, .blue],
        [.red, .orange, .yellow, .green, .blue, .purple]
    ]
    
    @State private var currentIdx = 0
    
    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: gradients[currentIdx]),
                startPoint: .leading,
                endPoint: .trailing
            )
            .edgesIgnoringSafeArea(.all)
            
            VStack {
                Spacer()
                Text("Banding Kontrolü - Geçişlerin pürüzsüz olması gerekir.")
                    .font(.headline)
                    .padding()
                    .background(Color.black.opacity(0.6))
                    .cornerRadius(10)
                    .padding(.bottom, 50)
            }
        }
        .onTapGesture {
            currentIdx = (currentIdx + 1) % gradients.count
        }
        .focusable()
    }
}

#Preview {
    GradientTestView()
}
