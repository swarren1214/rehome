import Testing
@testable import Rehome

struct DescriptionTemplateTests {
    let facts = ListingFacts(
        title: "Cable-knit crewneck sweater",
        brand: "Free People",
        category: "Sweaters",
        size: "S",
        condition: "Like new",
        color: "Cream",
        material: "Cotton blend",
        measurements: "21 in pit to pit, 24 in long",
        priceCents: 3400,
        originalPriceCents: 12800
    )

    @Test func simpleTemplateNamesTheBasics() {
        let text = DescriptionWriter.templateBody(facts, tone: .simple)
        #expect(text.hasPrefix("Free People cream cable-knit crewneck sweater, size S."))
    }

    @Test func assembleAddsMeasurementsPriceAndPickup() {
        var options = DescriptionOptions(tone: .friendly)
        options.pickupDetails = "Porch pickup or I can meet nearby."
        let text = DescriptionWriter.assemble(body: "Body.", facts, options: options)
        let paragraphs = text.components(separatedBy: "\n\n")
        #expect(paragraphs.count == 3)
        #expect(paragraphs[1] == "Measurements: 21 in pit to pit, 24 in long.")
        #expect(paragraphs[2].contains("Porch pickup"))
    }

    @Test func optionsTurnPartsOff() {
        let options = DescriptionOptions(tone: .simple, includeMeasurements: false, includePickup: false, includeHashtags: false, pickupDetails: "Pickup")
        let text = DescriptionWriter.assemble(body: "Body.", facts, options: options)
        #expect(!text.contains("Measurements"))
        #expect(!text.contains("Pickup"))
    }

    @Test func hashtagsAreUniqueAndClean() {
        let tags = DescriptionWriter.hashtags(facts)
        #expect(tags.hasPrefix("#freepeople #sweaters"))
    }
}

struct PriceTests {
    @Test func parsesTypedPrices() {
        #expect(PriceParser.cents(from: "34") == 3400)
        #expect(PriceParser.cents(from: "$34.50") == 3450)
        #expect(PriceParser.cents(from: "34,5") == 3450)
        #expect(PriceParser.cents(from: "") == nil)
    }
}

struct SizeTests {
    @Test func everySystemListsEachSizeOnce() {
        for system in SizeSystem.allCases {
            #expect(Set(system.sizes).count == system.sizes.count)
        }
    }

    @Test func kidsShoeSizesRunFromBabyToBigKid() {
        let sizes = SizeSystem.kidsShoe.sizes
        #expect(sizes.first == "1C")
        #expect(sizes.contains("13.5C"))
        #expect(sizes.last == "7Y")
    }

    @Test func kidsSizesSayKids() {
        #expect(SizeSystem.kids.phrase(for: "10/12") == "Kids' size 10/12")
        #expect(SizeSystem.kidsLetter.label(for: "S") == "Kids S")
        #expect(SizeSystem.toddler.phrase(for: "3T") == "Size 3T")
    }

    @Test func kidsSizeReadsNaturallyInPosts() {
        let facts = ListingFacts(
            title: "Puffer jacket", brand: "", category: "Coats & Jackets", size: "Kids 10/12",
            condition: "Good", color: "", material: "", measurements: "", priceCents: 0, originalPriceCents: 0
        )
        #expect(DescriptionWriter.templateBody(facts, tone: .simple) == "Puffer jacket, kids' size 10/12. Good.")
    }
}
