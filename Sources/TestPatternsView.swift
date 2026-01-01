import SwiftUI
import UIKit

struct TestPatternsView: View {
    struct PatternItem: Identifiable, Hashable {
        let id: String
        let name: String
        let category: String
    }

    enum PatternResolution: String, CaseIterable, Identifiable {
        case hd = "HD-1280x720"
        case wxga = "WXGA-1280x800"
        case fhd = "FHD-1920x1080"
        case qhd = "QHD-2560x1440"
        case wqxga = "WQXGA-2560x1600"
        case uhd = "UHD-3840x2160"

        var id: String { rawValue }

        var label: String {
            rawValue.replacingOccurrences(of: "-", with: " ")
        }

        var pixelCount: Int {
            let parts = rawValue.split(separator: "-").last?.split(separator: "x") ?? []
            guard parts.count == 2,
                  let width = Int(parts[0]),
                  let height = Int(parts[1]) else {
                return 0
            }
            return width * height
        }
    }

    @Environment(\.dismiss) private var dismiss
    @State private var isMinimized = false
    @State private var selectedResolution: PatternResolution = .uhd
    @State private var selectedCategory: String = ""
    @State private var selectedPattern: PatternItem?
    @State private var categories: [String: [PatternItem]] = [:]
    @State private var isLoading = true
    @State private var displayedImage: UIImage?
    @State private var controlsHidden = false

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            if let image = displayedImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .ignoresSafeArea()
            }

            if isLoading {
                VStack(spacing: 12) {
                    ProgressView()
                    Text("Loading pattern...")
                        .font(.callout)
                        .foregroundStyle(.white.opacity(0.8))
                }
            } else if categories.isEmpty {
                Text("No patterns found for \(selectedResolution.label).")
                    .font(.headline)
                    .foregroundStyle(.secondary)
            }

            ControlPanelDock(title: "Test Patterns", isMinimized: $isMinimized, controlsHidden: controlsHidden) {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Select a category and pattern to test geometry, color, and resolution.")
                        .font(.callout)
                        .foregroundStyle(.secondary)

                    SectionHeader(title: "Resolution")
                    Picker("Resolution", selection: $selectedResolution) {
                        ForEach(PatternResolution.allCases.sorted(by: { $0.pixelCount < $1.pixelCount })) { resolution in
                            Text(resolution.label).tag(resolution)
                        }
                    }
                    .pickerStyle(.menu)
                    .glassInput(cornerRadius: 12)

                    if !categories.isEmpty {
                        SectionHeader(title: "Category")
                        Picker("Category", selection: $selectedCategory) {
                            ForEach(categories.keys.sorted(), id: \.self) { category in
                                Text(category.capitalized).tag(category)
                            }
                        }
                        .pickerStyle(.menu)
                        .glassInput(cornerRadius: 12)

                        if let items = categories[selectedCategory] {
                            SectionHeader(title: "Pattern")
                            Picker("Pattern", selection: Binding(
                                get: { selectedPattern?.id ?? items.first?.id ?? "" },
                                set: { newValue in
                                    if let match = items.first(where: { $0.id == newValue }) {
                                        selectedPattern = match
                                        loadImage()
                                    }
                                }
                            )) {
                                ForEach(items) { pattern in
                                    Text(pattern.name).tag(pattern.id)
                                }
                            }
                            .pickerStyle(.menu)
                            .glassInput(cornerRadius: 12)
                        }
                    }
                }
            }
        }
        .onAppear {
            let best = bestResolution()
            if Bundle.main.url(forResource: "index", withExtension: "json", subdirectory: "Patterns/\(best.rawValue)") != nil {
                selectedResolution = best
            } else {
                selectedResolution = .fhd
            }
            loadPatterns()
        }
        .onChange(of: selectedResolution) { _, _ in
            loadPatterns()
        }
        .toolbar(.hidden, for: .navigationBar)
        .testControls(controlsHidden: $controlsHidden, dismiss: dismiss)
    }

    private func bestResolution() -> PatternResolution {
        let native = UIScreen.main.nativeBounds.size
        let pixels = Int(native.width * native.height)
        let sorted = PatternResolution.allCases.sorted { $0.pixelCount < $1.pixelCount }
        return sorted.first(where: { $0.pixelCount >= pixels }) ?? sorted.last ?? .uhd
    }

    private func loadPatterns() {
        isLoading = true
        categories = [:]
        selectedCategory = ""
        selectedPattern = nil
        displayedImage = nil

        let subdirectory = "Patterns/\(selectedResolution.rawValue)"

        DispatchQueue.global(qos: .userInitiated).async {
            do {
                let files: [String]
                if let url = Bundle.main.url(forResource: "index", withExtension: "json", subdirectory: subdirectory) {
                    let data = try Data(contentsOf: url)
                    files = try JSONDecoder().decode([String].self, from: data)
                } else if let urls = Bundle.main.urls(forResourcesWithExtension: "png", subdirectory: subdirectory) {
                    files = urls.map { $0.lastPathComponent }
                } else {
                    DispatchQueue.main.async {
                        isLoading = false
                    }
                    return
                }

                var mapped: [String: [PatternItem]] = [:]
                for file in files {
                    let item = parsePattern(filename: file)
                    mapped[item.category, default: []].append(item)
                }

                let sorted = mapped.mapValues { $0.sorted { $0.name < $1.name } }

                DispatchQueue.main.async {
                    categories = sorted
                    if let firstCategory = sorted.keys.sorted().first,
                       let firstPattern = sorted[firstCategory]?.first {
                        selectedCategory = firstCategory
                        selectedPattern = firstPattern
                    }
                    loadImage()
                }
            } catch {
                DispatchQueue.main.async {
                    isLoading = false
                }
            }
        }
    }

    private func loadImage() {
        guard let selectedPattern else {
            isLoading = false
            return
        }

        isLoading = true
        DispatchQueue.global(qos: .userInitiated).async {
            let image = loadPatternImage(named: selectedPattern.id)
            DispatchQueue.main.async {
                displayedImage = image
                isLoading = false
            }
        }
    }

    private func loadPatternImage(named name: String) -> UIImage? {
        guard let url = Bundle.main.url(
            forResource: name,
            withExtension: nil,
            subdirectory: "Patterns/\(selectedResolution.rawValue)"
        ) else {
            return nil
        }
        return UIImage(contentsOfFile: url.path)
    }

    private func parsePattern(filename: String) -> PatternItem {
        let base = filename.replacingOccurrences(of: ".png", with: "")
        let parts = base.split(separator: "-")
        guard parts.count >= 3 else {
            return PatternItem(id: filename, name: base, category: "General")
        }

        let category = String(parts[1])
        let nameParts = parts.dropFirst(2)
        let name = nameParts.map { $0.capitalized }.joined(separator: " ")
        return PatternItem(id: filename, name: name, category: category)
    }
}

#Preview {
    TestPatternsView()
}
