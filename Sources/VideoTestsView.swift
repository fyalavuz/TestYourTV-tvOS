import AVFoundation
import AVKit
import SwiftUI
import UIKit

struct VideoTestsView: View {
    @StateObject private var loader = VideoCatalogLoader()

    var body: some View {
        ZStack {
            AmbientBackground()

            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 40) {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Reference Videos")
                            .font(.largeTitle.weight(.bold))
                            .foregroundStyle(.white)
                        Text("Reference clips for motion, compression, resolution and HDR checks.")
                            .font(.callout)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.top, 40)
                    .padding(.horizontal, 80)

                    if loader.isLoading {
                        ProgressView()
                            .scaleEffect(1.4)
                            .padding(.horizontal, 80)
                    } else if loader.categories.isEmpty {
                        if let error = loader.errorMessage {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Unable to load video catalog.")
                                    .font(.title3.weight(.semibold))
                                    .foregroundStyle(.white)
                                Text(error)
                                    .font(.callout)
                                    .foregroundStyle(.secondary)
                                Button("Retry") {
                                    loader.load(force: true)
                                }
                                .buttonStyle(.borderedProminent)
                            }
                            .padding(.horizontal, 80)
                        } else {
                            Text("No videos available.")
                                .font(.callout)
                                .foregroundStyle(.secondary)
                                .padding(.horizontal, 80)
                        }
                    } else {
                        if let error = loader.errorMessage {
                            Text("Catalog offline, showing fallback list.")
                                .font(.callout)
                                .foregroundStyle(.secondary)
                                .padding(.horizontal, 80)
                        }
                        ForEach(loader.categories) { category in
                            VStack(alignment: .leading, spacing: 20) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(category.title)
                                        .font(.title2.weight(.bold))
                                        .foregroundStyle(.white)
                                        .padding(.horizontal, 80)

                                    if let subtitle = category.subtitle {
                                        Text(subtitle)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                            .padding(.horizontal, 80)
                                    }
                                }

                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 32) {
                                        Spacer().frame(width: 40)

                                        ForEach(category.clips) { clip in
                                            NavigationLink(destination: VideoPlayerQuickView(clip: clip)) {
                                                VideoClipCard(clip: clip)
                                            }
                                            .buttonStyle(.card)
                                        }

                                        Spacer().frame(width: 80)
                                    }
                                }
                                .scrollClipDisabled()
                            }
                        }
                    }
                }
                .padding(.bottom, 80)
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .onAppear {
            loader.load(force: false)
        }
    }
}

struct VideoClipDetailView: View {
    let clip: VideoClip
    var body: some View { VideoPlayerQuickView(clip: clip) }
}

struct VideoPlayerQuickView: View {
    let clip: VideoClip

    @StateObject private var playerModel = VideoQueuePlayerModel()
    @State private var matchDisplayMode = true
    @Environment(\.presentationMode) private var presentationMode

    var body: some View {
        ZStack {
            NativeVideoPlayer(player: playerModel.player, appliesDisplayCriteriaAutomatically: matchDisplayMode)
                .ignoresSafeArea()

            VStack(spacing: 8) {
                Spacer()

                VStack(spacing: 8) {
                    Text(clip.displayName)
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(.white)
                        .shadow(color: .black.opacity(0.7), radius: 2, x: 0, y: 0)

                    Toggle(isOn: $matchDisplayMode) {
                        Text("Match display criteria")
                            .font(.callout.weight(.semibold))
                            .foregroundStyle(.white)
                    }
                    .toggleStyle(GlassCheckboxToggleStyle())
                    .onChange(of: matchDisplayMode) { newValue in
                        if newValue {
                            // Try to match currently playing item to a variant
                            let currentURL = (playerModel.player.items().first?.asset as? AVURLAsset)?.url
                            let currentVariant = clip.variants.first { $0.url == currentURL }
                            playerModel.applyDisplayCriteria(for: currentVariant)
                        } else {
                            playerModel.clearDisplayCriteria()
                        }
                    }

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(clip.variants) { variant in
                                VariantRow(
                                    variant: variant,
                                    isSelected: playerModel.player.items().first?.asset.asURLString() == variant.url.absoluteString
                                ) {
                                    playerModel.play(variants: [variant], applyDisplayCriteria: matchDisplayMode)
                                }
                            }
                        }
                        .padding(.horizontal, 12)
                    }

                    Button("Close") {
                        presentationMode.wrappedValue.dismiss()
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding()
                .background(.ultraThinMaterial)
                .cornerRadius(16)
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
            }
        }
        .onAppear {
            if let first = clip.variants.first {
                playerModel.play(variants: [first], applyDisplayCriteria: matchDisplayMode)
            }
        }
        .onDisappear {
            playerModel.stop()
            playerModel.clearDisplayCriteria()
        }
    }
}

private extension AVAsset {
    func asURLString() -> String? {
        if let urlAsset = self as? AVURLAsset {
            return urlAsset.url.absoluteString
        }
        return nil
    }
}

private struct FilterScroll<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                content
            }
            .padding(.vertical, 4)
        }
    }
}

private struct VideoClipCard: View {
    let clip: VideoClip

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ZStack(alignment: .bottomLeading) {
                if let thumbnailURL = thumbnailURL(for: clip) {
                    AsyncImage(url: thumbnailURL) { phase in
                        switch phase {
                        case .empty:
                            Rectangle()
                                .fill(Color.gray.opacity(0.3))
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFill()
                        case .failure:
                            Rectangle()
                                .fill(Color.gray.opacity(0.3))
                        @unknown default:
                            Rectangle()
                                .fill(Color.gray.opacity(0.3))
                        }
                    }
                    .frame(width: 360, height: 200)
                    .clipped()
                    .cornerRadius(20)
                } else {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 360, height: 200)
                        .cornerRadius(20)
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text(clip.displayName)
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(.white)
                        .lineLimit(2)
                        .shadow(color: .black.opacity(0.7), radius: 2, x: 0, y: 0)
                    Text(clip.summary)
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.7))
                        .shadow(color: .black.opacity(0.7), radius: 1, x: 0, y: 0)
                }
                .padding(14)
            }
            .frame(width: 360, height: 200)
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        }
    }
}

private func thumbnailURL(for clip: VideoClip) -> URL? {
    guard let first = clip.variants.first else { return nil }
    let mp4 = first.url.absoluteString
    let thumb = mp4.replacingOccurrences(of: ".mp4", with: ".jpg")
    return URL(string: thumb)
}

private struct VariantRow: View {
    let variant: VideoVariant
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: isSelected ? "play.circle.fill" : "play.circle")
                    .foregroundStyle(isSelected ? .white : .white.opacity(0.7))

                Text(variant.label)
                    .font(.caption)
                    .foregroundStyle(.white)
                    .lineLimit(2)

                Spacer(minLength: 0)
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(isSelected ? Color.white.opacity(0.25) : Color.white.opacity(0.08))
            )
        }
        .buttonStyle(.glassFocus(cornerRadius: 12))
    }
}

private struct DisplayStatusRow: View {
    let title: String
    let value: String

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 10) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)

            Spacer(minLength: 0)

            Text(value)
                .font(.callout.weight(.semibold))
                .foregroundStyle(.white)
        }
    }
}

private struct NativeVideoPlayer: UIViewControllerRepresentable {
    let player: AVQueuePlayer
    let appliesDisplayCriteriaAutomatically: Bool

    func makeUIViewController(context: Context) -> AVPlayerViewController {
        let controller = AVPlayerViewController()
        controller.player = player
        controller.showsPlaybackControls = true
        controller.videoGravity = .resizeAspect
        controller.appliesPreferredDisplayCriteriaAutomatically = appliesDisplayCriteriaAutomatically
        return controller
    }

    func updateUIViewController(_ controller: AVPlayerViewController, context: Context) {
        controller.player = player
        controller.appliesPreferredDisplayCriteriaAutomatically = appliesDisplayCriteriaAutomatically
    }
}

final class VideoQueuePlayerModel: ObservableObject {
    let player = AVQueuePlayer()
    @Published var hasQueue = false

    func play(variants: [VideoVariant], applyDisplayCriteria shouldApplyDisplayCriteria: Bool) {
        player.removeAllItems()
        guard !variants.isEmpty else {
            hasQueue = false
#if os(iOS)
            UIApplication.shared.isIdleTimerDisabled = false
#endif
            return
        }
        if shouldApplyDisplayCriteria {
            applyDisplayCriteria(for: variants.first)
        } else {
            clearDisplayCriteria()
        }
        let items = variants.compactMap { AVPlayerItem(url: $0.url) }
        items.forEach { player.insert($0, after: nil) }
        hasQueue = true
        player.play()
#if os(iOS)
        UIApplication.shared.isIdleTimerDisabled = true
#endif
    }

    func stop() {
        player.pause()
        player.removeAllItems()
        hasQueue = false
#if os(iOS)
        UIApplication.shared.isIdleTimerDisabled = false
#endif
    }

    func applyDisplayCriteria(for variant: VideoVariant?) {
        guard let variant else { return }
        guard let displayManager = Self.activeDisplayManager() else { return }

        let asset = AVURLAsset(url: variant.url)
        asset.loadValuesAsynchronously(forKeys: ["tracks"]) {
            var error: NSError?
            let status = asset.statusOfValue(forKey: "tracks", error: &error)
            guard status == .loaded else { return }

            let track = asset.tracks(withMediaType: .video).first
            let formatDescription = track?.formatDescriptions.first.map { $0 as! CMFormatDescription }
            let refreshRate = Float(variant.fps ?? Double(track?.nominalFrameRate ?? 0))

            var criteria: AVDisplayCriteria?
            if let formatDescription, refreshRate > 0, #available(tvOS 17.0, *) {
                criteria = AVDisplayCriteria(refreshRate: refreshRate, formatDescription: formatDescription)
            } else {
                criteria = asset.preferredDisplayCriteria
            }

            DispatchQueue.main.async {
                displayManager.preferredDisplayCriteria = criteria
            }
        }
    }

    func clearDisplayCriteria() {
        Self.activeDisplayManager()?.preferredDisplayCriteria = nil
    }

    static func activeDisplayManager() -> AVDisplayManager? {
        #if os(iOS)
        let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
        let windows = scenes.flatMap { $0.windows }
        let window = windows.first(where: { $0.isKeyWindow }) ?? windows.first
        return window?.windowScene?.avDisplayManager
        #else
        return nil
        #endif
    }
}

final class VideoCatalogLoader: ObservableObject {
    @Published var categories: [VideoCategory] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let catalogURL = URL(string: "https://telecommunication-telemedia-assessment.github.io/AVT-VQDB-UHD-1/videos.html")!
    private let supportedCodecs: Set<String> = ["h264", "hevc"]

    func load(force: Bool) {
        if !force, !categories.isEmpty { return }
        isLoading = true
        errorMessage = nil

        URLSession.shared.dataTask(with: catalogURL) { data, _, error in
            if let error {
                DispatchQueue.main.async {
                    self.applyFallback(error: error.localizedDescription)
                }
                return
            }
            guard let data, let html = String(data: data, encoding: .utf8) else {
                DispatchQueue.main.async {
                    self.applyFallback(error: "Invalid response")
                }
                return
            }

            let variants = self.parseVariants(from: html)
            let categories = self.buildCategories(from: variants)

            DispatchQueue.main.async {
                if categories.isEmpty {
                    self.applyFallback(error: "No compatible videos found")
                } else {
                    self.categories = categories
                    self.isLoading = false
                }
            }
        }.resume()
    }

    private func applyFallback(error: String) {
        errorMessage = error
        categories = buildCategories(from: fallbackVariants())
        isLoading = false
    }

    private func parseVariants(from html: String) -> [VideoVariant] {
        let pattern = "href=\\\"([^\\\"]+\\.mp4)\\\""
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) else { return [] }

        let matches = regex.matches(in: html, range: NSRange(html.startIndex..., in: html))
        var urls = Set<String>()
        for match in matches {
            guard let range = Range(match.range(at: 1), in: html) else { continue }
            let link = String(html[range])
            if let url = URL(string: link, relativeTo: catalogURL)?.absoluteURL {
                urls.insert(url.absoluteString)
            }
        }

        return urls.compactMap { URL(string: $0) }.compactMap { parseVariant(from: $0) }
    }

    private func parseVariant(from url: URL) -> VideoVariant? {
        let file = url.lastPathComponent
        guard file.lowercased().hasSuffix(".mp4") else { return nil }
        let base = String(file.dropLast(4))
        let tokens = base.split(separator: "_").map(String.init)
        guard !tokens.isEmpty else { return nil }

        let codecToken = tokens.first(where: { ["h264", "hevc", "vp9"].contains($0.lowercased()) })?.lowercased()
        if codecToken == "vp9" {
            return nil
        }
        let codec = codecToken

        let fpsValue = tokens.first(where: { $0.lowercased().hasSuffix("fps") })
            .flatMap { Double($0.dropLast(3)) }

        let resolutionValue = tokens.first(where: { token in
            let lower = token.lowercased()
            guard lower.hasSuffix("p") else { return false }
            guard let value = Int(lower.dropLast()) else { return false }
            return value >= 144
        }).flatMap { Int($0.dropLast()) }

        let bitrateValue = tokens.first(where: { $0.lowercased().hasSuffix("kbps") })
            .flatMap { Int($0.dropLast(4)) }

        let sourceResolution = tokens.first(where: { token in
            let parts = token.split(separator: "x")
            guard parts.count == 2 else { return false }
            return parts.allSatisfy { Int($0) != nil }
        })

        let testSet = url.pathComponents.first(where: { $0.hasPrefix("test_") }) ?? "test"
        let clipKey = clipName(from: tokens)
        let displayName = formatDisplayName(clipKey)

        return VideoVariant(
            id: url.absoluteString,
            url: url,
            clipKey: clipKey,
            displayName: displayName,
            testSet: testSet,
            sourceResolution: sourceResolution,
            resolutionHeight: resolutionValue,
            fps: fpsValue,
            bitrateKbps: bitrateValue,
            codec: codec
        )
    }

    private func clipName(from tokens: [String]) -> String {
        var nameTokens: [String] = []
        for token in tokens {
            if isTechnicalToken(token) {
                break
            }
            nameTokens.append(token)
        }
        if nameTokens.isEmpty {
            return tokens.first ?? "Clip"
        }
        return nameTokens.joined(separator: "_")
    }

    private func isTechnicalToken(_ token: String) -> Bool {
        let lower = token.lowercased()
        if supportedCodecs.contains(lower) || lower == "vp9" { return true }
        if lower == "sdr" || lower == "hdr" || lower == "hlg" || lower == "pq" { return true }
        if lower == "ffvhuff" || lower == "422" || lower == "420" || lower == "444" { return true }
        if lower.hasSuffix("kbps") { return true }
        if lower.hasSuffix("fps") { return true }
        if lower.hasSuffix("bit"), Int(lower.dropLast(3)) != nil { return true }
        if lower.hasSuffix("s"), Int(lower.dropLast()) != nil { return true }
        if lower.hasSuffix("p"), Int(lower.dropLast()) != nil { return true }
        if Int(lower) != nil { return true }
        if lower.contains("x") {
            let parts = lower.split(separator: "x")
            if parts.count == 2, parts.allSatisfy({ Int($0) != nil }) { return true }
        }
        return false
    }

    private func buildCategories(from variants: [VideoVariant]) -> [VideoCategory] {
        let grouped = Dictionary(grouping: variants, by: { $0.testSet })
        let categories = grouped.map { testSet, variants in
            let clipsByName = Dictionary(grouping: variants, by: { $0.clipKey })
            let clips = clipsByName.map { key, variants in
                VideoClip(
                    id: "\(testSet)-\(key)",
                    testSet: testSet,
                    clipKey: key,
                    displayName: formatDisplayName(key),
                    variants: variants
                )
            }
            .sorted { $0.displayName < $1.displayName }
            return VideoCategory(id: testSet, title: formatTestSet(testSet), subtitle: nil, clips: clips)
        }

        return categories.sorted { $0.id < $1.id }
    }

    private func formatTestSet(_ value: String) -> String {
        if value.hasPrefix("test_") {
            let suffix = value.replacingOccurrences(of: "test_", with: "")
            return "Test Set \(suffix)"
        }
        return "Test Set"
    }

    private func formatDisplayName(_ key: String) -> String {
        let spaced = key.replacingOccurrences(of: "_", with: " ").replacingOccurrences(of: "-", with: " ")
        return spaced.split(separator: " ").map { part in
            part.prefix(1).uppercased() + part.dropFirst()
        }.joined(separator: " ")
    }

    private func fallbackVariants() -> [VideoVariant] {
        let urls = [
            "https://avtshare01.rz.tu-ilmenau.de/avt-vqdb-uhd-1/test_1/segments/bigbuck_bunny_8bit_7500kbps_1080p_60.0fps_hevc.mp4",
            "https://avtshare01.rz.tu-ilmenau.de/avt-vqdb-uhd-1/test_1/segments/water_netflix_7500kbps_1080p_59.94fps_hevc.mp4",
            "https://avtshare01.rz.tu-ilmenau.de/avt-vqdb-uhd-1/test_2/segments/Dancers_8s_10244kbps_1080p_60.0fps_hevc.mp4",
            "https://avtshare01.rz.tu-ilmenau.de/avt-vqdb-uhd-1/test_4/segments/Daydreamer_SDR_8s_3840x2160_8_6000kbps_1440p_60.0fps_hevc.mp4",
            "https://avtshare01.rz.tu-ilmenau.de/avt-vqdb-uhd-1/test_4/segments/Giftmord-SDR_8s_11_3840x2160_6000kbps_1440p_60.0fps_hevc.mp4",
            "https://avtshare01.rz.tu-ilmenau.de/avt-vqdb-uhd-1/test_4/segments/Sparks_cut_13_6000kbps_1440p_59.94fps_hevc.mp4"
        ]

        return urls.compactMap { URL(string: $0) }.compactMap { parseVariant(from: $0) }
    }
}

struct VideoCategory: Identifiable {
    let id: String
    let title: String
    let subtitle: String?
    let clips: [VideoClip]
}

struct VideoClip: Identifiable {
    let id: String
    let testSet: String
    let clipKey: String
    let displayName: String
    let variants: [VideoVariant]

    var testSetLabel: String {
        if testSet.hasPrefix("test_") {
            return testSet.replacingOccurrences(of: "test_", with: "")
        }
        return testSet
    }

    var availableResolutions: [Int] {
        sortedUnique(variants.compactMap { $0.resolutionHeight })
    }

    var availableFps: [Double] {
        sortedUnique(variants.compactMap { $0.fps })
    }

    var availableBitrates: [Int] {
        sortedUnique(variants.compactMap { $0.bitrateKbps })
    }

    var availableCodecs: [String] {
        let codecs = variants.compactMap { $0.codec }
        return Array(Set(codecs)).sorted()
    }

    var summary: String {
        let resolution = rangeText(values: availableResolutions, suffix: "p")
        let fps = rangeText(values: availableFps, suffix: "fps")
        let codecs = availableCodecs.map { $0.uppercased() }.joined(separator: ", ")
        return [resolution, fps, codecs].filter { !$0.isEmpty }.joined(separator: " · ")
    }

    var palette: [Color] {
        let hash = stableHash(clipKey)
        let hue = Double(hash % 360) / 360.0
        let altHue = (hue + 0.18).truncatingRemainder(dividingBy: 1.0)
        return [
            Color(hue: hue, saturation: 0.55, brightness: 0.85),
            Color(hue: altHue, saturation: 0.65, brightness: 0.6)
        ]
    }

    private func rangeText<T: Comparable & CustomStringConvertible>(values: [T], suffix: String) -> String {
        guard let first = values.first, let last = values.last else { return "" }
        if first == last {
            return "\(first) \(suffix)"
        }
        return "\(first)-\(last) \(suffix)"
    }
}

struct VideoVariant: Identifiable {
    let id: String
    let url: URL
    let clipKey: String
    let displayName: String
    let testSet: String
    let sourceResolution: String?
    let resolutionHeight: Int?
    let fps: Double?
    let bitrateKbps: Int?
    let codec: String?

    var label: String {
        var parts: [String] = []
        if let resolutionHeight {
            parts.append("\(resolutionHeight)p")
        }
        if let fps {
            if fps.rounded(.down) == fps {
                parts.append(String(format: "%.0f fps", fps))
            } else {
                parts.append(String(format: "%.2f fps", fps))
            }
        }
        if let bitrateKbps {
            parts.append("\(bitrateKbps) kbps")
        }
        if let codec {
            parts.append(codec.uppercased())
        }
        if parts.isEmpty {
            return url.lastPathComponent
        }
        return parts.joined(separator: " · ")
    }
}

private func stableHash(_ input: String) -> Int {
    var hash = 5381
    for scalar in input.unicodeScalars {
        hash = ((hash << 5) &+ hash) &+ Int(scalar.value)
    }
    return abs(hash)
}

private func sortedUnique<T: Comparable & Hashable>(_ values: [T]) -> [T] {
    let unique = Array(Set(values))
    return unique.sorted()
}

#Preview {
    VideoTestsView()
}
