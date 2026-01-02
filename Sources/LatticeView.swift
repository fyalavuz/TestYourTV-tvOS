import SwiftUI

struct LatticeView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var controlsHidden = false
    @State private var startDate = Date()

    var body: some View {
        TimelineView(.animation) { timeline in
            GeometryReader { proxy in
                Rectangle()
                    .fill(.black)
                    .colorEffect(ShaderLibrary.polar_lattice(
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
    LatticeView()
}
