import SwiftUI

enum DS {
    enum ColorPalette {
        static let backgroundTop = Color(red: 0.04, green: 0.10, blue: 0.16)
        static let backgroundBottom = Color(red: 0.02, green: 0.04, blue: 0.07)
        static let accentA = Color(red: 0.18, green: 0.90, blue: 0.95)
        static let accentB = Color(red: 0.90, green: 0.45, blue: 0.15)
        static let surface = Color.white.opacity(0.08)
        static let surfaceStroke = Color.white.opacity(0.18)
        static let textPrimary = Color.white
        static let textSecondary = Color.white.opacity(0.7)
    }

    enum Spacing {
        static let xs: CGFloat = 4
        static let s: CGFloat = 8
        static let m: CGFloat = 12
        static let l: CGFloat = 16
        static let xl: CGFloat = 20
        static let xxl: CGFloat = 24
        static let hero: CGFloat = 40
    }

    enum Radius {
        static let s: CGFloat = 12
        static let m: CGFloat = 16
        static let l: CGFloat = 20
        static let xl: CGFloat = 24
        static let card: CGFloat = 26
    }

    enum Shadow {
        static let faint = Color.black.opacity(0.2)
        static let medium = Color.black.opacity(0.35)
    }

    enum Typography {
        static let hero = Font.system(size: 52, weight: .bold, design: .rounded)
        static let title = Font.title2.weight(.bold)
        static let headline = Font.headline.weight(.semibold)
        static let callout = Font.callout
        static let caption = Font.caption
    }
}
