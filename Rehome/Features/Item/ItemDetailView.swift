import SwiftData
import SwiftUI
import UIKit

/// One item: its photos, price, details, where it's listed, the post text and her notes, with
/// Drop Price and Mark as Sold at the bottom.
struct ItemDetailView: View {
    @Bindable var item: Item
    @Environment(AppRouter.self) private var router
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @State private var askingSoldPrice = false
    @State private var askingNewPrice = false
    @State private var confirmingDelete = false
    @State private var priceText = ""
    @State private var copied = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                PhotoCarousel(item: item)
                VStack(alignment: .leading, spacing: 20) {
                    header
                    if item.status == .sold { soldBanner }
                    details
                    listing
                    if !item.listingText.isEmpty { post }
                    notes
                }
                .padding(.horizontal, 16)
                .frame(maxWidth: RehomeScreen<EmptyView>.readableWidth)
                .frame(maxWidth: .infinity)
            }
            .padding(.bottom, 24)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle(item.displayTitle)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                Group {
                    Button("Edit", systemImage: "pencil") { router.edit(item) }
                    Menu("More", systemImage: "ellipsis") {
                        ItemMenu(item: item)
                        Divider()
                        Button("Delete Item", menuIcon: "trash", role: .destructive) { confirmingDelete = true }
                    }
                }
                .tint(.primary)
            }
        }
        .safeAreaInset(edge: .bottom) { actions }
        .alert("Mark as Sold", isPresented: $askingSoldPrice) {
            TextField("Sold for", text: $priceText)
                .keyboardType(.decimalPad)
            Button("Cancel", role: .cancel) {}
            Button("Mark as Sold") {
                item.markSold(for: parsedCents ?? item.priceCents)
            }
        } message: {
            Text("What did it sell for? Remember to mark it sold on Facebook too.")
        }
        .alert("Drop Price", isPresented: $askingNewPrice) {
            TextField("New price", text: $priceText)
                .keyboardType(.decimalPad)
            Button("Cancel", role: .cancel) {}
            Button("Update Price") {
                if let cents = parsedCents { item.priceCents = cents }
            }
        } message: {
            Text("It's \(Money.format(item.priceCents)) now. Update the listing on Facebook too.")
        }
        .alert("Delete \(item.displayTitle)?", isPresented: $confirmingDelete) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                // Leave the page first, so nothing draws the item after it's gone.
                let doomed = item
                dismiss()
                Task {
                    try? await Task.sleep(for: .milliseconds(450))
                    context.delete(doomed)
                }
            }
        } message: {
            Text("Its photos and notes are deleted from all your devices.")
        }
    }

    // MARK: - Sections

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                if !item.brand.isEmpty {
                    Text(item.brand.uppercased())
                        .font(.footnote.weight(.semibold))
                        .tracking(0.4)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                StatusChip(status: item.status)
            }
            Text(item.displayTitle)
                .font(.title2.bold())
            HStack(alignment: .firstTextBaseline, spacing: 10) {
                Text(Money.format(item.priceCents))
                    .font(.title.bold())
                    .monospacedDigit()
                if item.originalPriceCents > 0 {
                    Text("\(Money.format(item.originalPriceCents)) retail")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .strikethrough()
                }
            }
        }
        .padding(.horizontal, 4)
    }

    private var soldBanner: some View {
        Card {
            HStack(spacing: 12) {
                Image(systemName: "checkmark")
                    .font(.body.bold())
                    .foregroundStyle(.white)
                    .frame(width: 32, height: 32)
                    .background(Color.green, in: .circle)
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 1) {
                    Text("Sold for \(Money.format(item.soldPriceCents))")
                        .font(.headline)
                    if let soldAt = item.soldAt {
                        Text(soldAt.formatted(date: .abbreviated, time: .omitted))
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }
                Spacer()
                Button("Undo") { item.undoSold() }
                    .tint(.primary)
            }
        }
    }

    private var details: some View {
        VStack(alignment: .leading, spacing: 7) {
            CardLabel("Details")
            VStack(spacing: 0) {
                let rows = detailRows
                ForEach(Array(rows.enumerated()), id: \.offset) { index, row in
                    LabeledContent(row.0, value: row.1)
                        .padding(.vertical, 12)
                        .padding(.horizontal, 16)
                    if index < rows.count - 1 { Divider().padding(.leading, 16) }
                }
            }
            .background(Color(.secondarySystemGroupedBackground), in: .rect(cornerRadius: 22))
        }
    }

    private var detailRows: [(String, String)] {
        var rows: [(String, String)] = [("Category", item.category.title)]
        if item.sizeSystem == .oneSize {
            rows.append(("Size", "One size"))
        } else if !item.size.isEmpty {
            rows.append(("Size", item.size))
        }
        rows.append(("Condition", item.condition.title))
        if !item.color.isEmpty { rows.append(("Color", item.color)) }
        if !item.material.isEmpty { rows.append(("Material", item.material)) }
        if !item.measurements.isEmpty { rows.append(("Measurements", item.measurements)) }
        return rows
    }

    private var listing: some View {
        VStack(alignment: .leading, spacing: 7) {
            CardLabel("Listing")
            Card {
                HStack(spacing: 12) {
                    Image(systemName: "storefront")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(.white)
                        .frame(width: 32, height: 32)
                        .background(Color(hex: 0x1877F2), in: .rect(cornerRadius: 8))
                        .accessibilityHidden(true)
                    VStack(alignment: .leading, spacing: 1) {
                        Text("Facebook Marketplace")
                        Text(listingLine)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                    Spacer(minLength: 8)
                    if item.status == .draft {
                        Button("Post") { router.posting = item }
                            .buttonStyle(.glassProminent)
                    }
                }
            }
        }
    }

    private var listingLine: String {
        switch item.status {
        case .draft:
            return "Not listed yet"
        case .listed:
            guard let listedAt = item.listedAt else { return "Listed" }
            return "Listed \(listedAt.formatted(date: .abbreviated, time: .omitted)) · \(listedAt.formatted(.relative(presentation: .named)))"
        case .sold:
            if let days = item.daysToSell { return "Sold in \(days) \(days == 1 ? "day" : "days")" }
            return "Sold"
        }
    }

    private var post: some View {
        VStack(alignment: .leading, spacing: 7) {
            CardLabel(title: "Post") {
                Button(copied ? "Copied" : "Copy", systemImage: copied ? "checkmark" : "doc.on.doc") {
                    UIPasteboard.general.string = item.listingText
                    copied = true
                }
                .font(.footnote.weight(.semibold))
                .tint(.primary)
            }
            Card {
                Text(item.listingText)
                    .font(.callout)
                    .textSelection(.enabled)
            }
        }
    }

    private var notes: some View {
        VStack(alignment: .leading, spacing: 7) {
            CardLabel("Notes")
            Card {
                TextField("Who asked about it, pickup plans…", text: $item.notes, axis: .vertical)
                    .lineLimit(2...8)
            }
        }
    }

    private var actions: some View {
        HStack(spacing: 10) {
            if item.status != .sold {
                Button {
                    priceText = ""
                    askingNewPrice = true
                } label: {
                    Label("Drop Price", systemImage: "arrow.down")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.glass)
                .tint(.primary)

                Button {
                    priceText = ""
                    askingSoldPrice = true
                } label: {
                    Label("Mark as Sold", systemImage: "checkmark")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.glassProminent)
            }
        }
        .controlSize(.large)
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
        .frame(maxWidth: RehomeScreen<EmptyView>.readableWidth)
    }

    private var parsedCents: Int? {
        PriceParser.cents(from: priceText)
    }
}

/// Swipe through an item's photos. With none, a tile with the category's symbol.
struct PhotoCarousel: View {
    var item: Item

    var body: some View {
        let photos = item.sortedPhotos
        Group {
            if photos.isEmpty {
                PhotoTile(data: nil, symbol: item.category.symbol)
            } else {
                TabView {
                    ForEach(photos) { photo in
                        PhotoTile(data: photo.data, symbol: item.category.symbol, maxPixel: 1400)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: photos.count > 1 ? .always : .never))
            }
        }
        .frame(height: 400)
        .frame(maxWidth: .infinity)
    }
}

/// Reads a price someone typed: "34", "$34.50", "34,50".
nonisolated enum PriceParser {
    static func cents(from text: String) -> Int? {
        let cleaned = text
            .replacingOccurrences(of: ",", with: ".")
            .filter { $0.isNumber || $0 == "." }
        guard !cleaned.isEmpty, let value = Decimal(string: cleaned) else { return nil }
        return Money.cents(value)
    }
}
