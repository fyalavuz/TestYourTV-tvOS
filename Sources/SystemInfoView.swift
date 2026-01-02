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
                VStack(alignment: .leading, spacing: 24) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("System Debug")
                            .font(.system(size: 52, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)

                        Text("Device, display, network, and locale diagnostics.")
                            .font(.headline)
                            .foregroundStyle(.white.opacity(0.7))
                    }

                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 260), spacing: 18)], spacing: 18) {
                        SystemInfoTile(title: "Device", value: deviceMonitor.deviceModel)
                        SystemInfoTile(title: "tvOS", value: "\(deviceMonitor.systemName) \(deviceMonitor.systemVersion)")
                        SystemInfoTile(title: "Resolution", value: deviceMonitor.resolution)
                        SystemInfoTile(title: "HDR", value: deviceMonitor.hdrStatus)
                        SystemInfoTile(title: "Network", value: networkMonitor.statusText)
                        SystemInfoTile(title: "Locale", value: localeSummary)
                        SystemInfoTile(title: "Time Zone", value: timeZoneSummary)
                        SystemInfoTile(title: "Audio Route", value: audioMonitor.outputSummary)
                    }

                    VStack(alignment: .leading, spacing: 16) {
                        Divider().overlay(Color.white.opacity(0.2))

                        Text("Device")
                            .font(.headline)
                            .foregroundStyle(.white)
                        InfoRow(title: "Name", value: deviceMonitor.deviceName)
                        InfoRow(title: "Model", value: deviceMonitor.deviceModel)
                        InfoRow(title: "tvOS", value: "\(deviceMonitor.systemName) \(deviceMonitor.systemVersion)")
                        InfoRow(title: "Resolution", value: deviceMonitor.resolution)
                        InfoRow(title: "Display", value: deviceMonitor.displayQuality)
                        InfoRow(title: "HDR", value: deviceMonitor.hdrStatus)

                        Divider().overlay(Color.white.opacity(0.2))

                        Text("Locale & Time")
                            .font(.headline)
                            .foregroundStyle(.white)
                        InfoRow(title: "Locale", value: localeSummary)
                        InfoRow(title: "Preferred Language", value: preferredLanguage)
                        InfoRow(title: "Time Zone", value: timeZoneSummary)
                        InfoRow(title: "Local Time", value: localTimeString)

                        Divider().overlay(Color.white.opacity(0.2))

                        Text("Network")
                            .font(.headline)
                            .foregroundStyle(.white)
                        InfoRow(title: "Status", value: networkMonitor.statusText)
                        InfoRow(title: "Interface", value: networkMonitor.interfaceText)
                        InfoRow(title: "Constrained", value: networkMonitor.isConstrained ? "Yes" : "No")
                        InfoRow(title: "Expensive", value: networkMonitor.isExpensive ? "Yes" : "No")

                        Divider().overlay(Color.white.opacity(0.2))

                        Text("Audio Route")
                            .font(.headline)
                            .foregroundStyle(.white)
                        InfoRow(title: "Summary", value: audioMonitor.outputSummary)
                        ForEach(audioMonitor.outputDetails.indices, id: \.self) { index in
                            InfoRow(title: "Output \(index + 1)", value: audioMonitor.outputDetails[index])
                        }
                    }
                }
                .padding(.top, 40)
                .padding(.horizontal, 80)
                .padding(.bottom, 80)
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

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title.uppercased())
                .font(.caption2.weight(.bold))
                .foregroundStyle(.secondary)
            Text(value)
                .font(.headline.weight(.semibold))
                .foregroundStyle(.white)
                .lineLimit(2)
                .minimumScaleFactor(0.8)
                .allowsTightening(true)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.white.opacity(0.08))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.white.opacity(0.12), lineWidth: 1)
        )
    }
}

private struct InfoRow: View {
    let title: String
    let value: String

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 10) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)

            Spacer(minLength: 0)

            Text(value)
                .font(.callout.weight(.semibold))
                .foregroundStyle(.white)
                .lineLimit(1)
                .truncationMode(.tail)
                .minimumScaleFactor(0.8)
                .allowsTightening(true)
        }
    }
}

#Preview {
    SystemInfoView()
}
