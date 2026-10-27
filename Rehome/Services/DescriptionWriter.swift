import Foundation
import FoundationModels

/// What a post is written from. Only these facts go to the model; nothing about the person.
nonisolated struct ListingFacts: Sendable, Equatable {
    var title: String
    var brand: String
    var category: String
    var size: String
    var condition: String
    var color: String
    var material: String
    var measurements: String
    var priceCents: Int
    var originalPriceCents: Int
}

nonisolated enum DescriptionTone: String, CaseIterable, Identifiable, Sendable {
    case friendly, simple, detailed

    var id: String { rawValue }

    var title: String {
        switch self {
        case .friendly: "Friendly"
        case .simple: "Simple"
        case .detailed: "Detailed"
        }
    }

    /// How the model is asked to write.
    var guidance: String {
        switch self {
        case .friendly: "Warm and upbeat, like a friend selling something she loved. Two to four sentences."
        case .simple: "Short and plain. One or two sentences of facts, no adjectives beyond what's needed."
        case .detailed: "Thorough: fit, fabric, construction and condition. Four to six sentences."
        }
    }
}

nonisolated struct DescriptionOptions: Sendable, Equatable {
    var tone: DescriptionTone = .friendly
    var includeMeasurements = true
    var includePickup = true
    var includeHashtags = false
    /// "Porch pickup in [your area], or I can meet nearby."
    var pickupDetails = ""
}

/// Writes the Facebook post for an item, on device with Apple Intelligence (Foundation Models).
/// When the model isn't available (older device, Apple Intelligence off, still downloading), it
/// uses a template, so there's always a post to start from.
nonisolated enum DescriptionWriter {
    /// Whether Apple Intelligence can write here, for the Description screen's note.
    static var isModelAvailable: Bool {
        if case .available = SystemLanguageModel.default.availability { return true }
        return false
    }

    static func write(_ facts: ListingFacts, options: DescriptionOptions) async -> String {
        guard isModelAvailable else { return template(facts, options: options) }
        do {
            let session = LanguageModelSession(instructions: instructions)
            let response = try await session.respond(to: prompt(facts, options: options))
            let body = clean(response.content)
            guard !body.isEmpty else { return template(facts, options: options) }
            return assemble(body: body, facts, options: options)
        } catch {
            return template(facts, options: options)
        }
    }

    // MARK: - Model

    private static let instructions = """
    You write listings for secondhand clothing on Facebook Marketplace. Write only the \
    description paragraph: no title line, no price, no measurements, no hashtags, no emoji, no \
    quotation marks. Use only the facts given; never invent flaws, materials, measurements or \
    history. Write in the first person as the seller.
    """

    static func prompt(_ facts: ListingFacts, options: DescriptionOptions) -> String {
        var lines = ["Item: \(facts.title.isEmpty ? facts.category : facts.title)"]
        if !facts.brand.isEmpty { lines.append("Brand: \(facts.brand)") }
        lines.append("Category: \(facts.category)")
        if !facts.size.isEmpty { lines.append("Size: \(facts.size)") }
        lines.append("Condition: \(facts.condition)")
        if !facts.color.isEmpty { lines.append("Color: \(facts.color)") }
        if !facts.material.isEmpty { lines.append("Material: \(facts.material)") }
        lines.append("Style: \(options.tone.guidance)")
        return lines.joined(separator: "\n")
    }

    private static func clean(_ text: String) -> String {
        text.trimmingCharacters(in: .whitespacesAndNewlines)
            .trimmingCharacters(in: CharacterSet(charactersIn: "\"“”"))
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    // MARK: - Template

    /// The post without the model: the same shape, written from the facts alone.
    static func template(_ facts: ListingFacts, options: DescriptionOptions) -> String {
        assemble(body: templateBody(facts, tone: options.tone), facts, options: options)
    }

    static func templateBody(_ facts: ListingFacts, tone: DescriptionTone) -> String {
        let name = facts.title.isEmpty ? facts.category.lowercased() : facts.title.lowercased()
        let what = [facts.brand, facts.color.lowercased(), name]
            .filter { !$0.isEmpty }
            .joined(separator: " ")
        let sizePart = facts.size.isEmpty ? "" : (facts.size == "One size" ? ", one size" : ", size \(facts.size)")
        let condition = facts.condition.lowercased()
        switch tone {
        case .simple:
            return "\(what.capitalizedFirst)\(sizePart). \(facts.condition)."
        case .friendly:
            var text = "\(what.capitalizedFirst)\(sizePart)."
            if !facts.material.isEmpty { text += " It's \(facts.material.lowercased()) and so easy to wear." }
            text += " In \(condition) condition and ready for a new closet."
            return text
        case .detailed:
            var text = "\(what.capitalizedFirst)\(sizePart)."
            if !facts.material.isEmpty { text += " Made of \(facts.material.lowercased())." }
            text += " Condition: \(condition)."
            if facts.originalPriceCents > 0 { text += " Retails for \(Money.format(facts.originalPriceCents))." }
            text += " Smoke-free home. Happy to send more photos of any detail."
            return text
        }
    }

    /// The body plus the parts that never come from the model: measurements, price, pickup and
    /// hashtags, each its own paragraph.
    static func assemble(body: String, _ facts: ListingFacts, options: DescriptionOptions) -> String {
        var parts = [body]
        let measurements = facts.measurements.trimmingCharacters(in: .whitespacesAndNewlines)
        if options.includeMeasurements, !measurements.isEmpty {
            parts.append("Measurements: \(measurements).")
        }
        var closing = facts.priceCents > 0 ? "\(Money.format(facts.priceCents))." : ""
        if options.tone != .simple {
            closing += (closing.isEmpty ? "" : " ") + "Message me with any questions!"
        }
        let pickup = options.pickupDetails.trimmingCharacters(in: .whitespacesAndNewlines)
        if options.includePickup, !pickup.isEmpty {
            closing += (closing.isEmpty ? "" : " ") + pickup
        }
        if !closing.isEmpty { parts.append(closing) }
        if options.includeHashtags {
            let tags = hashtags(facts)
            if !tags.isEmpty { parts.append(tags) }
        }
        return parts.joined(separator: "\n\n")
    }

    static func hashtags(_ facts: ListingFacts) -> String {
        let words = [facts.brand, facts.category, "womens fashion", "secondhand"]
        let tags = words.compactMap { word -> String? in
            let tag = word.lowercased().filter { $0.isLetter || $0.isNumber }
            return tag.isEmpty ? nil : "#\(tag)"
        }
        var seen = Set<String>()
        return tags.filter { seen.insert($0).inserted }.joined(separator: " ")
    }
}

extension String {
    /// "free People sweater" → "Free People sweater": only the first letter changes.
    nonisolated var capitalizedFirst: String {
        guard let first else { return self }
        return first.uppercased() + dropFirst()
    }
}
