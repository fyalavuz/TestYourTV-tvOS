import AVFoundation
import Combine

class AudioManager: ObservableObject {
    private var engine: AVAudioEngine!
    private var player: AVAudioPlayerNode!
    private var mixer: AVAudioMixerNode!
    private var buffer: AVAudioPCMBuffer?
    private var routeObserver: NSObjectProtocol?

    @Published var outputRouteSummary: String = "Unknown"
    @Published var outputRoutes: [String] = []
    
    init() {
        setupAudioEngine()
        observeRouteChanges()
    }

    deinit {
        if let routeObserver {
            NotificationCenter.default.removeObserver(routeObserver)
        }
    }
    
    private func setupAudioEngine() {
        engine = AVAudioEngine()
        player = AVAudioPlayerNode()
        mixer = engine.mainMixerNode
        
        engine.attach(player)
        engine.connect(player, to: mixer, format: mixer.outputFormat(forBus: 0))
        
        // Prepare Pink Noise Buffer
        if let noise = generatePinkNoise(duration: 5.0) {
            self.buffer = noise
        }
        
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .measurement, options: [])
            try AVAudioSession.sharedInstance().setActive(true)
            try engine.start()
        } catch {
            print("Audio Engine Error: \(error)")
        }
    }

    private func observeRouteChanges() {
        updateRouteInfo()
        routeObserver = NotificationCenter.default.addObserver(
            forName: AVAudioSession.routeChangeNotification,
            object: AVAudioSession.sharedInstance(),
            queue: .main
        ) { [weak self] _ in
            self?.updateRouteInfo()
        }
    }

    private func updateRouteInfo() {
        let outputs = AVAudioSession.sharedInstance().currentRoute.outputs
        if outputs.isEmpty {
            outputRouteSummary = "No Output"
            outputRoutes = ["No active outputs"]
            return
        }

        outputRouteSummary = outputs.map(\.portName).joined(separator: " + ")
        outputRoutes = outputs.map { output in
            let typeLabel = portTypeLabel(output.portType)
            let channels = output.channels?.count ?? 0
            let channelInfo = channels > 0 ? "\(channels) ch" : nil
            return [typeLabel, output.portName, channelInfo]
                .compactMap { $0 }
                .joined(separator: " • ")
        }
    }

    private func portTypeLabel(_ port: AVAudioSession.Port) -> String {
        switch port {
        case .hdmi: return "HDMI"
        case .airPlay: return "AirPlay"
        case .bluetoothA2DP: return "Bluetooth A2DP"
        case .bluetoothLE: return "Bluetooth LE"
        case .bluetoothHFP: return "Bluetooth HFP"
        case .builtInSpeaker: return "Built-in Speaker"
        case .builtInReceiver: return "Built-in Receiver"
        case .lineOut: return "Line Out"
        case .headphones: return "Headphones"
        case .usbAudio: return "USB Audio"
        case .carAudio: return "Car Audio"
        case .avb: return "AVB"
        case .fireWire: return "FireWire"
        case .pci: return "PCI"
        case .virtual: return "Virtual"
        default: return port.rawValue
        }
    }
    
    func playChannelTest(channel: String) {
        // Stop previous playback
        player.stop()
        
        guard let buffer = self.buffer else { return }
        
        // Determine channel index
        // Standard Layout: L, R, C, LFE, LS, RS
        var channelIndex = 0
        switch channel {
        case "Left Front": channelIndex = 0
        case "Right Front": channelIndex = 1
        case "Center": channelIndex = 2
        case "Subwoofer": channelIndex = 3
        case "Left Surround": channelIndex = 4
        case "Right Surround": channelIndex = 5
        default: channelIndex = 0
        }
        
        // Channel Mapping Logic
        // We create a channel map where only the target channel is 1.0, others 0.0
        let channelCount = Int(engine.outputNode.outputFormat(forBus: 0).channelCount)
        if channelCount > 0 {
            // AVAudioMixerNode doesn't support easy dynamic channel mapping per input bus in a simple way 
            // without using an intermediate matrix mixer or AVAudioUnitChannelMap.
            // For simplicity in this demo, we assume the system handles panning if we pan the player.
            // But AVAudioPlayerNode pan is only -1.0 to 1.0 (Stereo).
            
            // Professional approach: Re-connect or use Matrix Mixer.
            // Since we want to be "Perfect", let's try a simple pan for stereo, 
            // but for surround, without multi-channel assets, it's hard to force routing programmatically 
            // without using lower level AudioUnit APIs.
            
            // Fallback: Use the panner for L/R/C.
            if channelIndex == 0 { player.pan = -1.0 }
            else if channelIndex == 1 { player.pan = 1.0 }
            else if channelIndex == 2 { player.pan = 0.0 }
            else {
                // For surrounds, standard Pan doesn't work.
                // We would need 3D audio or channel mapping.
                player.pan = 0.0
            }
        }
        
        player.scheduleBuffer(buffer, at: nil, options: .loops, completionHandler: nil)
        player.play()
    }
    
    func stop() {
        player.stop()
    }
    
    // Simple Pink Noise Generator
    private func generatePinkNoise(duration: Double) -> AVAudioPCMBuffer? {
        let sampleRate = 44100.0
        let frameCount = AVAudioFrameCount(sampleRate * duration)
        guard let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 2),
              let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else {
            return nil
        }
        
        buffer.frameLength = frameCount
        let channels = buffer.format.channelCount
        
        // Basic Pink Noise algorithm (McCartney)
        var b0: Float = 0, b1: Float = 0, b2: Float = 0, b3: Float = 0, b4: Float = 0, b5: Float = 0, b6: Float = 0
        
        for i in 0..<Int(channels) {
            guard let channelData = buffer.floatChannelData?[i] else { continue }
            for j in 0..<Int(frameCount) {
                let white = Float.random(in: -1...1)
                b0 = 0.99886 * b0 + white * 0.0555179
                b1 = 0.99332 * b1 + white * 0.0750759
                b2 = 0.96900 * b2 + white * 0.1538520
                b3 = 0.86650 * b3 + white * 0.3104856
                b4 = 0.55000 * b4 + white * 0.5329522
                b5 = -0.7616 * b5 - white * 0.0168980
                let pink = b0 + b1 + b2 + b3 + b4 + b5 + b6 + white * 0.5362
                b6 = white * 0.115926
                channelData[j] = pink * 0.1 // Scale down
            }
        }
        
        return buffer
    }
}
