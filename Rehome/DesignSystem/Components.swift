import SwiftUI

// The pieces every Rehome screen is built from, matching the Rehome canvas: the berry header that
// fades into the gray background (the Hearth color header), white 22 pt cards, quiet uppercase
// labels, status chips and photo tiles.

/// The berry header that fades into the gray background, fixed behind the scroll view. The same
/// header every Hearth app draws in its own color.
struct HeaderGradient: View {
    /// How far down the screen the color reaches before it's gone, as a share of the screen's
    /// height: half on iPhone, 40% on iPad.
    var fraction: CGFloat?

    @Environment(\.horizontalSizeClass) private var sizeClass

    var body: some View {
        // On iPhone the color holds longer before it fades (eased); on iPad, an even fade.
        let curve = sizeClass == .compact ? Self.phoneCurve : Self.evenCurve
        GeometryReader { geo in
            LinearGradient(
                stops: curve.map { point in
                    Gradient.Stop(
                        color: Brand.berryDeep.mix(with: Brand.berryMid, by: point.location).opacity(point.opacity),
                        location: point.location
                    )
                },
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(width: geo.size.width, height: geo.size.height * (fraction ?? (sizeClass == .compact ? 0.5 : 0.4)))
        }
        .ignoresSafeArea()
        .accessibilityHidden(true)
    }

    private static let phoneCurve: [(location: Double, opacity: Double)] = [
        (0, 1), (0.3, 0.88), (0.6, 0.5), (0.85, 0.15), (1, 0),
    ]
    private static let evenCurve: [(location: Double, opacity: Double)] = [(0, 1), (1, 0)]
}

/// A screen with the berry header: a big white title (tabs) or a small centered one (details),
/// an optional line under it, then cards. On iPad the content keeps to a readable column while
/// the color runs edge to edge.
struct RehomeScreen<Content: View>: View {
    static var readableWidth: CGFloat { 760 }

    @Environment(\.colorScheme) private var colorScheme
    var title: String
    var subtitle: String?
    var largeTitle = true
    var refresh: (() async -> Void)?
    @ViewBuilder var content: () -> Content

    init(_ title: String, subtitle: String? = nil, largeTitle: Bool = true, refresh: (() async -> Void)? = nil, @ViewBuilder content: @escaping () -> Content) {
        self.title = title
        self.subtitle = subtitle
        self.largeTitle = largeTitle
        self.refresh = refresh
        self.content = content
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if largeTitle || subtitle != nil {
                    VStack(alignment: .leading, spacing: 3) {
                        if largeTitle {
                            Text(title)
                                .font(.largeTitle.bold())
                                .accessibilityAddTraits(.isHeader)
                        }
                        if let subtitle {
                            Text(subtitle)
                                .font(.subheadline)
                                .opacity(0.85)
                        }
                    }
                    // A touch softer in Light Mode, where pure white over the lighter berry glares.
                    .foregroundStyle(.white.opacity(colorScheme == .light ? 0.92 : 1))
                    .padding(.horizontal, 4)
                }
                content()
            }
            .padding(.horizontal, 16)
            .padding(.top, 4)
            .padding(.bottom, 32)
            .frame(maxWidth: Self.readableWidth)
            .frame(maxWidth: .infinity)
        }
        .refreshable { await refresh?() }
        .background(alignment: .top) { HeaderGradient() }
        .background(Color(.systemGroupedBackground))
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .principal) {
                if largeTitle {
                    // The title is drawn large in the content, as in the designs.
                    Color.clear.frame(width: 1, height: 1).accessibilityHidden(true)
                } else {
                    Text(title)
                        .font(.headline)
                        .foregroundStyle(.white)
                        .lineLimit(1)
                }
            }
        }
    }
}

/// A white card with the designs' 22 pt corners.
struct Card<Content: View>: View {
    var padding: CGFloat = 16
    @ViewBuilder var content: () -> Content

    var body: some View {
        content()
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(padding)
            .background(Color(.secondarySystemGroupedBackground), in: .rect(cornerRadius: 22))
    }
}

/// A quiet, uppercase label over a card ("RECENTLY SOLD"), with an optional control on the right.
struct CardLabel<Trailing: View>: View {
    var title: String
    @ViewBuilder var trailing: () -> Trailing

    var body: some View {
        HStack(spacing: 8) {
            Text(title.uppercased())
                .font(.footnote.weight(.semibold))
                .tracking(0.4)
                .foregroundStyle(.secondary)
                .accessibilityAddTraits(.isHeader)
            Spacer(minLength: 8)
            trailing()
        }
        .padding(.horizontal, 4)
    }
}

extension CardLabel where Trailing == EmptyView {
    init(_ title: String) {
        self.init(title: title, trailing: { EmptyView() })
    }
}

/// "Listed", "Sold": a small chip in the status's colors.
struct StatusChip: View {
    var status: ItemStatus

    var body: some View {
        Text(status.title)
            .font(.caption.weight(.semibold))
            .foregroundStyle(status.ink)
            .padding(.horizontal, 9)
            .padding(.vertical, 3)
            .background(status.fill, in: .capsule)
    }
}

/// A photo, cropped to fill its frame. Decodes a small copy off the main thread. With no photo,
/// the category's symbol on a soft berry tile.
struct PhotoTile: View {
    var data: Data?
    var symbol: String = "hanger"
    /// The longest side to decode, in pixels.
    var maxPixel: CGFloat = 700

    @State private var image: UIImage?

    var body: some View {
        Rectangle()
            .fill(Brand.tint)
            .overlay {
                if let image {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                } else {
                    Image(systemName: symbol)
                        .font(.system(size: 34, weight: .light))
                        .foregroundStyle(Brand.ink)
                }
            }
            .clipped()
            .task(id: data) {
                image = await ImageTools.thumbnail(data, maxPixel: maxPixel)
            }
            .accessibilityHidden(true)
    }
}

/// A big number with a caption under it, for the Closet's and Sales' summary cards.
struct StatValue: View {
    var value: String
    var label: String

    var body: some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.title2.bold())
                .monospacedDigit()
            Text(label)
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
    }
}
