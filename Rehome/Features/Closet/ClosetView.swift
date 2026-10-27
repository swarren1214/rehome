import SwiftData
import SwiftUI

/// The Closet tab: everything being sold, with counts by status, a filter and search.
struct ClosetView: View {
    @Environment(AppRouter.self) private var router
    @Query(sort: \Item.createdAt, order: .reverse) private var items: [Item]
    @State private var filter: ClosetFilter = .all
    @State private var searchText = ""

    var body: some View {
        RehomeScreen("Closet", subtitle: subtitle, refresh: { await CloudRefresh.wait() }) {
            if items.isEmpty {
                ClosetEmptyState { router.newItem() }
            } else {
                summary
                filterPicker
                if visible.isEmpty {
                    Card {
                        Text(searchText.isEmpty ? "Nothing here yet." : "No items match “\(searchText)”.")
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 24)
                    }
                } else {
                    grid
                }
            }
        }
        .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .automatic), prompt: "Search your closet")
        .rehomeToolbar {
            Button("Add Item", systemImage: "plus") { router.newItem() }
        }
    }

    // MARK: - Pieces

    private var subtitle: String? {
        guard !items.isEmpty else { return nil }
        let unsold = items.filter { $0.status != .sold }
        let asking = unsold.reduce(0) { $0 + $1.priceCents }
        let count = unsold.count
        return "\(count) \(count == 1 ? "item" : "items") · \(Money.format(asking)) asking"
    }

    private var summary: some View {
        HStack(spacing: 0) {
            StatValue(value: "\(count(.listed))", label: "Listed")
            Divider().frame(height: 36)
            StatValue(value: "\(count(.draft))", label: "Drafts")
            Divider().frame(height: 36)
            StatValue(value: "\(count(.sold))", label: "Sold")
        }
        .padding(.vertical, 14)
        .background(Color(.secondarySystemGroupedBackground), in: .rect(cornerRadius: 22))
    }

    private var filterPicker: some View {
        Picker("Show", selection: $filter) {
            ForEach(ClosetFilter.allCases) { option in
                Text(option.title).tag(option)
            }
        }
        .pickerStyle(.segmented)
    }

    private var grid: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 160), spacing: 12)], spacing: 12) {
            ForEach(visible) { item in
                NavigationLink(value: item) {
                    ItemCard(item: item)
                }
                .buttonStyle(.plain)
                .contextMenu { ItemMenu(item: item) }
            }
        }
    }

    // MARK: - Data

    private func count(_ status: ItemStatus) -> Int {
        items.filter { $0.status == status }.count
    }

    private var visible: [Item] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        return items.filter { item in
            guard filter.matches(item.status) else { return false }
            guard !query.isEmpty else { return true }
            return [item.title, item.brand, item.size, item.color, item.category.title]
                .contains { $0.localizedCaseInsensitiveContains(query) }
        }
    }
}

enum ClosetFilter: String, CaseIterable, Identifiable {
    case all, drafts, listed, sold

    var id: String { rawValue }

    var title: String {
        switch self {
        case .all: "All"
        case .drafts: ItemStatus.draft.pluralTitle
        case .listed: ItemStatus.listed.pluralTitle
        case .sold: ItemStatus.sold.pluralTitle
        }
    }

    func matches(_ status: ItemStatus) -> Bool {
        switch self {
        case .all: true
        case .drafts: status == .draft
        case .listed: status == .listed
        case .sold: status == .sold
        }
    }
}

/// One item in the Closet grid: cover photo, title, size and brand, price and status.
struct ItemCard: View {
    var item: Item

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            PhotoTile(data: item.coverData, symbol: item.category.symbol)
                .frame(height: 170)
                .overlay(alignment: .bottomLeading) {
                    let count = item.photos?.count ?? 0
                    if count > 0 {
                        Label("\(count)", systemImage: "photo")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(.black.opacity(0.42), in: .capsule)
                            .padding(8)
                            .accessibilityLabel("\(count) photos")
                    }
                }
            VStack(alignment: .leading, spacing: 2) {
                Text(item.displayTitle)
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(1)
                Text(item.summary.isEmpty ? item.category.title : item.summary)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                HStack {
                    Text(Money.format(item.status == .sold ? item.soldPriceCents : item.priceCents))
                        .font(.headline)
                        .monospacedDigit()
                    Spacer(minLength: 6)
                    StatusChip(status: item.status)
                }
                .padding(.top, 6)
            }
            .padding(.horizontal, 12)
            .padding(.top, 10)
            .padding(.bottom, 12)
        }
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(.rect(cornerRadius: 18))
        .contentShape(.rect(cornerRadius: 18))
        .accessibilityElement(children: .combine)
    }
}

/// The long-press menu on an item, also used by the item page's "…" button.
struct ItemMenu: View {
    var item: Item
    @Environment(AppRouter.self) private var router

    var body: some View {
        Button("Edit", menuIcon: "pencil") { router.edit(item) }
        if item.status != .sold {
            Button("Get Ready to Post", menuIcon: "square.and.arrow.up") { router.posting = item }
        }
    }
}

/// The first launch: nothing in the closet yet.
struct ClosetEmptyState: View {
    var add: () -> Void

    var body: some View {
        Card(padding: 24) {
            VStack(spacing: 14) {
                Image(systemName: "hanger")
                    .font(.system(size: 48, weight: .light))
                    .foregroundStyle(Brand.ink)
                    .accessibilityHidden(true)
                Text("Your closet is empty")
                    .font(.title3.bold())
                Text("Add a piece you want to sell: snap a few photos, set the size and price, and Rehome writes the post for you.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                Button(action: add) {
                    Label("Add First Item", systemImage: "camera")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.glassProminent)
                .controlSize(.large)
                .padding(.top, 4)
            }
            .frame(maxWidth: .infinity)
        }
    }
}

/// Pull to refresh: SwiftData syncs with iCloud on its own, so this gives the latest changes a
/// moment to arrive before the spinner goes away.
nonisolated enum CloudRefresh {
    static func wait() async {
        try? await Task.sleep(for: .seconds(1))
    }
}
