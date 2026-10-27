# Rehome

A native iPhone and iPad app for selling clothes: keep the closet of what's for sale, photograph
each piece, set its size, condition and price, have Apple Intelligence write the post, and hand it
off to Facebook Marketplace. Styled like the Hearth apps, but standalone (no HearthKit, household
or paywall). Design: the "Rehome iOS Prototype" canvas.

## Build

- Xcode 26 or later, iOS 26 deployment target, Swift with MainActor default isolation.
- Open `Rehome.xcodeproj`. The `Rehome` and `RehomeTests` folders are synchronized groups, so new
  files are picked up without editing the project.
- Signing & Capabilities: team BH8R3BX5WF. iCloud (CloudKit) with container
  `iCloud.com.stephenwarren.rehome` and Push Notifications are in `Rehome.entitlements`; let Xcode
  register the container the first time. Without iCloud the closet stays on the device.
- In the simulator, Settings › Developer › Add Sample Closet fills in example items.

## How it's built

| Folder | What's there |
| --- | --- |
| `App/` | `RehomeApp` (SwiftData container synced with CloudKit), `AppRouter` (tab, paths, sheets), `RootTabView` |
| `Models/` | `Item` and `ItemPhoto` (SwiftData), status, condition, size system and category enums, `Money` |
| `DesignSystem/` | Brand colors, the color header (`HeaderGradient`, `RehomeScreen`), cards, chips, photo tiles, sheet buttons, menu icons, the top bar |
| `Features/Closet` | The Closet tab: counts, filter, search, item grid |
| `Features/Item` | An item's page: photos, details, listing, post, notes; Drop Price, Mark as Sold, Delete |
| `Features/Editor` | New Item / Edit sheet working on an `ItemDraft`; photo strip (camera and library) and size chips |
| `Features/Description` | The post writer: tone, what to include, editable text |
| `Features/Post` | Ready to Post: save photos, copy the post, open Facebook, mark listed; share to a group |
| `Features/Sales` | The Sales tab: monthly earnings by week (Swift Charts), averages, recently sold |
| `Features/Settings` | Pickup details, post defaults, erase |
| `Services/` | `DescriptionWriter` (Foundation Models, with a template fallback), `ImageTools` |

### Data

- `Item` keeps prices in cents. Photos are `ItemPhoto` records with external storage, resized to
  2048 px JPEGs before saving. Everything syncs through the private CloudKit database, so every
  property has a default and relationships are optional.
- The editor never edits an `Item` directly: it fills an `ItemDraft` and copies it in on Save.

### Posts

`DescriptionWriter.write` asks the on-device model (`LanguageModelSession`) for the description
paragraph only, from the item's facts. Measurements, price, pickup details and hashtags are added
by code, so the model can't get them wrong. When Apple Intelligence isn't available, the template
writes the paragraph.

### Facebook

Meta doesn't let personal apps create Marketplace listings or post to groups, so Ready to Post is a
handoff: photos go to the library (add-only access), the post goes on the clipboard, and Open
Facebook launches `fb://marketplace` (or the web page). Share to a group sends the photos through
the share sheet.
