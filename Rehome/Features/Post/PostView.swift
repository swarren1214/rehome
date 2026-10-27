import CoreTransferable
import Photos
import SwiftUI
import UIKit
import UniformTypeIdentifiers

/// Ready to Post: Facebook doesn't let other apps create Marketplace listings, so Rehome gets
/// everything ready (photos in her library, the post on the clipboard), opens Facebook, and she
/// pastes and publishes. Then she marks the item listed here.
struct PostView: View {
    @Bindable var item: Item

    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    @Environment(\.colorScheme) private var colorScheme

    @State private var done: Set<PostStep> = []
    @State private var problem: String?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 3) {
                    Text("Ready to Post")
                        .font(.largeTitle.bold())
                        .accessibilityAddTraits(.isHeader)
                    Text("Facebook Marketplace · \(done.count) of \(PostStep.allCases.count) done")
                        .font(.subheadline)
                        .opacity(0.85)
                }
                .foregroundStyle(.white.opacity(colorScheme == .light ? 0.92 : 1))
                .padding(.horizontal, 4)

                preview
                steps
                share

                Text("Facebook doesn't let other apps create Marketplace listings. Rehome gets your photos and post ready so you only have to paste and publish.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 16)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 24)
            .frame(maxWidth: RehomeScreen<EmptyView>.readableWidth)
            .frame(maxWidth: .infinity)
        }
        .background(alignment: .top) { HeaderGradient() }
        .background(Color(.systemGroupedBackground))
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Close", systemImage: "xmark") { dismiss() }
                    .tint(.white)
            }
        }
        .safeAreaInset(edge: .bottom) {
            Button {
                item.markListed()
                dismiss()
            } label: {
                Label("Mark as Listed", systemImage: "checkmark")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.glassProminent)
            .controlSize(.large)
            .padding(.horizontal, 16)
            .padding(.bottom, 8)
            .frame(maxWidth: RehomeScreen<EmptyView>.readableWidth)
        }
        .alert("Couldn't Save Photos", isPresented: Binding(get: { problem != nil }, set: { if !$0 { problem = nil } })) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(problem ?? "")
        }
    }

    // MARK: - Sections

    private var preview: some View {
        HStack(alignment: .top, spacing: 12) {
            PhotoTile(data: item.coverData, symbol: item.category.symbol, maxPixel: 400)
                .frame(width: 96, height: 116)
                .clipShape(.rect(cornerRadius: 14))
            VStack(alignment: .leading, spacing: 3) {
                Text(Money.format(item.priceCents))
                    .font(.title3.bold())
                    .monospacedDigit()
                Text(listingTitle)
                    .font(.subheadline.weight(.semibold))
                Text(item.listingText.isEmpty ? "No post written yet. Edit the item to write one." : item.listingText)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .lineLimit(3)
            }
            Spacer(minLength: 0)
        }
        .padding(12)
        .background(Color(.secondarySystemGroupedBackground), in: .rect(cornerRadius: 22))
    }

    private var steps: some View {
        VStack(alignment: .leading, spacing: 7) {
            CardLabel("Steps")
            VStack(spacing: 0) {
                ForEach(Array(PostStep.allCases.enumerated()), id: \.element) { index, step in
                    stepRow(step, number: index + 1)
                    if index < PostStep.allCases.count - 1 { Divider().padding(.leading, 56) }
                }
            }
            .background(Color(.secondarySystemGroupedBackground), in: .rect(cornerRadius: 22))
        }
    }

    private func stepRow(_ step: PostStep, number: Int) -> some View {
        let isDone = done.contains(step)
        return HStack(spacing: 12) {
            ZStack {
                Circle().fill(isDone ? Color.green : Color(.tertiarySystemFill))
                if isDone {
                    Image(systemName: "checkmark")
                        .font(.footnote.weight(.bold))
                        .foregroundStyle(.white)
                } else {
                    Text("\(number)")
                        .font(.footnote.weight(.bold))
                        .monospacedDigit()
                }
            }
            .frame(width: 28, height: 28)
            .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 1) {
                Text(step.title)
                Text(hint(for: step))
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 8)
            if isDone {
                Text(step.doneTitle)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
            } else {
                Button(step.actionTitle) { perform(step) }
                    .buttonStyle(.glassProminent)
                    .disabled(step == .photos && item.sortedPhotos.isEmpty)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .accessibilityElement(children: .combine)
    }

    private var share: some View {
        ShareLink(
            items: item.sortedPhotos.compactMap { $0.data.map(PostPhoto.init(data:)) },
            subject: Text(listingTitle),
            message: Text(item.listingText),
            preview: { _ in SharePreview(listingTitle) }
        ) {
            HStack(spacing: 12) {
                Image(systemName: "person.2")
                    .frame(width: 28)
                Text("Share to a buy and sell group")
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.tertiary)
            }
            .foregroundStyle(.primary)
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(Color(.secondarySystemGroupedBackground), in: .rect(cornerRadius: 22))
        }
        .disabled(item.sortedPhotos.isEmpty)
    }

    // MARK: - Actions

    private var listingTitle: String {
        [item.brand, item.displayTitle, item.size.isEmpty ? nil : "· \(item.size)"]
            .compactMap { $0 }
            .filter { !$0.isEmpty }
            .joined(separator: " ")
    }

    private func hint(for step: PostStep) -> String {
        switch step {
        case .photos:
            let count = item.sortedPhotos.count
            return count == 0 ? "Add photos to the item first" : "\(count) \(count == 1 ? "photo" : "photos") to your library"
        case .copy: return "Paste it into the description"
        case .open: return "Marketplace › Create new listing"
        }
    }

    private func perform(_ step: PostStep) {
        switch step {
        case .photos:
            Task {
                do {
                    try await PhotoSaver.save(item.sortedPhotos.compactMap(\.data))
                    done.insert(.photos)
                } catch {
                    problem = error.localizedDescription
                }
            }
        case .copy:
            UIPasteboard.general.string = item.listingText
            done.insert(.copy)
        case .open:
            done.insert(.open)
            if UIApplication.shared.canOpenURL(AppConfig.facebookMarketplaceAppURL) {
                openURL(AppConfig.facebookMarketplaceAppURL)
            } else {
                openURL(AppConfig.facebookMarketplaceWebURL)
            }
        }
    }
}

enum PostStep: CaseIterable, Hashable {
    case photos, copy, open

    var title: String {
        switch self {
        case .photos: "Save photos"
        case .copy: "Copy the post"
        case .open: "Open Facebook"
        }
    }

    var actionTitle: String {
        switch self {
        case .photos: "Save"
        case .copy: "Copy"
        case .open: "Open"
        }
    }

    var doneTitle: String {
        switch self {
        case .photos: "Saved"
        case .copy: "Copied"
        case .open: "Opened"
        }
    }
}

/// A photo for the share sheet, as a JPEG.
nonisolated struct PostPhoto: Transferable {
    var data: Data

    static var transferRepresentation: some TransferRepresentation {
        DataRepresentation(exportedContentType: .jpeg) { photo in photo.data }
    }
}

/// Saves photos to the person's library (add-only access: Rehome never reads her library).
nonisolated enum PhotoSaver {
    enum Failure: LocalizedError {
        case notAllowed

        var errorDescription: String? {
            "Rehome isn't allowed to add photos. Turn on access in Settings › Apps › Rehome › Photos."
        }
    }

    static func save(_ photos: [Data]) async throws {
        let status = await PHPhotoLibrary.requestAuthorization(for: .addOnly)
        guard status == .authorized || status == .limited else { throw Failure.notAllowed }
        try await PHPhotoLibrary.shared().performChanges {
            for data in photos {
                PHAssetCreationRequest.forAsset().addResource(with: .photo, data: data, options: nil)
            }
        }
    }
}
