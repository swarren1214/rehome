import PhotosUI
import SwiftData
import SwiftUI

/// The New Item / Edit sheet: photos, what it is, size, condition, details, price and the post.
struct ItemEditor: View {
    var item: Item?

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Environment(AppRouter.self) private var router
    @State private var draft: ItemDraft
    @State private var confirmingDiscard = false

    init(item: Item?) {
        self.item = item
        _draft = State(initialValue: item.map(ItemDraft.init(item:)) ?? ItemDraft())
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    PhotoStrip(photos: $draft.photos)
                        .listRowInsets(EdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16))
                } header: {
                    Text("Photos")
                } footer: {
                    Text("The first photo is the cover. Add the tag and any flaws.")
                }

                Section {
                    TextField("Title", text: $draft.title, prompt: Text("Cable-knit crewneck sweater"))
                    TextField("Brand", text: $draft.brand)
                    Picker("Category", selection: $draft.category) {
                        ForEach(ItemCategory.allCases) { category in
                            Text(category.title).tag(category)
                        }
                    }
                    .tint(.primary)
                }

                Section("Size") {
                    Picker("Size system", selection: $draft.sizeSystem) {
                        ForEach(SizeSystem.allCases) { system in
                            Text(system.title).tag(system)
                        }
                    }
                    .pickerStyle(.segmented)
                    .listRowSeparator(.hidden)
                    if draft.sizeSystem != .oneSize {
                        SizeChips(sizes: draft.sizeSystem.sizes, selection: $draft.size)
                        TextField("Or type a size", text: $draft.size)
                    }
                }

                Section("Condition") {
                    ForEach(ItemCondition.allCases) { condition in
                        Button {
                            draft.condition = condition
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 1) {
                                    Text(condition.title)
                                    Text(condition.hint)
                                        .font(.footnote)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                if draft.condition == condition {
                                    Image(systemName: "checkmark")
                                        .font(.body.weight(.semibold))
                                        .foregroundStyle(Brand.ink)
                                }
                            }
                            .contentShape(.rect)
                        }
                        .tint(.primary)
                        .accessibilityAddTraits(draft.condition == condition ? .isSelected : [])
                    }
                }

                Section("Details") {
                    TextField("Color", text: $draft.color)
                    TextField("Material", text: $draft.material, prompt: Text("Material, like cotton blend"))
                    TextField("Measurements", text: $draft.measurements, prompt: Text("Measurements, like 21 in pit to pit"), axis: .vertical)
                }

                Section("Price") {
                    LabeledContent("Asking price") {
                        TextField("Asking price", value: $draft.price, format: .currency(code: Money.currencyCode), prompt: Text("$0"))
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .font(.headline)
                    }
                    LabeledContent("Original price") {
                        TextField("Original price", value: $draft.originalPrice, format: .currency(code: Money.currencyCode), prompt: Text("Optional"))
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                }

                Section {
                    NavigationLink {
                        DescriptionView(draft: $draft)
                    } label: {
                        if draft.listingText.isEmpty {
                            Label("Write Description", systemImage: "sparkles")
                        } else {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Description")
                                Text(draft.listingText)
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(3)
                            }
                        }
                    }
                    .tint(.primary)
                } header: {
                    Text("Post")
                } footer: {
                    Text("Rehome writes the Facebook post from these details. You can edit it before you post.")
                }
            }
            .navigationTitle(item == nil ? "New Item" : "Edit Item")
            .navigationBarTitleDisplayMode(.inline)
            .onChange(of: draft.category) { _, new in
                // Pants go to numeric sizes, shoes to shoe sizes, until a size is picked.
                if draft.size.isEmpty { draft.sizeSystem = new.defaultSizeSystem }
            }
            .onChange(of: draft.sizeSystem) { _, new in
                if !new.sizes.contains(draft.size) { draft.size = "" }
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    SheetCancelButton {
                        if draft.hasContent && item == nil {
                            confirmingDiscard = true
                        } else {
                            dismiss()
                        }
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    SheetDoneButton("Save") { save() }
                        .disabled(!draft.hasContent)
                }
            }
            .alert("Discard this item?", isPresented: $confirmingDiscard) {
                Button("Keep Editing", role: .cancel) {}
                Button("Discard", role: .destructive) { dismiss() }
            } message: {
                Text("Its photos and details won't be saved.")
            }
            .interactiveDismissDisabled(draft.hasContent)
        }
    }

    private func save() {
        let saved = draft.save(into: item, context: context)
        dismiss()
        // A new item opens on its page, ready to post.
        if item == nil {
            router.tab = .closet
            router.closetPath = [saved]
        }
    }
}

/// The sizes for the chosen system as tappable chips; the selected one is filled berry.
struct SizeChips: View {
    var sizes: [String]
    @Binding var selection: String

    var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 52), spacing: 8)], spacing: 8) {
            ForEach(sizes, id: \.self) { size in
                let selected = selection == size
                Button {
                    selection = selected ? "" : size
                } label: {
                    Text(size)
                        .font(.subheadline.weight(.semibold))
                        .monospacedDigit()
                        .frame(maxWidth: .infinity, minHeight: 44)
                        .foregroundStyle(selected ? Color.white : Color.primary)
                        .background(selected ? Brand.berry : Color(.tertiarySystemFill), in: .rect(cornerRadius: 12))
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Size \(size)")
                .accessibilityAddTraits(selected ? .isSelected : [])
            }
        }
        .padding(.vertical, 4)
    }
}
