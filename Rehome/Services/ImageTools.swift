import ImageIO
import UIKit

/// Photo decoding and resizing, done off the main thread with ImageIO (fast and light on memory).
nonisolated enum ImageTools {
    /// The longest side, in pixels, a stored photo keeps: plenty for Facebook, small in iCloud.
    static let storedMaxPixel: CGFloat = 2048

    /// A copy of the photo no larger than `maxPixel` on its longest side, rotated upright.
    static func thumbnail(_ data: Data?, maxPixel: CGFloat) async -> UIImage? {
        guard let data else { return nil }
        let cgImage = await Task.detached(priority: .userInitiated) { () -> CGImage? in
            let sourceOptions = [kCGImageSourceShouldCache: false] as CFDictionary
            guard let source = CGImageSourceCreateWithData(data as CFData, sourceOptions) else { return nil }
            let options: [CFString: Any] = [
                kCGImageSourceCreateThumbnailFromImageAlways: true,
                kCGImageSourceCreateThumbnailWithTransform: true,
                kCGImageSourceShouldCacheImmediately: true,
                kCGImageSourceThumbnailMaxPixelSize: maxPixel,
            ]
            return CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary)
        }.value
        return cgImage.map { UIImage(cgImage: $0) }
    }

    /// Any photo (HEIC, PNG, JPEG) as an upright JPEG no larger than `storedMaxPixel`.
    static func storableJPEG(from data: Data) async -> Data? {
        await thumbnail(data, maxPixel: storedMaxPixel)?.jpegData(compressionQuality: 0.82)
    }

    /// A camera shot as an upright JPEG no larger than `storedMaxPixel`.
    static func storableJPEG(from image: UIImage) async -> Data? {
        guard let data = image.jpegData(compressionQuality: 0.95) else { return nil }
        return await storableJPEG(from: data)
    }
}
