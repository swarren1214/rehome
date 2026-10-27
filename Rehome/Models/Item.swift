import Foundation
import SwiftData

// The closet: every piece of clothing being sold, with its photos. Stored with SwiftData and
// synced to the person's private iCloud database (CloudKit), so it's on every device on her
// Apple Account. CloudKit sync rules: every property has a default or is optional, no unique
// constraints, and relationships are optional.

@Model
final class Item {
    var id: UUID = UUID()
    var title: String = ""
    var brand: String = ""
    var categoryRaw: String = ItemCategory.tops.rawValue
    var sizeSystemRaw: String = SizeSystem.letter.rawValue
    var size: String = ""
    var conditionRaw: String = ItemCondition.likeNew.rawValue
    var color: String = ""
    var material: String = ""
    /// Free text: "21 in pit to pit, 24 in long".
    var measurements: String = ""
    /// Asking price, in cents.
    var priceCents: Int = 0
    /// What it cost new, in cents (0 = unknown).
    var originalPriceCents: Int = 0
    var statusRaw: String = ItemStatus.draft.rawValue
    /// The post text she'll paste into Facebook.
    var listingText: String = ""
    /// Her own notes: who asked about it, pickup plans.
    var notes: String = ""
    var createdAt: Date = Date()
    var listedAt: Date?
    var soldAt: Date?
    /// What it actually sold for, in cents.
    var soldPriceCents: Int = 0

    @Relationship(deleteRule: .cascade, inverse: \ItemPhoto.item)
    var photos: [ItemPhoto]? = []

    init() {}

    var category: ItemCategory {
        get { ItemCategory(rawValue: categoryRaw) ?? .other }
        set { categoryRaw = newValue.rawValue }
    }

    var sizeSystem: SizeSystem {
        get { SizeSystem(rawValue: sizeSystemRaw) ?? .letter }
        set { sizeSystemRaw = newValue.rawValue }
    }

    var condition: ItemCondition {
        get { ItemCondition(rawValue: conditionRaw) ?? .good }
        set { conditionRaw = newValue.rawValue }
    }

    var status: ItemStatus {
        get { ItemStatus(rawValue: statusRaw) ?? .draft }
        set { statusRaw = newValue.rawValue }
    }

    /// Photos in the order she arranged them; the first is the cover.
    var sortedPhotos: [ItemPhoto] {
        (photos ?? []).sorted { $0.order < $1.order }
    }

    var coverData: Data? { sortedPhotos.first?.data }

    /// "Cable-knit sweater" or "Untitled item".
    var displayTitle: String {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "Untitled item" : trimmed
    }

    /// "Size S · Free People"
    var summary: String {
        var parts: [String] = []
        if !size.isEmpty { parts.append(sizeSystem == .oneSize ? "One size" : "Size \(size)") }
        if !brand.isEmpty { parts.append(brand) }
        return parts.joined(separator: " · ")
    }

    /// Mark it listed now (or keep the first listed date).
    func markListed() {
        status = .listed
        if listedAt == nil { listedAt = .now }
    }

    func markSold(for cents: Int, on date: Date = .now) {
        status = .sold
        soldPriceCents = cents
        soldAt = date
    }

    func undoSold() {
        status = listedAt == nil ? .draft : .listed
        soldAt = nil
        soldPriceCents = 0
    }

    /// Days from listing to sale, when both are known.
    var daysToSell: Int? {
        guard let listedAt, let soldAt else { return nil }
        return max(0, Calendar.current.dateComponents([.day], from: listedAt, to: soldAt).day ?? 0)
    }
}

/// One photo of an item. The JPEG lives outside the database file (and syncs as a CloudKit asset).
@Model
final class ItemPhoto {
    var id: UUID = UUID()
    @Attribute(.externalStorage) var data: Data?
    var order: Int = 0
    var item: Item?

    init(data: Data, order: Int) {
        self.data = data
        self.order = order
    }
}

nonisolated enum ItemStatus: String, CaseIterable, Codable, Identifiable, Sendable {
    case draft, listed, sold

    var id: String { rawValue }

    var title: String {
        switch self {
        case .draft: "Draft"
        case .listed: "Listed"
        case .sold: "Sold"
        }
    }

    /// The Closet filter's name for it.
    var pluralTitle: String {
        switch self {
        case .draft: "Drafts"
        case .listed: "Listed"
        case .sold: "Sold"
        }
    }
}

nonisolated enum ItemCondition: String, CaseIterable, Codable, Identifiable, Sendable {
    case newWithTags, likeNew, good, fair

    var id: String { rawValue }

    var title: String {
        switch self {
        case .newWithTags: "New with tags"
        case .likeNew: "Like new"
        case .good: "Good"
        case .fair: "Fair"
        }
    }

    var hint: String {
        switch self {
        case .newWithTags: "Never worn, tags attached"
        case .likeNew: "Worn a few times, no flaws"
        case .good: "Light wear, shown in photos"
        case .fair: "Visible wear or small flaws"
        }
    }
}

nonisolated enum SizeSystem: String, CaseIterable, Codable, Identifiable, Sendable {
    case letter, numeric, shoe, oneSize

    var id: String { rawValue }

    var title: String {
        switch self {
        case .letter: "Letter"
        case .numeric: "Numeric"
        case .shoe: "Shoe"
        case .oneSize: "One Size"
        }
    }

    var sizes: [String] {
        switch self {
        case .letter: ["XXS", "XS", "S", "M", "L", "XL", "XXL", "1X", "2X", "3X"]
        case .numeric: ["00", "0", "2", "4", "6", "8", "10", "12", "14", "16", "24", "25", "26", "27", "28", "29", "30", "31", "32"]
        case .shoe: ["5", "5.5", "6", "6.5", "7", "7.5", "8", "8.5", "9", "9.5", "10", "10.5", "11"]
        case .oneSize: []
        }
    }
}

nonisolated enum ItemCategory: String, CaseIterable, Codable, Identifiable, Sendable {
    case tops, sweaters, dresses, pants, skirts, outerwear, activewear, shoes, bags, accessories, other

    var id: String { rawValue }

    var title: String {
        switch self {
        case .tops: "Tops"
        case .sweaters: "Sweaters"
        case .dresses: "Dresses"
        case .pants: "Pants & Jeans"
        case .skirts: "Skirts & Shorts"
        case .outerwear: "Coats & Jackets"
        case .activewear: "Activewear"
        case .shoes: "Shoes"
        case .bags: "Bags"
        case .accessories: "Accessories"
        case .other: "Other"
        }
    }

    /// The symbol shown when an item has no photo yet.
    var symbol: String {
        switch self {
        case .tops, .sweaters, .activewear: "tshirt"
        case .dresses: "figure.stand.dress"
        case .shoes: "shoe"
        case .bags: "handbag"
        case .accessories: "eyeglasses"
        default: "hanger"
        }
    }

    /// The size system most items in this category use.
    var defaultSizeSystem: SizeSystem {
        switch self {
        case .pants: .numeric
        case .shoes: .shoe
        case .bags, .accessories: .oneSize
        default: .letter
        }
    }
}
