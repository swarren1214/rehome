import SwiftUI
import UIKit

/// Keys for settings stored with @AppStorage. Keep every key here so views stay in sync.
nonisolated enum SettingsKey {
    /// How the person hands off a buyer: "Porch pickup in [area], or I can meet nearby."
    /// Added to descriptions when "Pickup details" is on.
    static let pickupDetails = "listing.pickupDetails"
    /// The tone picked last time on the Description screen (`DescriptionTone` raw value).
    static let descriptionTone = "listing.tone"
    static let includeMeasurements = "listing.includeMeasurements"
    static let includePickup = "listing.includePickup"
    static let includeHashtags = "listing.includeHashtags"

    /// Defaults for settings that start on.
    static func registerDefaults() {
        UserDefaults.standard.register(defaults: [
            descriptionTone: DescriptionTone.friendly.rawValue,
            includeMeasurements: true,
            includePickup: true,
            includeHashtags: false,
        ])
    }
}

/// Rehome's colors: a berry (#B23A66). It fills buttons, the header and icon tiles, and is dark
/// enough for large text on white. Small text never uses it (see AGENT.md › App color).
nonisolated enum Brand {
    /// Buttons, the selected tab, the confirm button on sheets.
    static let berry = Color(hex: 0xB23A66)
    /// Top of the header gradient: a deeper berry, so the white title and icons read on it.
    static let berryDeep = Color(hex: 0x952C53)
    /// Middle of the header gradient.
    static let berryMid = Color(hex: 0xB23A66)
    /// Large text and stand-alone icons in the app's color: the berry on light (6:1 on white), a
    /// pale rose on dark.
    static let ink = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark ? UIColor(hex: 0xF08AAE) : UIColor(hex: 0xA3325C)
    })
    /// The soft rose behind icons.
    static let tint = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark ? UIColor(hex: 0xB23A66).withAlphaComponent(0.3) : UIColor(hex: 0xF8E3EB)
    })
}

/// A status's chip colors: a pale fill and a readable ink in both appearances.
extension ItemStatus {
    var ink: Color {
        switch self {
        case .draft: Color(.secondaryLabel)
        case .listed: Color(uiColor: UIColor { $0.userInterfaceStyle == .dark ? UIColor(hex: 0x6AB0FF) : UIColor(hex: 0x0059CC) })
        case .sold: Color(uiColor: UIColor { $0.userInterfaceStyle == .dark ? UIColor(hex: 0x4CD964) : UIColor(hex: 0x1C7431) })
        }
    }

    var fill: Color {
        switch self {
        case .draft: Color(.tertiarySystemFill)
        case .listed: Color(uiColor: UIColor { $0.userInterfaceStyle == .dark ? UIColor(hex: 0x0A84FF).withAlphaComponent(0.22) : UIColor(hex: 0x007AFF).withAlphaComponent(0.12) })
        case .sold: Color(uiColor: UIColor { $0.userInterfaceStyle == .dark ? UIColor(hex: 0x30D158).withAlphaComponent(0.2) : UIColor(hex: 0x34C759).withAlphaComponent(0.16) })
        }
    }
}

extension Color {
    nonisolated init(hex: UInt32) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: 1
        )
    }
}

extension UIColor {
    nonisolated convenience init(hex: UInt32) {
        self.init(
            red: CGFloat((hex >> 16) & 0xFF) / 255,
            green: CGFloat((hex >> 8) & 0xFF) / 255,
            blue: CGFloat(hex & 0xFF) / 255,
            alpha: 1
        )
    }
}
