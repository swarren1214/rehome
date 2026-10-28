import Foundation
import SwiftData

/// The New Item / Edit sheet works on a copy, so Cancel leaves the closet untouched.
struct ItemDraft {
    var title = ""
    var brand = ""
    var category: ItemCategory = .tops
    var sizeSystem: SizeSystem = .letter
    var size = ""
    var condition: ItemCondition = .likeNew
    var color = ""
    var material = ""
    var measurements = ""
    var price: Decimal?
    var originalPrice: Decimal?
    var listingText = ""
    var photos: [DraftPhoto] = []

    init() {}

    init(item: Item) {
        title = item.title
        brand = item.brand
        category = item.category
        sizeSystem = item.sizeSystem
        size = item.size
        condition = item.condition
        color = item.color
        material = item.material
        measurements = item.measurements
        price = item.priceCents > 0 ? Money.decimal(item.priceCents) : nil
        originalPrice = item.originalPriceCents > 0 ? Money.decimal(item.originalPriceCents) : nil
        listingText = item.listingText
        photos = item.sortedPhotos.compactMap { photo in
            photo.data.map { DraftPhoto(id: photo.id, data: $0) }
        }
    }

    /// Worth saving: a photo or a title.
    var hasContent: Bool {
        !photos.isEmpty || !title.trimmingCharacters(in: .whitespaces).isEmpty
    }

    /// The facts the description writer works from.
    var facts: ListingFacts {
        ListingFacts(
            title: title.trimmingCharacters(in: .whitespacesAndNewlines),
            brand: brand.trimmingCharacters(in: .whitespacesAndNewlines),
            category: category.title,
            size: sizeSystem == .oneSize ? "One size" : (size.isEmpty ? "" : sizeSystem.label(for: size)),
            condition: condition.title,
            color: color,
            material: material,
            measurements: measurements,
            priceCents: price.map(Money.cents) ?? 0,
            originalPriceCents: originalPrice.map(Money.cents) ?? 0
        )
    }

    /// Copies the draft into `item` (a new one when nil) and returns it.
    @discardableResult
    func save(into item: Item?, context: ModelContext) -> Item {
        let target = item ?? Item()
        if item == nil { context.insert(target) }
        target.title = title.trimmingCharacters(in: .whitespacesAndNewlines)
        target.brand = brand.trimmingCharacters(in: .whitespacesAndNewlines)
        target.category = category
        target.sizeSystem = sizeSystem
        target.size = sizeSystem == .oneSize ? "" : size
        target.condition = condition
        target.color = color
        target.material = material
        target.measurements = measurements
        target.priceCents = price.map(Money.cents) ?? 0
        target.originalPriceCents = originalPrice.map(Money.cents) ?? 0
        target.listingText = listingText

        // Photos: keep the ones still here (in their new order), drop the removed, add the new.
        let existing = target.photos ?? []
        let keptIDs = Set(photos.map(\.id))
        for photo in existing where !keptIDs.contains(photo.id) {
            context.delete(photo)
        }
        var result: [ItemPhoto] = []
        for (index, draftPhoto) in photos.enumerated() {
            if let photo = existing.first(where: { $0.id == draftPhoto.id }) {
                photo.order = index
                result.append(photo)
            } else {
                let photo = ItemPhoto(data: draftPhoto.data, order: index)
                photo.id = draftPhoto.id
                context.insert(photo)
                result.append(photo)
            }
        }
        target.photos = result
        return target
    }
}

struct DraftPhoto: Identifiable, Equatable {
    var id = UUID()
    var data: Data
}
