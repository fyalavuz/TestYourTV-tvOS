import SwiftUI
import WebKit

struct TestPatternsView: View {
    struct PatternItem: Identifiable {
        let id: String
        let url: URL
        let name: String
    }

    @Environment(\.dismiss) private var dismiss
    @State private var isMinimized = false
    @State private var patterns: [PatternItem] = []
    @State private var selectedIndex: Int = 0
    @State private var isLoading = true
    @State private var controlsHidden = false

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            if let current = currentPattern {
                SVGWebView(url: current.url)
                    .ignoresSafeArea()
                    .allowsHitTesting(false)
            }

            if isLoading {
                VStack(spacing: 12) {
                    ProgressView()
                    Text("Loading patterns...")
                        .font(.callout)
                        .foregroundStyle(.white.opacity(0.8))
                }
            } else if patterns.isEmpty {
                Text("No SVG patterns found.")
                    .font(.headline)
                    .foregroundStyle(.secondary)
            }

            ControlPanelDock(title: "Test Patterns", isMinimized: $isMinimized, controlsHidden: controlsHidden, fillsHeight: false) {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Use left/right on the remote to switch between SVG patterns.")
                        .font(.callout)
                        .foregroundStyle(.secondary)

                    SectionHeader(title: "Current Pattern")
                    Text(currentPattern?.name ?? "None")
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(.white)

                    Text(patternIndexLabel)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .onAppear {
            loadPatterns()
        }
        .onMoveCommand { direction in
            handleMove(direction)
        }
        .toolbar(.hidden, for: .navigationBar)
        .testControls(controlsHidden: $controlsHidden, dismiss: dismiss)
    }

    private var currentPattern: PatternItem? {
        guard patterns.indices.contains(selectedIndex) else { return nil }
        return patterns[selectedIndex]
    }

    private var patternIndexLabel: String {
        guard !patterns.isEmpty else { return "0 / 0" }
        return "\(selectedIndex + 1) / \(patterns.count)"
    }

    private func handleMove(_ direction: MoveCommandDirection) {
        guard !patterns.isEmpty else { return }
        switch direction {
        case .left:
            selectedIndex = (selectedIndex - 1 + patterns.count) % patterns.count
        case .right:
            selectedIndex = (selectedIndex + 1) % patterns.count
        default:
            break
        }
    }

    private func loadPatterns() {
        isLoading = true
        patterns = []
        selectedIndex = 0

        DispatchQueue.global(qos: .userInitiated).async {
            let urls = Bundle.main.urls(forResourcesWithExtension: "svg", subdirectory: "test-cards") ?? []
            let items = urls
                .map { url in
                    let name = url.deletingPathExtension().lastPathComponent
                    return PatternItem(id: name, url: url, name: displayName(for: name))
                }
                .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }

            DispatchQueue.main.async {
                patterns = items
                selectedIndex = 0
                isLoading = false
            }
        }
    }

    private func displayName(for filename: String) -> String {
        filename
            .replacingOccurrences(of: "_", with: " ")
            .replacingOccurrences(of: "-", with: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .capitalized
    }
}

struct SVGWebView: UIViewRepresentable {
    let url: URL

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.isOpaque = false
        webView.backgroundColor = .clear
        webView.scrollView.isScrollEnabled = false
        webView.scrollView.bounces = false
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        guard context.coordinator.currentURL != url else { return }
        context.coordinator.currentURL = url
        let svgContent = (try? String(contentsOf: url)) ?? ""
        let html = """
        <!doctype html>
        <html>
          <head>
            <meta name=\"viewport\" content=\"width=device-width, height=device-height, initial-scale=1, user-scalable=no\" />
            <style>
              html, body { margin: 0; padding: 0; width: 100%; height: 100%; background: #000; }
              svg { width: 100%; height: 100%; display: block; }
            </style>
          </head>
          <body>
            \(svgContent)
          </body>
        </html>
        """
        webView.loadHTMLString(html, baseURL: url.deletingLastPathComponent())
    }

    final class Coordinator {
        var currentURL: URL?
    }
}

#Preview {
    TestPatternsView()
}
