import SwiftUI

struct RayMarchingView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var controlsHidden = false
    @State private var isMinimized = false
    
    // Shader start time
    @State private var startDate = Date()

    var body: some View {
        TimelineView(.animation) { timeline in
            GeometryReader { proxy in
                Rectangle()
                    .fill(.black)
                    .colorEffect(ShaderLibrary.ray_marching(
                        .float2(proxy.size),
                        .float(Float(timeline.date.timeIntervalSince(startDate)))
                    ))
            }
            .ignoresSafeArea()
        }
        .toolbar(.hidden, for: .navigationBar)
        .testControls(controlsHidden: $controlsHidden, dismiss: dismiss)
    }
}

#Preview {
    RayMarchingView()
}