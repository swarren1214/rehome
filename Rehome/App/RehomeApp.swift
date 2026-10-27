import SwiftData
import SwiftUI
import UIKit

@main
struct RehomeApp: App {
    @State private var router = AppRouter()
    private let container = RehomeApp.makeContainer()

    init() {
        SettingsKey.registerDefaults()
        // Alerts use the system label color rather than the berry. Destructive buttons stay red.
        UIView.appearance(whenContainedInInstancesOf: [UIAlertController.self]).tintColor = .label
    }

    var body: some Scene {
        WindowGroup {
            RootTabView()
                .tint(Brand.berry)
                .environment(router)
        }
        .modelContainer(container)
    }

    /// The closet, synced to the person's private iCloud database. If CloudKit can't be set up
    /// (no iCloud capability while developing), it falls back to this device only.
    static func makeContainer() -> ModelContainer {
        let schema = Schema([Item.self, ItemPhoto.self])
        let synced = ModelConfiguration(schema: schema, cloudKitDatabase: .private(AppConfig.cloudKitContainer))
        do {
            return try ModelContainer(for: schema, configurations: synced)
        } catch {
            let local = ModelConfiguration(schema: schema, cloudKitDatabase: .none)
            do {
                return try ModelContainer(for: schema, configurations: local)
            } catch {
                fatalError("Couldn't open the closet: \(error)")
            }
        }
    }
}

nonisolated enum AppConfig {
    static let cloudKitContainer = "iCloud.com.stephenwarren.rehome"
    /// Opens the Facebook app's Marketplace when it's installed.
    static let facebookMarketplaceAppURL = URL(string: "fb://marketplace")!
    /// Marketplace's "create listing" page, for when the app isn't installed.
    static let facebookMarketplaceWebURL = URL(string: "https://www.facebook.com/marketplace/create/item")!
}
