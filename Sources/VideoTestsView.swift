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
                                                // Navigate to Detail View to select quality
                                                NavigationLink(destination: VideoClipDetailView(clip: clip)) {
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

// Cinematic Detail View
struct VideoClipDetailView: View {
    let clip: VideoClip
    @State private var selectedVariant: VideoVariant?

    var body: some View {
        ZStack {
            // Immersive Backdrop
            GeometryReader { proxy in
                AsyncImage(url: clip.thumbnailURL) { phase in
                    if let image = phase.image {
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: proxy.size.width, height: proxy.size.height)
                            .blur(radius: 60)
                            .overlay(Color.black.opacity(0.6))
                    } else {
                        AmbientBackground()
                    }
                }
            }
            .ignoresSafeArea()
            
            HStack(alignment: .top, spacing: 80) {
                // Left: Hero Poster
                AsyncImage(url: clip.thumbnailURL) { phase in
                    if let image = phase.image {
                        image
                            .resizable()
                            .aspectRatio(16/9, contentMode: .fit)
                    } else {
                        ZStack {
                            Color.white.opacity(0.1)
                            ProgressView()
                        }
                        .aspectRatio(16/9, contentMode: .fit)
                    }
                }
                .frame(width: 600)
                .cornerRadius(24)
                .shadow(color: .black.opacity(0.5), radius: 30, y: 15)
                
                // Right: Content & Actions
                VStack(alignment: .leading, spacing: 32) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(clip.displayName)
                            .font(.system(size: 56, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                            .shadow(color: .black.opacity(0.5), radius: 2, y: 2)
                        
                        Text(clip.subtitle)
                            .font(.title3.weight(.medium))
                            .foregroundStyle(.white.opacity(0.7))
                    }
                    
                    Text(clip.summary)
                        .font(.body)
                        .lineSpacing(6)
                        .foregroundStyle(.white.opacity(0.9))
                        .lineLimit(6)
                        .frame(maxWidth: 600, alignment: .leading)
                    
                    VStack(alignment: .leading, spacing: 16) {
                        Text("PLAYBACK QUALITY")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(.white.opacity(0.5))
                            .tracking(1)
                        
                        ScrollView(.vertical, showsIndicators: false) {
                            VStack(spacing: 16) {
                                ForEach(clip.variants) { variant in
                                    NavigationLink(destination: VideoPlayerQuickView(variant: variant)) {
                                        HStack {
                                            Image(systemName: "play.fill")
                                                .font(.headline)
                                            Text(variant.id)
                                                .font(.headline.weight(.semibold))
                                            Spacer()
                                            if variant.isPrimary {
                                                Image(systemName: "star.fill")
                                                    .font(.caption)
                                                    .foregroundStyle(.yellow)
                                            }
                                        }
                                        .padding(.vertical, 18)
                                        .padding(.horizontal, 24)
                                        .background(Color.white.opacity(0.1))
                                        .cornerRadius(14)
                                    }
                                    .buttonStyle(.card)
                                }
                            }
                            .padding(20) // Focus expansion room
                        }
                        .frame(maxHeight: 300)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(80)
        }
    }
}

struct VideoPlayerQuickView: View {
    let variant: VideoVariant
    @StateObject private var playerModel = VideoQueuePlayerModel()

    var body: some View {
        ZStack {
            NativeVideoPlayer(player: playerModel.player, appliesDisplayCriteriaAutomatically: true)
                .ignoresSafeArea()
        }
        .onAppear {
            playerModel.play(variant: variant, applyDisplayCriteria: true)
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

    func play(variant: VideoVariant, applyDisplayCriteria: Bool) {
        player.removeAllItems()
        let item = AVPlayerItem(url: variant.url)
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
        
        let tosBase = "https://ftp.nluug.nl/pub/graphics/blender/demo/movies/ToS/"
        let tosVariants = [
            VideoVariant(id: "4K (3840x2160)", url: URL(string: tosBase + "ToS-4k-1920.mov")!, isPrimary: true),
            VideoVariant(id: "1080p", url: URL(string: tosBase + "tears_of_steel_1080p.mov")!),
            VideoVariant(id: "720p", url: URL(string: tosBase + "tears_of_steel_720p.mov")!)
        ]
        
        let tosClip = VideoClip(
            id: "tears_of_steel",
            displayName: "Tears of Steel",
            subtitle: "By Blender Foundation",
            summary: "Tears of Steel was realized with crowd-funding by users of the open source 3D creation tool Blender. A sci-fi short film about a group of warriors and scientists who gather at the Oude Kerk in Amsterdam to save the world from destructive robots.",
            thumbnailURL: URL(string: "https://mango.blender.org/wp-content/uploads/2013/06/12_scients_header.jpg")!,
            variants: tosVariants
        )

        let bunnyBase = "https://download.blender.org/peach/bigbuckbunny_movies/"
        let bunnyVariants = [
            VideoVariant(id: "1080p 60fps (HEVC)", url: URL(string: "https://avtshare01.rz.tu-ilmenau.de/avt-vqdb-uhd-1/test_1/segments/bigbuck_bunny_8bit_7500kbps_1080p_60.0fps_hevc.mp4")!, isPrimary: true),
            VideoVariant(id: "1080p 30fps (H.264)", url: URL(string: bunnyBase + "big_buck_bunny_1080p_h264.mov")!),
            VideoVariant(id: "720p 30fps (H.264)", url: URL(string: bunnyBase + "big_buck_bunny_720p_h264.mov")!),
            VideoVariant(id: "480p", url: URL(string: bunnyBase + "big_buck_bunny_480p_h264.mov")!)
        ]
        
        let bunnyClip = VideoClip(
            id: "big_buck_bunny",
            displayName: "Big Buck Bunny",
            subtitle: "By Blender Foundation",
            summary: "A giant rabbit with a heart bigger than himself. When three rodents rudely harass him, something snaps... and the rabbit ain't no bunny anymore! A classic open movie project.",
            thumbnailURL: URL(string: "https://peach.blender.org/wp-content/uploads/title_anouncement.jpg")!,
            variants: bunnyVariants
        )
        
        var clips: [VideoClip] = []
        clips.append(bunnyClip)
        clips.append(tosClip)
        
        switch mode {
        case .reference:
            let grouped = Dictionary(grouping: clips, by: { $0.subtitle })
            let providerCategories = grouped.map { provider, clips in
                let providerName = provider.hasPrefix("By ") ? String(provider.dropFirst(3)) : provider
                return VideoCategory(id: provider, title: providerName, clips: clips.sorted { $0.displayName < $1.displayName })
            }.sorted { $0.title < $1.title }
            self.categories = providerCategories
            
        case .technical:
            let techVideos = [
                ("Water Netflix", "1080p 59.94fps", "Fluid motion test.", "https://avtshare01.rz.tu-ilmenau.de/avt-vqdb-uhd-1/test_1/segments/water_netflix_7500kbps_1080p_59.94fps_hevc.mp4")
            ]
            let techClips = techVideos.map { title, subtitle, desc, url in
                VideoClip(
                    id: url,
                    displayName: title,
                    subtitle: subtitle,
                    summary: desc,
                    thumbnailURL: URL(string: "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/images/BigBuckBunny.jpg")!,
                    variants: [VideoVariant(id: "Default", url: URL(string: url)!, isPrimary: true)]
                )
            }
            self.categories = [VideoCategory(id: "technical", title: "Technical Tests", clips: techClips)]
        }
        self.isLoading = false
    }
}

// Global static data for direct access
struct VideoData {
    static let bunny = VideoClip(
        id: "big_buck_bunny",
        displayName: "Big Buck Bunny",
        subtitle: "By Blender Foundation",
        summary: "Big Buck Bunny tells the story of a giant rabbit with a heart bigger than himself.",
        thumbnailURL: URL(string: "https://peach.blender.org/wp-content/uploads/title_anouncement.jpg")!,
        variants: [
            VideoVariant(id: "1080p 60fps", url: URL(string: "https://avtshare01.rz.tu-ilmenau.de/avt-vqdb-uhd-1/test_1/segments/bigbuck_bunny_8bit_7500kbps_1080p_60.0fps_hevc.mp4")!, isPrimary: true)
        ]
    )
    
    static let tears = VideoClip(
        id: "tears_of_steel",
        displayName: "Tears of Steel",
        subtitle: "By Blender Foundation",
        summary: "Tears of Steel was realized with crowd-funding by users of the open source 3D creation tool Blender.",
        thumbnailURL: URL(string: "https://mango.blender.org/wp-content/uploads/2013/06/12_scients_header.jpg")!,
        variants: [
            VideoVariant(id: "4K (3840x2160)", url: URL(string: "https://ftp.nluug.nl/pub/graphics/blender/demo/movies/ToS/ToS-4k-1920.mov")!, isPrimary: true)
        ]
    )
}

struct VideoCategory: Identifiable {
    let id: String
    let title: String
    let clips: [VideoClip]
}

struct VideoClip: Identifiable, Hashable {
    let id: String
    let displayName: String
    let subtitle: String
    let summary: String
    let thumbnailURL: URL
    let variants: [VideoVariant]
    
    var palette: [Color] {
        [.blue, .purple]
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: VideoClip, rhs: VideoClip) -> Bool {
        lhs.id == rhs.id
    }
}

struct VideoVariant: Identifiable, Hashable {
    let id: String
    let url: URL
    var isPrimary: Bool = false
}

private extension AVAsset {
    func asURLString() -> String? {
        (self as? AVURLAsset)?.url.absoluteString
    }
}

#Preview {
    VideoTestsView()
}