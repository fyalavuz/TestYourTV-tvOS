import SwiftUI
import Network
import AVFoundation
import Combine

struct SystemInfoView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var deviceMonitor = DeviceMonitor()
    @StateObject private var networkMonitor = NetworkMonitor()
    @StateObject private var audioMonitor = AudioRouteMonitor()

    var body: some View {
        ZStack {
            AmbientBackground()

            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 40) {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("System Information")
                            .font(.system(size: 52, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)

                        Text("Device, display, network, and locale diagnostics.")
                            .font(.title3)
                            .foregroundStyle(.white.opacity(0.7))
                    }
                    .padding(.top, 40)
                    .padding(.horizontal, 80)

                    // Summary Grid
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 300), spacing: 24)], spacing: 24) {
                        SystemInfoTile(title: "Device", value: deviceMonitor.deviceModel, icon: "tv")
                        SystemInfoTile(title: "tvOS", value: "\(deviceMonitor.systemName) \(deviceMonitor.systemVersion)", icon: "applelogo")
                        SystemInfoTile(title: "Resolution", value: deviceMonitor.resolution, icon: "display")
                        SystemInfoTile(title: "HDR", value: deviceMonitor.hdrStatus, icon: "sun.max")
                        SystemInfoTile(title: "Network", value: networkMonitor.statusText, icon: "network")
                        SystemInfoTile(title: "Locale", value: localeSummary, icon: "globe")
                        SystemInfoTile(title: "Time Zone", value: timeZoneSummary, icon: "clock")
                        SystemInfoTile(title: "Audio Route", value: audioMonitor.outputSummary, icon: "hifispeaker")
                    }
                    .padding(.horizontal, 80)

                    // Detailed Lists
                    VStack(spacing: 40) {
                        DetailSection(title: "Device", icon: "cpu") {
                            InfoRow(title: "Name", value: deviceMonitor.deviceName)
                            InfoRow(title: "Model", value: deviceMonitor.deviceModel)
                            InfoRow(title: "tvOS Version", value: "\(deviceMonitor.systemName) \(deviceMonitor.systemVersion)")
                            InfoRow(title: "Screen Resolution", value: deviceMonitor.resolution)
                            InfoRow(title: "Display Quality", value: deviceMonitor.displayQuality)
                            InfoRow(title: "HDR Capability", value: deviceMonitor.hdrStatus)
                        }

                        DetailSection(title: "Locale & Time", icon: "globe") {
                            InfoRow(title: "Locale Identifier", value: localeSummary)
                            InfoRow(title: "Language", value: preferredLanguage)
                            InfoRow(title: "Time Zone", value: timeZoneSummary)
                            InfoRow(title: "Local Time", value: localTimeString)
                        }

                        DetailSection(title: "Network", icon: "network") {
                            InfoRow(title: "Status", value: networkMonitor.statusText)
                            InfoRow(title: "Interface Type", value: networkMonitor.interfaceText)
                            InfoRow(title: "Low Data Mode", value: networkMonitor.isConstrained ? "Yes" : "No")
                            InfoRow(title: "Expensive (Hotspot)", value: networkMonitor.isExpensive ? "Yes" : "No")
                        }

                        DetailSection(title: "Audio System", icon: "hifispeaker.2") {
                            InfoRow(title: "Active Output", value: audioMonitor.outputSummary)
                            ForEach(audioMonitor.outputDetails.indices, id: \.self) { index in
                                InfoRow(title: "Output Device \(index + 1)", value: audioMonitor.outputDetails[index])
                            }
                        }
                    }
                    .padding(.horizontal, 80)
                    .padding(.bottom, 80)
                }
            }
        }
        .toolbar(.hidden, for: .navigationBar)
    }

    private var localeSummary: String {
        let locale = Locale.current
        let region = locale.region?.identifier ?? ""
        let id = locale.identifier
        if region.isEmpty {
            return id
        }
        return "\(id) (\(region))"
    }

    private var preferredLanguage: String {
        Locale.preferredLanguages.first ?? "Unknown"
    }

    private var timeZoneSummary: String {
        let zone = TimeZone.current
        let seconds = zone.secondsFromGMT()
        let hours = seconds / 3600
        let minutes = abs(seconds / 60) % 60
        let sign = hours >= 0 ? "+" : "-"
        return "\(zone.identifier) (GMT\(sign)\(abs(hours)):\(String(format: "%02d", minutes)))"
    }

    private var localTimeString: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .medium
        formatter.timeZone = TimeZone.current
        return formatter.string(from: Date())
    }
}

// Monitors remain same (omitted for brevity, assume they are available or I need to include them?) 
// Since I overwrite the file, I MUST include them. I will copy them from previous read.

final class NetworkMonitor: ObservableObject {
    @Published var statusText: String = "Unknown"
    @Published var interfaceText: String = "Unknown"
    @Published var isExpensive: Bool = false
    @Published var isConstrained: Bool = false

    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "NetworkMonitorQueue")

    init() {
        monitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                self?.update(path)
            }
        }
        monitor.start(queue: queue)
    }

    deinit {
        monitor.cancel()
    }

    private func update(_ path: NWPath) {
        statusText = path.status == .satisfied ? "Connected" : "Disconnected"
        interfaceText = interfaceDescription(for: path)
        isExpensive = path.isExpensive
        isConstrained = path.isConstrained
    }

    private func interfaceDescription(for path: NWPath) -> String {
        var types: [String] = []
        if path.usesInterfaceType(.wifi) { types.append("Wi-Fi") }
        if path.usesInterfaceType(.wiredEthernet) { types.append("Ethernet") }
        if path.usesInterfaceType(.cellular) { types.append("Cellular") }
        if path.usesInterfaceType(.loopback) { types.append("Loopback") }
        return types.isEmpty ? "Unknown" : types.joined(separator: " + ")
    }
}

final class AudioRouteMonitor: ObservableObject {
    @Published var outputSummary: String = "Unknown"
    @Published var outputDetails: [String] = []

    private var observer: NSObjectProtocol?

    init() {
        updateRouteInfo()
        observer = NotificationCenter.default.addObserver(
            forName: AVAudioSession.routeChangeNotification,
            object: AVAudioSession.sharedInstance(),
            queue: .main
        ) { [weak self] _ in
            self?.updateRouteInfo()
        }
    }

    deinit {
        if let observer {
            NotificationCenter.default.removeObserver(observer)
        }
    }

    private func updateRouteInfo() {
        let outputs = AVAudioSession.sharedInstance().currentRoute.outputs
        if outputs.isEmpty {
            outputSummary = "No Output"
            outputDetails = ["No active outputs"]
            return
        }

        outputSummary = outputs.map(\.portName).joined(separator: " + ")
        outputDetails = outputs.map { output in
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
        #if !os(tvOS)
        case .hdmi: return "HDMI"
        case .avb: return "AVB"
        case .pci: return "PCI"
        #endif
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
        case .fireWire: return "FireWire"
        case .virtual: return "Virtual"
        default: return port.rawValue
        }
    }
}

private struct SystemInfoTile: View {
    let title: String
    let value: String
    let icon: String

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundStyle(.secondary)
                Text(title.uppercased())
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(.secondary)
            }
            
            Text(value)
                .font(.headline.weight(.semibold))
                .foregroundStyle(.white)
                .lineLimit(3)
                .minimumScaleFactor(0.8)
                .allowsTightening(true)
                .fixedSize(horizontal: false, vertical: true) // Allow expansion
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassSurface(cornerRadius: 20, strokeOpacity: 0.12)
    }
}

private struct DetailSection<Content: View>: View {
    let title: String
    let icon: String
    let content: Content
    
    init(title: String, icon: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.icon = icon
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(.white)
                Text(title)
                    .font(.title3.weight(.bold))
                    .foregroundStyle(.white)
            }
            .padding(.bottom, 8)
            
            VStack(spacing: 12) {
                content
            }
            .padding(24)
            .glassSurface(cornerRadius: 24, strokeOpacity: 0.1)
        }
    }
}

private struct InfoRow: View {
    let title: String
    let value: String

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 10) {
            Text(title)
                .font(.callout.weight(.medium))
                .foregroundStyle(.secondary)
                .frame(width: 180, alignment: .leading)

            Text(value)
                .font(.callout.weight(.semibold))
                .foregroundStyle(.white)
                .multilineTextAlignment(.leading)
            
            Spacer()
        }
    }
}

#Preview {
    SystemInfoView()
}