import SwiftUI

/// The Liquid Glass tab bar from the Rehome canvas: Closet and Sales. New Item, Settings and
/// Ready to Post open as sheets over either tab.
struct RootTabView: View {
    @Environment(AppRouter.self) private var router
    @Environment(\.horizontalSizeClass) private var sizeClass

    var body: some View {
        @Bindable var router = router
        TabView(selection: $router.tab) {
            Tab(value: AppTab.closet) {
                NavigationStack(path: $router.closetPath) {
                    ClosetView().itemDestinations()
                }
            } label: {
                tabLabel("Closet", "hanger")
            }

            Tab(value: AppTab.sales) {
                NavigationStack(path: $router.salesPath) {
                    SalesView().itemDestinations()
                }
            } label: {
                tabLabel("Sales", "tag")
            }
        }
        .tabViewStyle(.sidebarAdaptable)
        .tabBarMinimizeBehavior(.onScrollDown)
        .sheet(item: $router.editor) { request in
            ItemEditor(item: request.item)
        }
        .sheet(item: $router.posting) { item in
            NavigationStack {
                PostView(item: item)
            }
        }
        .sheet(isPresented: $router.showsSettings) {
            SettingsView()
        }
    }

    /// Icon only in the iPhone tab bar, as in every Hearth app (VoiceOver still reads the name);
    /// icon and name on iPad, where the icon is the color of its name (see AGENT.md).
    @ViewBuilder
    private func tabLabel(_ title: String, _ systemImage: String) -> some View {
        if sizeClass == .regular {
            Label { Text(title) } icon: { Image.menuIcon(systemImage) }
        } else {
            Image(systemName: systemImage)
                .accessibilityLabel(title)
        }
    }
}

extension View {
    /// Item pages pushed from any list.
    func itemDestinations() -> some View {
        navigationDestination(for: Item.self) { item in
            ItemDetailView(item: item)
        }
    }
}
