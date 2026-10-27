# AGENT.md — Rehome

Rules for anyone (person or agent) changing Rehome's code. See README.md for how the app is built.
Rehome follows the Hearth apps' conventions (see ~/Developer/trove/AGENT.md) without being part of
Hearth: no HearthKit copies, no household, no paywall.

## Design for every device

Layouts must work on every iPhone size, foldables, iPad full screen and in windows, portrait and
landscape, and at large Dynamic Type sizes. Lay out from the space available (size classes,
adaptive grids), never from a device name or fixed width.

## Prefer native

Use system controls, `Form`/`List`, `Menu`, `Picker`, sheets, toolbars, search, `ShareLink`,
`PhotosPicker`, SF Symbols, system colors and Dynamic Type. Build custom only when nothing native
does the job.

## App color

The berry (`Brand.berry`, root `.tint`) is for large titles and big numbers, stand-alone icons,
and components (toggles, charts, selection highlights, `SheetDoneButton`, prominent buttons with
white text). Never for menus, running text, headers, small icons or text buttons in rows: those use
`.primary`/`.secondary`. Put `.tint(.primary)` on menus, menu pickers and text buttons in rows.

- A button's icon is always the same color as its text.
- Menu icons use `Image.menuIcon` / `Button(_:menuIcon:)` so they match their text.

## The top bar and the color header

- Main screens use `RehomeScreen` (the berry header fading into the gray background, large white
  title) and `.rehomeToolbar { … }`: the screen's actions and `SettingsButton` share one glass
  capsule at the top right, Settings last, icons white over the header.
- The iPhone tab bar shows icons only; iPad's sidebar shows icon and name, icon in the text color.

## Sheet buttons

A sheet with Done and Cancel uses `SheetDoneButton` (berry circle, white checkmark) in
`.confirmationAction` and `SheetCancelButton` (X in the text color) in `.cancellationAction`.

## Confirmations

Confirm with a native `.alert` (destructive role + Cancel), never a confirmation dialog or popover.
Alert buttons use the label color (set once in `RehomeApp.init`); only destructive ones are red.

## iCloud

The closet syncs through SwiftData's CloudKit integration in the private database. New model
properties need defaults (or are optional), relationships stay optional, no unique constraints.
Screens that show the closet support pull to refresh.

## Privacy

Only an item's own facts go to the description model; nothing about the person. Photo library
access is add-only. Pickup details should name an area, never an address.
