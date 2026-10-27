import SwiftData
import SwiftUI

/// Settings, from the person button at the top right: pickup details for posts, what posts
/// include by default, and erasing the closet.
struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @AppStorage(SettingsKey.pickupDetails) private var pickupDetails = ""
    @AppStorage(SettingsKey.includeMeasurements) private var includeMeasurements = true
    @AppStorage(SettingsKey.includePickup) private var includePickup = true
    @AppStorage(SettingsKey.includeHashtags) private var includeHashtags = false
    @State private var confirmingErase = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Pickup details", text: $pickupDetails, prompt: Text("Porch pickup in [your area], or I can meet nearby."), axis: .vertical)
                        .lineLimit(2...4)
                } header: {
                    Text("Pickup")
                } footer: {
                    Text("Added to the end of every post. Name a neighborhood, not your address.")
                }

                Section("Posts Include") {
                    Toggle("Measurements", isOn: $includeMeasurements)
                    Toggle("Pickup details", isOn: $includePickup)
                    Toggle("Hashtags", isOn: $includeHashtags)
                }

                Section {
                    Label {
                        Text("Syncs with your iCloud")
                    } icon: {
                        Image(systemName: "icloud").foregroundStyle(.primary)
                    }
                } footer: {
                    Text("Your closet and photos stay in your iCloud and on your devices. Posts are written on this device.")
                }

                #if DEBUG
                Section("Developer") {
                    Button("Add Sample Closet", menuIcon: "tshirt") {
                        SampleCloset.add(to: context)
                    }
                    .tint(.primary)
                }
                #endif

                Section {
                    Button("Erase Closet", role: .destructive) { confirmingErase = true }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    SheetDoneButton { dismiss() }
                }
            }
            .alert("Erase your closet?", isPresented: $confirmingErase) {
                Button("Cancel", role: .cancel) {}
                Button("Erase", role: .destructive) {
                    // One by one, so each deletion syncs to iCloud.
                    let items = (try? context.fetch(FetchDescriptor<Item>())) ?? []
                    for item in items { context.delete(item) }
                    dismiss()
                }
            } message: {
                Text("Every item and photo is deleted from all your devices. This can't be undone.")
            }
        }
    }
}

#if DEBUG
/// Example items for trying the app in the simulator (Settings › Developer).
enum SampleCloset {
    static func add(to context: ModelContext) {
        let calendar = Calendar.current
        func daysAgo(_ days: Int) -> Date { calendar.date(byAdding: .day, value: -days, to: .now) ?? .now }

        let samples: [(String, String, ItemCategory, SizeSystem, String, Int, Int, ItemStatus, Int, Int?)] = [
            ("Cable-knit crewneck sweater", "Free People", .sweaters, .letter, "S", 3400, 12800, .listed, 3, nil),
            ("Perfect Vintage jean", "Madewell", .pants, .numeric, "27", 2800, 12800, .listed, 6, nil),
            ("Floral tiered midi dress", "Anthropologie", .dresses, .letter, "S", 3800, 14800, .draft, 1, nil),
            ("Classic trench coat", "Everlane", .outerwear, .letter, "M", 6500, 19800, .listed, 9, nil),
            ("Air Force 1 '07", "Nike", .shoes, .shoe, "8", 4000, 11500, .sold, 8, 5),
            ("Align leggings 25\"", "Lululemon", .activewear, .numeric, "6", 4500, 9800, .sold, 14, 12),
            ("Silk cami", "Aritzia", .tops, .letter, "S", 1800, 6800, .sold, 30, 24),
        ]
        for sample in samples {
            let item = Item()
            item.title = sample.0
            item.brand = sample.1
            item.category = sample.2
            item.sizeSystem = sample.3
            item.size = sample.4
            item.priceCents = sample.5
            item.originalPriceCents = sample.6
            item.createdAt = daysAgo(sample.8 + 1)
            if sample.7 != .draft { item.markListed(); item.listedAt = daysAgo(sample.8) }
            if sample.7 == .sold, let soldDaysAgo = sample.9 {
                item.markSold(for: sample.5, on: daysAgo(soldDaysAgo))
            }
            context.insert(item)
        }
    }
}
#endif
