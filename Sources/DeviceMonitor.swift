import UIKit
import SwiftUI

class DeviceMonitor: ObservableObject {
    @Published var resolution: String = ""
    @Published var displayQuality: String = "HD"
    @Published var fps: Int = 60
    @Published var hdrStatus: String = "SDR"
    
    init() {
        updateInfo()
    }
    
    func updateInfo() {
        let screen = UIScreen.main
        let nativeBounds = screen.nativeBounds
        let width = Int(nativeBounds.width)
        let height = Int(nativeBounds.height)
        
        self.resolution = "\(width) x \(height)"
        
        // Quality Labeling
        if width >= 3840 {
            self.displayQuality = "4K UHD"
        } else if width >= 2560 {
            self.displayQuality = "2K QHD"
        } else if width >= 1920 {
            self.displayQuality = "FHD 1080p"
        } else if width >= 1280 {
            self.displayQuality = "HD 720p"
        } else {
            self.displayQuality = "SD"
        }
        
        // HDR Kontrolü (Basitleştirmiş)
        if screen.maximumFramesPerSecond > 60 {
            self.fps = Int(screen.maximumFramesPerSecond)
        }
        
        // tvOS'te HDR tespiti traitCollection üzerinden tahmin edilebilir
        if screen.traitCollection.displayGamut == .P3 {
             self.hdrStatus = "HDR10 / DV (P3)"
        } else {
             self.hdrStatus = "SDR (sRGB)"
        }
    }
}
