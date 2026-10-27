import PhotosUI
import SwiftUI
import UIKit

/// The row of photos at the top of the editor: Camera and Library buttons, then the photos, the
/// first marked Cover. Long-press a photo to make it the cover or remove it.
struct PhotoStrip: View {
    @Binding var photos: [DraftPhoto]

    @State private var pickerItems: [PhotosPickerItem] = []
    @State private var showsCamera = false
    @State private var isLoading = false

    private let tileSize = CGSize(width: 92, height: 112)
    private static let maxPhotos = 12

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                if UIImagePickerController.isSourceTypeAvailable(.camera) {
                    addTile(title: "Camera", symbol: "camera") { showsCamera = true }
                }
                PhotosPicker(
                    selection: $pickerItems,
                    maxSelectionCount: max(1, Self.maxPhotos - photos.count),
                    matching: .images
                ) {
                    addTileLabel(title: "Library", symbol: "photo.on.rectangle")
                }
                .buttonStyle(.plain)
                .disabled(photos.count >= Self.maxPhotos)

                if isLoading {
                    ProgressView()
                        .frame(width: tileSize.width, height: tileSize.height)
                }

                ForEach(Array(photos.enumerated()), id: \.element.id) { index, photo in
                    PhotoTile(data: photo.data, maxPixel: 300)
                        .frame(width: tileSize.width, height: tileSize.height)
                        .clipShape(.rect(cornerRadius: 16))
                        .overlay(alignment: .bottomLeading) {
                            if index == 0 {
                                Text("Cover")
                                    .font(.caption2.weight(.semibold))
                                    .foregroundStyle(.white)
                                    .padding(.horizontal, 7)
                                    .padding(.vertical, 2)
                                    .background(.black.opacity(0.5), in: .capsule)
                                    .padding(6)
                            }
                        }
                        .overlay(alignment: .topTrailing) {
                            Button("Remove Photo", systemImage: "xmark") {
                                remove(photo)
                            }
                            .labelStyle(.iconOnly)
                            // Plain, so a tap in the Form row only hits this button.
                            .buttonStyle(.plain)
                            .font(.caption.weight(.bold))
                            .foregroundStyle(.white)
                            .frame(width: 26, height: 26)
                            .background(.black.opacity(0.5), in: .circle)
                            .padding(5)
                        }
                        .contextMenu {
                            if index > 0 {
                                Button("Make Cover", menuIcon: "star") { makeCover(photo) }
                            }
                            Button("Remove", menuIcon: "trash", role: .destructive) { remove(photo) }
                        }
                        .accessibilityElement(children: .contain)
                        .accessibilityLabel(index == 0 ? "Cover photo" : "Photo \(index + 1)")
                }
            }
        }
        .onChange(of: pickerItems) { _, items in
            guard !items.isEmpty else { return }
            Task { await load(items) }
        }
        .fullScreenCover(isPresented: $showsCamera) {
            CameraPicker { image in
                Task {
                    if let data = await ImageTools.storableJPEG(from: image) {
                        withAnimation { photos.append(DraftPhoto(data: data)) }
                    }
                }
            }
            .ignoresSafeArea()
        }
    }

    private func addTile(title: String, symbol: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            addTileLabel(title: title, symbol: symbol)
        }
        .buttonStyle(.plain)
        .disabled(photos.count >= Self.maxPhotos)
    }

    private func addTileLabel(title: String, symbol: String) -> some View {
        VStack(spacing: 6) {
            Image(systemName: symbol)
                .font(.title2)
            Text(title)
                .font(.footnote.weight(.semibold))
        }
        .foregroundStyle(.primary)
        .frame(width: tileSize.width, height: tileSize.height)
        .background(Color(.tertiarySystemFill), in: .rect(cornerRadius: 16))
    }

    private func load(_ items: [PhotosPickerItem]) async {
        isLoading = true
        defer {
            isLoading = false
            pickerItems = []
        }
        for item in items {
            guard photos.count < Self.maxPhotos else { break }
            if let raw = try? await item.loadTransferable(type: Data.self),
               let data = await ImageTools.storableJPEG(from: raw) {
                withAnimation { photos.append(DraftPhoto(data: data)) }
            }
        }
    }

    private func remove(_ photo: DraftPhoto) {
        withAnimation { photos.removeAll { $0.id == photo.id } }
    }

    private func makeCover(_ photo: DraftPhoto) {
        guard let index = photos.firstIndex(of: photo) else { return }
        withAnimation {
            let moved = photos.remove(at: index)
            photos.insert(moved, at: 0)
        }
    }
}

/// The system camera, for taking a photo of an item.
struct CameraPicker: UIViewControllerRepresentable {
    var onCapture: (UIImage) -> Void
    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ controller: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    final class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: CameraPicker

        init(_ parent: CameraPicker) { self.parent = parent }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.onCapture(image)
            }
            parent.dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}
