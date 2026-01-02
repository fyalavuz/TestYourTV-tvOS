import AVFoundation
import AVKit
import SwiftUI
import UIKit

enum VideoCatalogMode {
    case reference
    case technical

    var title: String {
        switch self {
        case .reference:
            return "Reference Videos"
        case .technical:
            return "Technical Tests"
        }
    }

    var subtitle: String {
        switch self {
        case .reference:
            return "High-quality samples grouped by provider."
        case .technical:
            return "Instrumented clips for motion, HDR, and resolution checks."
        }
    }
}

struct VideoTestsView: View {
    let mode: VideoCatalogMode
    @StateObject private var loader = VideoCatalogLoader()

    init(mode: VideoCatalogMode = .reference) {
        self.mode = mode
    }

    var body: some View {
        ZStack {
            AmbientBackground()

            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 40) {
                    VStack(alignment: .leading, spacing: 10) {
                        Text(mode.title)
                            .font(.system(size: 52, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                        Text(mode.subtitle)
                            .font(.title3)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.top, 40)
                    .padding(.horizontal, 80)

                    if loader.isLoading {
                        ProgressView()
                            .scaleEffect(1.4)
                            .padding(.horizontal, 80)
                    } else {
                        ForEach(loader.categories) { category in
                            VStack(alignment: .leading, spacing: 20) {
                                if !(mode == .technical && loader.categories.count == 1 && category.title == mode.title) {
                                    Text(category.title)
                                        .font(.title2.weight(.bold))
                                        .foregroundStyle(.white)
                                        .padding(.horizontal, 80)
                                }

                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 32) {
                                        Spacer().frame(width: 40)

                                        ForEach(category.clips) { clip in
                                            VStack(alignment: .leading, spacing: 10) {
                                                NavigationLink(destination: VideoPlayerQuickView(clip: clip)) {
                                                    VideoClipThumbnail(clip: clip)
                                                }
                                                .buttonStyle(.card)
                                                
                                                VideoClipMeta(clip: clip, showsSubtitle: mode == .technical)
                                                    .frame(width: 440, alignment: .leading)
                                                    .allowsHitTesting(false)
                                            }
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
            loader.load(mode: mode)
        }
    }
}

struct VideoPlayerQuickView: View {
    let clip: VideoClip
    @StateObject private var playerModel = VideoQueuePlayerModel()
    @State private var selectedVariant: VideoVariant?

    var body: some View {
        ZStack {
            if let variant = selectedVariant {
                NativeVideoPlayer(player: playerModel.player, appliesDisplayCriteriaAutomatically: true)
                    .ignoresSafeArea()
                    .onAppear {
                        playerModel.play(variants: [variant], applyDisplayCriteria: true)
                    }
            } else {
                ProgressView()
            }
        }
        .onAppear {
            if selectedVariant == nil {
                selectedVariant = clip.variants.first
            }
        }
        .onDisappear {
            playerModel.stop()
        }
    }
}

private struct VideoClipThumbnail: View {
    let clip: VideoClip

    var body: some View {
        ZStack {
            AsyncImage(url: clip.thumbnailURL) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFill()
                default:
                    ZStack {
                        LinearGradient(colors: clip.palette, startPoint: .topLeading, endPoint: .bottomTrailing)
                        Image(systemName: "play.circle.fill")
                            .font(.system(size: 48))
                            .foregroundStyle(.white.opacity(0.8))
                    }
                }
            }
            .frame(width: 440, height: 240)
            .clipped()
            .cornerRadius(24)
        }
    }
}

private struct VideoClipMeta: View {
    let clip: VideoClip
    let showsSubtitle: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(clip.displayName)
                .font(.headline.weight(.bold))
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            if showsSubtitle {
                Text(clip.subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
        }
        .padding(.horizontal, 6)
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

    func updateUIViewController(_ controller: AVPlayerViewController, context: Context) {}
}

final class VideoQueuePlayerModel: ObservableObject {
    let player = AVQueuePlayer()

    func play(variants: [VideoVariant], applyDisplayCriteria: Bool) {
        player.removeAllItems()
        guard let first = variants.first else { return }
        let item = AVPlayerItem(url: first.url)
        player.insert(item, after: nil)
        player.play()
    }

    func stop() {
        player.pause()
        player.removeAllItems()
    }
}

final class VideoCatalogLoader: ObservableObject {
    @Published var categories: [VideoCategory] = []
    @Published var isLoading = false

    func load(mode: VideoCatalogMode) {
        isLoading = true
        let allVideos = [
            (
                "Big Buck Bunny (Trailer)",
                "Blender Open Movie",
                "Short-form animation with dense texture detail and fast motion.",
                "https://peach.blender.org/wp-content/uploads/title_anouncement.jpg",
                "https://download.blender.org/peach/trailer/trailer_720p.mov"
            ),
            (
                "Sintel (Trailer)",
                "Blender Open Movie",
                "Cinematic lighting, skin tones, and smoke-heavy grading.",
                "https://durian.blender.org/wp-content/uploads/2011/02/4-DVD-verti-feb2011.jpg",
                "https://download.blender.org/durian/trailer/sintel_trailer-720p.mp4"
            ),
            (
                "Elephants Dream",
                "Blender Open Movie",
                "High-contrast scenes for shadow and color separation checks.",
                "https://download.blender.org/ED/cover.jpg",
                "https://download.blender.org/ED/elephantsdream-720-h264-st-aac.mov"
            ),
            (
                "Tears of Steel",
                "Blender Open Movie",
                "Live-action + CG blend for sharpness and mixed lighting.",
                "https://mango.blender.org/wp-content/uploads/2013/06/12_scients_header.jpg",
                "https://download.blender.org/demo/movies/ToS/tears_of_steel_720p.mov"
            )
        ]
        
        let clips = allVideos.map { title, subtitle, desc, thumb, file in
            VideoClip(
                id: file,
                displayName: title,
                subtitle: subtitle,
                summary: desc,
                thumbnailURL: URL(string: thumb)!,
                variants: [VideoVariant(id: file, url: URL(string: file)!)]
            )
        }
        
        switch mode {
        case .reference:
            // Group by provider (subtitle)
            let grouped = Dictionary(grouping: clips, by: { $0.subtitle })
            
            // Create categories from groups, sorted by provider name
            let providerCategories = grouped.map { provider, clips in
                let providerName = provider.hasPrefix("By ") ? String(provider.dropFirst(3)) : provider
                return VideoCategory(id: provider, title: providerName, clips: clips.sorted { $0.displayName < $1.displayName })
            }.sorted { $0.title < $1.title }
            
            self.categories = providerCategories
        case .technical:
            let techVideos = [
                ("Big Buck Bunny (H.264)", "1080p 60fps", "High frame rate test.", "https://avtshare01.rz.tu-ilmenau.de/avt-vqdb-uhd-1/test_1/segments/bigbuck_bunny_8bit_7500kbps_1080p_60.0fps_hevc.mp4"),
                ("Water Netflix", "1080p 59.94fps", "Fluid motion test.", "https://avtshare01.rz.tu-ilmenau.de/avt-vqdb-uhd-1/test_1/segments/water_netflix_7500kbps_1080p_59.94fps_hevc.mp4"),
                ("Dancers", "1080p 60fps", "Complex motion test.", "https://avtshare01.rz.tu-ilmenau.de/avt-vqdb-uhd-1/test_2/segments/Dancers_8s_10244kbps_1080p_60.0fps_hevc.mp4"),
                ("Daydreamer (SDR)", "1440p 60fps", "Resolution test.", "https://avtshare01.rz.tu-ilmenau.de/avt-vqdb-uhd-1/test_4/segments/Daydreamer_SDR_8s_3840x2160_8_6000kbps_1440p_60.0fps_hevc.mp4"),
                ("Giftmord (SDR)", "1440p 60fps", "Dark scene test.", "https://avtshare01.rz.tu-ilmenau.de/avt-vqdb-uhd-1/test_4/segments/Giftmord-SDR_8s_11_3840x2160_6000kbps_1440p_60.0fps_hevc.mp4"),
                ("Sparks", "1440p 59.94fps", "Particle effect test.", "https://avtshare01.rz.tu-ilmenau.de/avt-vqdb-uhd-1/test_4/segments/Sparks_cut_13_6000kbps_1440p_59.94fps_hevc.mp4")
            ]
            
            let techClips = techVideos.map { title, subtitle, desc, url in
                VideoClip(
                    id: url,
                    displayName: title,
                    subtitle: subtitle,
                    summary: desc,
                    thumbnailURL: URL(string: "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/images/BigBuckBunny.jpg")!,
                    variants: [VideoVariant(id: url, url: URL(string: url)!)]
                )
            }
            
            self.categories = [VideoCategory(id: "technical", title: "Technical Tests", clips: techClips)]
        }
        self.isLoading = false
    }
}

struct VideoCategory: Identifiable {
    let id: String
    let title: String
    let clips: [VideoClip]
}

struct VideoClip: Identifiable {
    let id: String
    let displayName: String
    let subtitle: String
    let summary: String
    let thumbnailURL: URL
    let variants: [VideoVariant]
    
    var palette: [Color] {
        [.blue, .purple]
    }
}

struct VideoVariant: Identifiable {
    let id: String
    let url: URL
}

private extension AVAsset {
    func asURLString() -> String? {
        (self as? AVURLAsset)?.url.absoluteString
    }
}

#Preview {
    VideoTestsView()
}
