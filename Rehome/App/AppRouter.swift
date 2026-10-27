import Observation
import SwiftUI

enum AppTab: Hashable {
    case closet, sales
}

/// Opens the New Item sheet (`item` nil) or edits an item.
struct EditorRequest: Identifiable {
    let id = UUID()
    var item: Item?
}

/// Where the app is: the selected tab, each tab's navigation path and the sheets that open over
/// any tab.
@Observable
final class AppRouter {
    var tab: AppTab = .closet
    var closetPath: [Item] = []
    var salesPath: [Item] = []
    var editor: EditorRequest?
    var posting: Item?
    var showsSettings = false

    func newItem() {
        editor = EditorRequest(item: nil)
    }

    func edit(_ item: Item) {
        editor = EditorRequest(item: item)
    }
}
