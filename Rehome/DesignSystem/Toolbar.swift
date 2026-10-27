import SwiftUI

/// The round button at the top right of every main screen that opens Settings. Rehome isn't part
/// of the Hearth household, so there's no profile photo; the person symbol stands in its place.
struct SettingsButton: View {
    @Environment(AppRouter.self) private var router

    var body: some View {
        Button("Settings", systemImage: "person.crop.circle") {
            router.showsSettings = true
        }
    }
}

extension View {
    /// The top bar for every main screen: the screen's actions and the Settings button share one
    /// Liquid Glass capsule at the top right, Settings always last. Icons are white over the
    /// color header (`overColorHeader` false: the text color).
    func rehomeToolbar<Actions: View>(overColorHeader: Bool = true, @ViewBuilder actions: @escaping () -> Actions) -> some View {
        toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                // White icons (also in the "…" overflow menu, where the berry tint would
                // otherwise color icons beside white text).
                Group {
                    actions()
                    SettingsButton()
                }
                .tint(overColorHeader ? Color.white : Color.primary)
            }
        }
    }
}
