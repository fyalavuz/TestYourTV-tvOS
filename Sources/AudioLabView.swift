import SwiftUI
import AVFoundation

struct AudioLabView: View {
    enum AudioMode: Hashable {
        case menu
        case channels
        case tones
        case sweep
        case noise
    }

    @State private var currentMode: AudioMode = .menu
    @State private var lastMode: AudioMode? = nil 
    @StateObject private var audioManager = AudioManager()
    @StateObject private var toneEngine = ToneEngine()
    @Environment(\.dismiss) private var dismiss
    
    // Focus Management for Content
    @FocusState private var focusedField: FocusField?
    // Focus Management for Main Menu
    @FocusState private var focusedMenuItem: AudioMode?
    
    enum FocusField {
        case content
    }

    var body: some View {
        ZStack {
            AmbientBackground()

            if currentMode == .menu {
                mainMenu
                    .transition(.move(edge: .leading).combined(with: .opacity))
            } else {
                activeView
                    .transition(.move(edge: .trailing).combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: currentMode)
        .toolbar(.hidden, for: .navigationBar)
        .onDisappear { stopAll() }
        .onAppear {
            #if os(iOS) || os(tvOS)
            UIApplication.shared.isIdleTimerDisabled = true
            #endif
            // Initial focus logic
            if currentMode != .menu {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    focusedField = .content
                }
            } else {
                // If starting in menu, default to channels or last used
                focusedMenuItem = .channels
            }
        }
        .onChange(of: currentMode) { newMode in
            if newMode != .menu {
                lastMode = newMode 
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    focusedField = .content
                }
            } else {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    focusedMenuItem = lastMode ?? .channels
                }
            }
        }
        .onDisappear {
            #if os(iOS) || os(tvOS)
            UIApplication.shared.isIdleTimerDisabled = false
            #endif
        }
    }

    private var mainMenu: some View {
        VStack(spacing: 40) {
            VStack(spacing: 12) {
                Text("Audio Lab")
                    .font(.system(size: 60, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                Text("Professional Audio Diagnostics")
                    .font(.title3)
                    .foregroundStyle(.white.opacity(0.6))
            }

            VStack(spacing: 20) {
                MenuButton(title: "Speaker Layout", icon: "hifispeaker.2.fill", color: .green) {
                    currentMode = .channels
                }
                .focused($focusedMenuItem, equals: .channels)
                
                MenuButton(title: "Sine Generator", icon: "waveform.path.ecg", color: .blue) {
                    currentMode = .tones
                }
                .focused($focusedMenuItem, equals: .tones)
                
                MenuButton(title: "Frequency Sweep", icon: "chart.xyaxis.line", color: .orange) {
                    currentMode = .sweep
                }
                .focused($focusedMenuItem, equals: .sweep)
                
                MenuButton(title: "Noise Generator", icon: "aqi.medium", color: .purple) {
                    currentMode = .noise
                }
                .focused($focusedMenuItem, equals: .noise)
            }
            .frame(width: 800)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onExitCommand {
            dismiss()
        }
    }

    @ViewBuilder
    private var activeView: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 0) {
                // Content Area
                ZStack {
                    switch currentMode {
                    case .channels:
                        ChannelsLayoutView(audioManager: audioManager)
                            .onExitCommand { goBack() }
                    case .tones:
                        TonesView(toneEngine: toneEngine)
                            .onExitCommand { goBack() }
                    case .sweep:
                        SweepView(toneEngine: toneEngine)
                            .onExitCommand { goBack() }
                    case .noise:
                        NoiseView(toneEngine: toneEngine)
                            .onExitCommand { goBack() }
                    case .menu:
                        EmptyView()
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 60)
                .padding(.bottom, 100)
                .focused($focusedField, equals: .content)
            }
        }
    }
    
    private func goBack() {
        stopAll()
        withAnimation {
            currentMode = .menu
        }
    }

    private func stopAll() {
        audioManager.stop()
        toneEngine.stop()
    }
}

struct MenuButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 20) {
                Image(systemName: icon)
                    .font(.system(size: 32))
                    .foregroundStyle(color)
                    .frame(width: 50)
                
                Text(title)
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(.white)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.headline)
                    .foregroundStyle(.white.opacity(0.3))
            }
            .padding(24)
            .background(Color.white.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        }
        .buttonStyle(.glassFocus(cornerRadius: 20))
    }
}

// MARK: - Spatial Speaker Layout
struct ChannelsLayoutView: View {
    @ObservedObject var audioManager: AudioManager
    @State private var activeSpeaker: String? = nil

    var body: some View {
        VStack {
            Spacer()
            
            // TV / Screen representation
            RoundedRectangle(cornerRadius: 12)
                .fill(LinearGradient(colors: [.gray.opacity(0.3), .gray.opacity(0.1)], startPoint: .top, endPoint: .bottom))
                .frame(width: 400, height: 20)
                .overlay(Text("DISPLAY").font(.caption2).fontWeight(.black).foregroundStyle(.white.opacity(0.4)).padding(.top, 30))
                .padding(.bottom, 60)

            // Spatial Grid
            Grid(horizontalSpacing: 80, verticalSpacing: 80) {
                GridRow {
                    SpeakerButton(name: "Left Front", icon: "hifispeaker.fill", activeSpeaker: $activeSpeaker, action: play)
                    SpeakerButton(name: "Center", icon: "hifispeaker.and.homepod.fill", activeSpeaker: $activeSpeaker, action: play)
                    SpeakerButton(name: "Right Front", icon: "hifispeaker.fill", activeSpeaker: $activeSpeaker, action: play)
                }
                GridRow {
                    SpeakerButton(name: "Left Surround", icon: "speaker.wave.2.fill", activeSpeaker: $activeSpeaker, action: play)
                    SpeakerButton(name: "Subwoofer", icon: "speaker.zzz.fill", activeSpeaker: $activeSpeaker, action: play)
                    SpeakerButton(name: "Right Surround", icon: "speaker.wave.2.fill", activeSpeaker: $activeSpeaker, action: play)
                }
            }
            
            Spacer().frame(height: 60) 
            
            VStack {
                if let active = activeSpeaker {
                    Text("Playing: \(active)")
                        .font(.title2.weight(.bold))
                        .foregroundStyle(.green)
                } else {
                    Text("Select a speaker to test")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(height: 80)
            .padding(.bottom, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    func play(_ name: String) {
        activeSpeaker = name
        audioManager.playChannelTest(channel: name)
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            if activeSpeaker == name {
                activeSpeaker = nil
                audioManager.stop()
            }
        }
    }
}

struct SpeakerButton: View {
    let name: String
    let icon: String
    @Binding var activeSpeaker: String?
    let action: (String) -> Void

    var body: some View {
        Button(action: { action(name) }) {
            VStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 44))
                    .foregroundStyle(activeSpeaker == name ? .green : .white)
                    .shadow(color: activeSpeaker == name ? .green.opacity(0.5) : .clear, radius: 10)
                
                Text(name)
                    .font(.headline.weight(.bold))
                    .foregroundStyle(.white.opacity(0.95))
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, 16)
            }
            .frame(width: 320, height: 200)
            .background(Color.white.opacity(activeSpeaker == name ? 0.15 : 0.05))
            .clipShape(RoundedRectangle(cornerRadius: 32, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 32, style: .continuous)
                    .stroke(activeSpeaker == name ? Color.green.opacity(0.6) : Color.white.opacity(0.1), lineWidth: 2)
            )
        }
        .buttonStyle(.glassFocus(cornerRadius: 32))
    }
}

// MARK: - Subviews (Refactored)
struct TonesView: View {
    @ObservedObject var toneEngine: ToneEngine
    @State private var frequency: Double = 1000
    @State private var isPlaying = false

    var body: some View {
        VStack(spacing: 40) {
            VStack(spacing: 8) {
                Text("Sine Tone Generator")
                    .font(.title2.weight(.bold))
                    .foregroundStyle(.white)
                Text("\(Int(frequency)) Hz")
                    .font(.system(size: 64, weight: .thin, design: .monospaced))
                    .foregroundStyle(.blue)
            }

            // Flattened hierarchy: Removed grouping VStacks
            LabeledSlider(value: $frequency, range: 20...20000, step: 10, suffix: " Hz")
                .frame(width: 600)
            
            HStack(spacing: 20) {
                PresetButton(title: "Low (100Hz)") { frequency = 100; if isPlaying { toneEngine.playSine(frequency: frequency) } }
                PresetButton(title: "Mid (1kHz)") { frequency = 1000; if isPlaying { toneEngine.playSine(frequency: frequency) } }
                PresetButton(title: "High (10kHz)") { frequency = 10000; if isPlaying { toneEngine.playSine(frequency: frequency) } }
            }

            Button(action: {
                if isPlaying { toneEngine.stop() } else { toneEngine.playSine(frequency: frequency) }
                isPlaying.toggle()
            }) {
                HStack(spacing: 16) {
                    Image(systemName: isPlaying ? "stop.fill" : "play.fill")
                        .font(.system(size: 32))
                    Text(isPlaying ? "Stop Tone" : "Play Tone")
                        .font(.headline)
                }
                .padding(.horizontal, 40)
                .padding(.vertical, 20)
                .background(isPlaying ? Color.red : Color.green)
                .clipShape(RoundedRectangle(cornerRadius: 24))
            }
            .buttonStyle(.glassFocus(cornerRadius: 24))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct PresetButton: View {
    let title: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.callout.weight(.medium))
                .padding(.vertical, 12)
                .padding(.horizontal, 24)
                .background(Color.white.opacity(0.1))
                .cornerRadius(12)
        }
        .buttonStyle(.glassFocus(cornerRadius: 12))
    }
}

struct SweepView: View {
    @ObservedObject var toneEngine: ToneEngine
    @State private var start: Double = 20
    @State private var end: Double = 20000
    @State private var duration: Double = 10
    @State private var isRunning = false

    var body: some View {
        VStack(spacing: 40) {
            Text("Frequency Sweep")
                .font(.title2.weight(.bold))
                .foregroundStyle(.white)

            // Layout match: TonesView style but with 3 sliders
            
            LabeledSlider(value: $start, range: 20...1000, step: 10, suffix: " Hz Start")
                .frame(width: 600)
            
            LabeledSlider(value: $end, range: 1000...20000, step: 100, suffix: " Hz End")
                .frame(width: 600)
            
            LabeledSlider(value: $duration, range: 5...60, step: 5, suffix: " s Duration")
                .frame(width: 600)

            Button(action: {
                if isRunning { toneEngine.stop() } else { toneEngine.playSweep(start: start, end: end, duration: duration) }
                isRunning.toggle()
            }) {
                HStack(spacing: 16) {
                    Image(systemName: isRunning ? "stop.fill" : "chart.xyaxis.line")
                        .font(.system(size: 32))
                    Text(isRunning ? "Stop Sweep" : "Start Sweep")
                        .font(.headline)
                }
                .frame(width: 600, height: 80) // Width match Sliders (600)
                .background(isRunning ? Color.red : Color.orange)
                .clipShape(RoundedRectangle(cornerRadius: 24))
            }
            .buttonStyle(.glassFocus(cornerRadius: 24))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct NoiseView: View {
    @ObservedObject var toneEngine: ToneEngine
    @State private var type: ToneEngine.NoiseType = .white
    @State private var isPlaying = false

    var body: some View {
        VStack(spacing: 50) {
            Text("Noise Generator")
                .font(.title2.weight(.bold))
                .foregroundStyle(.white)

            HStack(spacing: 40) {
                NoiseButton(title: "White Noise", type: .white, current: type) { type = .white; if isPlaying { toneEngine.playNoise(type: .white) } }
                NoiseButton(title: "Pink Noise", type: .pink, current: type) { type = .pink; if isPlaying { toneEngine.playNoise(type: .pink) } }
            }

            Button(action: {
                if isPlaying { toneEngine.stop() } else { toneEngine.playNoise(type: type) }
                isPlaying.toggle()
            }) {
                HStack(spacing: 16) {
                    Image(systemName: isPlaying ? "stop.fill" : "play.fill")
                        .font(.system(size: 32))
                    Text(isPlaying ? "Stop Noise" : "Play Noise")
                        .font(.headline)
                }
                .frame(width: 300, height: 80)
                .background(isPlaying ? Color.red : Color.purple)
                .clipShape(RoundedRectangle(cornerRadius: 24))
            }
            .buttonStyle(.glassFocus(cornerRadius: 24))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct NoiseButton: View {
    let title: String
    let type: ToneEngine.NoiseType
    let current: ToneEngine.NoiseType
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.headline)
                .foregroundStyle(.white)
                .frame(width: 240, height: 120)
                .background(current == type ? Color.white.opacity(0.2) : Color.white.opacity(0.05))
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(current == type ? Color.white : Color.clear, lineWidth: 2)
                )
        }
        .buttonStyle(.glassFocus(cornerRadius: 20))
    }
}

// ToneEngine remains the same
final class ToneEngine: ObservableObject {
    enum NoiseType { case white, pink }

    private let engine = AVAudioEngine()
    private var sourceNode: AVAudioSourceNode?
    private var sampleRate: Double = 44100
    private var phase: Double = 0
    private var sweepTimer: Timer?

    func playSine(frequency: Double) {
        stop()
        configureSession()
        let format = engine.mainMixerNode.outputFormat(forBus: 0)
        sampleRate = Double(format.sampleRate)
        var freq = frequency
        phase = 0
        let node = AVAudioSourceNode { _, _, frameCount, audioBufferList -> OSStatus in
            let abl = UnsafeMutableAudioBufferListPointer(audioBufferList)
            let omega = 2.0 * Double.pi * freq / self.sampleRate
            for frame in 0..<Int(frameCount) {
                let sample = Float(sin(self.phase))
                self.phase += omega
                if self.phase > 2.0 * Double.pi { self.phase -= 2.0 * Double.pi }
                for buffer in abl {
                    let ptr = buffer.mData!.assumingMemoryBound(to: Float.self)
                    ptr[frame] = sample * 0.2
                }
            }
            return noErr
        }
        connect(node)
        engine.prepare()
        try? engine.start()
        sourceNode = node
    }

    func playSweep(start: Double, end: Double, duration: Double) {
        stop()
        configureSession()
        let format = engine.mainMixerNode.outputFormat(forBus: 0)
        sampleRate = Double(format.sampleRate)
        var t: Double = 0
        let totalSamples = duration * sampleRate
        phase = 0
        let node = AVAudioSourceNode { _, _, frameCount, audioBufferList -> OSStatus in
            let abl = UnsafeMutableAudioBufferListPointer(audioBufferList)
            for frame in 0..<Int(frameCount) {
                let progress = min(1.0, t / totalSamples)
                let freq = start * pow(end / start, progress) // log sweep
                let omega = 2.0 * Double.pi * freq / self.sampleRate
                let sample = Float(sin(self.phase))
                self.phase += omega
                if self.phase > 2.0 * Double.pi { self.phase -= 2.0 * Double.pi }
                for buffer in abl {
                    let ptr = buffer.mData!.assumingMemoryBound(to: Float.self)
                    ptr[frame] = sample * 0.2
                }
                t += 1
            }
            return noErr
        }
        connect(node)
        engine.prepare()
        try? engine.start()
        sourceNode = node
    }

    func playNoise(type: NoiseType) {
        stop()
        configureSession()
        let node = AVAudioSourceNode { _, _, frameCount, audioBufferList -> OSStatus in
            let abl = UnsafeMutableAudioBufferListPointer(audioBufferList)
            var b0: Float = 0, b1: Float = 0, b2: Float = 0, b3: Float = 0, b4: Float = 0, b5: Float = 0, b6: Float = 0
            for frame in 0..<Int(frameCount) {
                let sample: Float
                switch type {
                case .white:
                    sample = Float.random(in: -1...1) * 0.15
                case .pink:
                    let white = Float.random(in: -1...1)
                    b0 = 0.99886 * b0 + white * 0.0555179
                    b1 = 0.99332 * b1 + white * 0.0750759
                    b2 = 0.96900 * b2 + white * 0.1538520
                    b3 = 0.86650 * b3 + white * 0.3104856
                    b4 = 0.55000 * b4 + white * 0.5329522
                    b5 = -0.7616 * b5 - white * 0.0168980
                    let pink = b0 + b1 + b2 + b3 + b4 + b5 + b6 + white * 0.5362
                    b6 = white * 0.115926
                    sample = pink * 0.06
                }
                for buffer in abl {
                    let ptr = buffer.mData!.assumingMemoryBound(to: Float.self)
                    ptr[frame] = sample
                }
            }
            return noErr
        }
        connect(node)
        engine.prepare()
        try? engine.start()
        sourceNode = node
    }

    func stop() {
        if engine.isRunning { engine.stop() }
        if let node = sourceNode { engine.detach(node) }
        sourceNode = nil
        sweepTimer?.invalidate()
        sweepTimer = nil
    }

    private func connect(_ node: AVAudioNode) {
        engine.attach(node)
        let format = engine.mainMixerNode.outputFormat(forBus: 0)
        engine.connect(node, to: engine.mainMixerNode, format: format)
    }

    private func configureSession() {
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.playback, mode: .measurement, options: [])
        try? session.setActive(true)
    }
}