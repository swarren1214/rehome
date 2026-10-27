import SwiftUI

/// Writes the Facebook post from the item's details: pick a tone and what to include, then edit
/// the text freely. Written on device with Apple Intelligence when it's available.
struct DescriptionView: View {
    @Binding var draft: ItemDraft

    @AppStorage(SettingsKey.descriptionTone) private var toneRaw = DescriptionTone.friendly.rawValue
    @AppStorage(SettingsKey.includeMeasurements) private var includeMeasurements = true
    @AppStorage(SettingsKey.includePickup) private var includePickup = true
    @AppStorage(SettingsKey.includeHashtags) private var includeHashtags = false
    @AppStorage(SettingsKey.pickupDetails) private var pickupDetails = ""

    @State private var isWriting = false
    @State private var writeTask: Task<Void, Never>?

    private var tone: DescriptionTone { DescriptionTone(rawValue: toneRaw) ?? .friendly }

    private var options: DescriptionOptions {
        DescriptionOptions(
            tone: tone,
            includeMeasurements: includeMeasurements,
            includePickup: includePickup,
            includeHashtags: includeHashtags,
            pickupDetails: pickupDetails
        )
    }

    var body: some View {
        Form {
            Section {
                Picker("Tone", selection: $toneRaw) {
                    ForEach(DescriptionTone.allCases) { tone in
                        Text(tone.title).tag(tone.rawValue)
                    }
                }
                .pickerStyle(.segmented)
            } header: {
                Text("Tone")
            }

            Section {
                ZStack(alignment: .topLeading) {
                    TextEditor(text: $draft.listingText)
                        .frame(minHeight: 220)
                        .opacity(isWriting ? 0.35 : 1)
                        .disabled(isWriting)
                    if isWriting {
                        HStack(spacing: 8) {
                            ProgressView()
                            Text("Writing…")
                                .foregroundStyle(.secondary)
                        }
                        .padding(.top, 8)
                    }
                }
                HStack {
                    Image(systemName: "sparkles")
                        .accessibilityHidden(true)
                    Text(DescriptionWriter.isModelAvailable ? "Written on device · \(draft.listingText.count) characters" : "\(draft.listingText.count) characters")
                    Spacer()
                    Button("Rewrite", systemImage: "arrow.clockwise") { write() }
                        .buttonStyle(.bordered)
                        .disabled(isWriting)
                }
                .font(.footnote)
                .foregroundStyle(.secondary)
                .tint(.primary)
            } header: {
                Text("Post")
            } footer: {
                if !DescriptionWriter.isModelAvailable {
                    Text("Turn on Apple Intelligence in Settings for posts written in your tone. Until then Rehome starts you from a template.")
                }
            }

            Section {
                Toggle(isOn: $includeMeasurements) {
                    toggleLabel("Measurements", "Pit to pit, length and the like")
                }
                Toggle(isOn: $includePickup) {
                    toggleLabel("Pickup details", pickupDetails.isEmpty ? "Add yours in Settings" : pickupDetails)
                }
                .disabled(pickupDetails.isEmpty)
                Toggle(isOn: $includeHashtags) {
                    toggleLabel("Hashtags", "Helps people find it in search")
                }
            } header: {
                Text("Include")
            }
        }
        .navigationTitle("Description")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            if draft.listingText.isEmpty { write() }
        }
        .onChange(of: options) { write() }
        .onDisappear { writeTask?.cancel() }
    }

    private func toggleLabel(_ title: String, _ hint: String) -> some View {
        VStack(alignment: .leading, spacing: 1) {
            Text(title)
            Text(hint)
                .font(.footnote)
                .foregroundStyle(.secondary)
                .lineLimit(2)
        }
    }

    private func write() {
        writeTask?.cancel()
        let facts = draft.facts
        let options = options
        isWriting = true
        writeTask = Task {
            let text = await DescriptionWriter.write(facts, options: options)
            guard !Task.isCancelled else { return }
            draft.listingText = text
            isWriting = false
        }
    }
}
