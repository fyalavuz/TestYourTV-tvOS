import SwiftUI

struct AudioTestsView: View {
    @StateObject private var audioManager = AudioManager()
    @State private var activeSpeaker: String? = nil
    
    let speakers = [
        ("Left Front", "hifispeaker.fill"),
        ("Center", "hifispeaker.fill"),
        ("Right Front", "hifispeaker.fill"),
        ("Left Surround", "speaker.wave.2.fill"),
        ("Right Surround", "speaker.wave.2.fill"),
        ("Subwoofer", "speaker.zzz.fill")
    ]
    
    var body: some View {
        ZStack {
            AmbientBackground()

            VStack(spacing: 40) {
                VStack(spacing: 12) {
                    Text("Audio Channel Test")
                        .font(.system(size: 54, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)

                    Text("Confirm every speaker channel plays correctly.")
                        .font(.headline)
                        .foregroundStyle(.white.opacity(0.7))
                }

                AudioRouteCard(summary: audioManager.outputRouteSummary, outputs: audioManager.outputRoutes)
                    .frame(maxWidth: 860)

                LazyVGrid(columns: [GridItem(.adaptive(minimum: 260), spacing: 24)], spacing: 24) {
                    ForEach(speakers, id: \.0) { speaker in
                        Button(action: {
                            testSpeaker(speaker.0)
                        }) {
                            VStack(spacing: 18) {
                                Image(systemName: speaker.1)
                                    .font(.system(size: 56))
                                    .foregroundStyle(activeSpeaker == speaker.0 ? .green : .white)

                                Text(speaker.0)
                                    .font(.headline)
                                    .foregroundStyle(.white)
                            }
                            .frame(maxWidth: .infinity, minHeight: 190)
                            .glassSurface(cornerRadius: 26, strokeOpacity: activeSpeaker == speaker.0 ? 0.45 : 0.18)
                            .overlay(
                                RoundedRectangle(cornerRadius: 26, style: .continuous)
                                    .stroke(activeSpeaker == speaker.0 ? Color.green.opacity(0.8) : Color.clear, lineWidth: 2)
                            )
                        }
                        .buttonStyle(.glassFocus(cornerRadius: 26))
                    }
                }
                .padding(.horizontal, 40)

                if let active = activeSpeaker {
                    Text("Testing: \(active)")
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(.green)
                        .padding(.top, 12)
                }
            }
            .padding(.vertical, 60)
        }
        .toolbar(.hidden, for: .navigationBar)
    }
    
    func testSpeaker(_ name: String) {
        activeSpeaker = name
        // Demo amaçlı konuşma sentezi.
        // Gerçek dünyada burada o kanala özel sinyal gönderilir.
        audioManager.playChannelTest(channel: name)
        
        // Animasyon için reset
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            if activeSpeaker == name {
                activeSpeaker = nil
                audioManager.stop()
            }
        }
    }
}

private struct AudioRouteCard: View {
    let summary: String
    let outputs: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Audio Output Route")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)

            Text(summary)
                .font(.headline.weight(.semibold))
                .foregroundStyle(.white)

            ForEach(outputs.indices, id: \.self) { index in
                Text(outputs[index])
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassSurface(cornerRadius: 20, strokeOpacity: 0.16)
    }
}

#Preview {
    AudioTestsView()
}
