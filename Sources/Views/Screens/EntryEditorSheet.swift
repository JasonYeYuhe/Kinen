import SwiftUI
import SwiftData
import PhotosUI

struct EntryEditorSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let entry: JournalEntry? // nil = new entry

    @State private var content: String
    @State private var title: String
    @State private var mood: Mood?
    @State private var template: JournalTemplate?
    @State private var templateResponses: [UUID: String] = [:]
    @State private var aiPromptSuggestion: String?
    @State private var showingTemplatePicker = false
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var photoData: Data?
    @AppStorage("defaultMoodEnabled") private var defaultMoodEnabled = true
    @State private var crisisAlert: CrisisDetector.CrisisAlert?
    @State private var showCrisisAlert = false
    @State private var writingStartTime: Date?
    @State private var elapsedTime: TimeInterval = 0
    @State private var timer: Timer?

    init(entry: JournalEntry?) {
        self.entry = entry
        _content = State(initialValue: entry?.content ?? "")
        _title = State(initialValue: entry?.title ?? "")
        _mood = State(initialValue: entry?.mood)
        _template = State(initialValue: entry?.template)
        _photoData = State(initialValue: entry?.photoData)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    titleSection
                    if defaultMoodEnabled {
                        moodSection
                    }
                    aiPromptBanner
                    templateBanner
                    Divider()

                    if let template, template != .freeWrite, template != .morningPages {
                        templatePromptsView(template: template)
                    } else {
                        freeWriteEditor
                    }

                    photoSection
                    footerStats
                }
                .padding()
            }
            .navigationTitle(entry == nil ? "New Entry" : "Edit Entry")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { stopTimer(); dismiss() }
                }
                ToolbarItemGroup(placement: .primaryAction) {
                    Button("Save") { save() }
                        .disabled(effectiveContent.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        .fontWeight(.semibold)
                }
            }
            .sheet(isPresented: $showingTemplatePicker) {
                TemplatePickerSheet { selected in
                    template = selected
                    if entry == nil && title.isEmpty {
                        title = selected.name + " — " + Date().formatted(date: .abbreviated, time: .omitted)
                    }
                }
            }
            .onAppear {
                startTimer()
                if entry == nil { generateNewPrompt() }
            }
            .onChange(of: mood) { generateNewPrompt() }
            .onDisappear { stopTimer() }
            .overlay {
                if showCrisisAlert, let alert = crisisAlert {
                    Color.black.opacity(0.4)
                        .ignoresSafeArea()
                        .overlay {
                            CrisisAlertView(alert: alert) {
                                showCrisisAlert = false
                            }
                            .padding()
                        }
                }
            }
        }
        #if os(macOS)
        .frame(minWidth: 560, minHeight: 500)
        #else
        .presentationDetents([.large])
        #endif
    }

    // MARK: - Title

    private var titleSection: some View {
        TextField("Title (optional)", text: $title)
            .font(.title2)
            .fontWeight(.semibold)
            .textFieldStyle(.plain)
    }

    // MARK: - Mood

    private var moodSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("How are you feeling?")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            MoodPicker(selectedMood: $mood)
        }
    }

    // MARK: - AI Prompt Suggestion

    @ViewBuilder
    private var aiPromptBanner: some View {
        if entry == nil, let prompt = aiPromptSuggestion, content.isEmpty {
            HStack(alignment: .top, spacing: 8) {
                Image(systemName: "sparkles")
                    .foregroundStyle(.purple)
                    .font(.caption)
                Text(prompt)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .italic()
                Spacer()
                Button(action: { generateNewPrompt() }) {
                    Image(systemName: "arrow.clockwise")
                        .font(.caption)
                }
                .buttonStyle(.borderless)
                .help("Get a different suggestion")
            }
            .padding(10)
            .background(.purple.opacity(0.06))
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .onTapGesture {
                content = prompt + "\n\n"
                aiPromptSuggestion = nil
            }
        }
    }

    private func generateNewPrompt() {
        aiPromptSuggestion = PromptGenerator.generatePrompt(
            currentMood: mood,
            recentEntries: []
        )
    }

    // MARK: - Template Banner

    private var templateBanner: some View {
        HStack {
            if let template {
                HStack(spacing: 6) {
                    Image(systemName: template.icon)
                        .foregroundStyle(template.color)
                    Text(template.name)
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(template.color.opacity(0.1))
                .clipShape(Capsule())

                Button("Change") { showingTemplatePicker = true }
                    .font(.caption)
            } else if entry == nil {
                Button(action: { showingTemplatePicker = true }) {
                    Label("Use a Template", systemImage: "doc.text")
                        .font(.subheadline)
                }
                .buttonStyle(.bordered)
                .tint(.purple)
            }

            Spacer()

            VoiceRecorderButton(transcribedText: $content)
        }
    }

    // MARK: - Template Prompts View

    private func templatePromptsView(template: JournalTemplate) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            ForEach(template.prompts) { prompt in
                VStack(alignment: .leading, spacing: 6) {
                    if let promptTitle = prompt.title {
                        Text(promptTitle)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundStyle(template.color)
                    }

                    TextEditor(text: binding(for: prompt))
                        .font(.body)
                        .frame(minHeight: 80)
                        .scrollContentBackground(.hidden)
                        .padding(8)
                        .background(Color.secondary.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .overlay(alignment: .topLeading) {
                            if (templateResponses[prompt.id] ?? "").isEmpty {
                                Text(prompt.placeholder)
                                    .foregroundStyle(.tertiary)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 16)
                                    .allowsHitTesting(false)
                            }
                        }
                }
            }
        }
    }

    // MARK: - Free Write Editor

    private var freeWriteEditor: some View {
        TextEditor(text: $content)
            .font(.body)
            .frame(minHeight: 200)
            .scrollContentBackground(.hidden)
    }

    // MARK: - Photo Section

    private var photoSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            PhotosPicker(selection: $selectedPhoto, matching: .images) {
                Label("Add Photo", systemImage: "photo.badge.plus")
                    .font(.subheadline)
            }
            .buttonStyle(.bordered)
            .onChange(of: selectedPhoto) {
                Task {
                    if let data = try? await selectedPhoto?.loadTransferable(type: Data.self) {
                        photoData = data
                    }
                }
            }

            if let photoData {
                #if os(macOS)
                if let nsImage = NSImage(data: photoData) {
                    Image(nsImage: nsImage)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 200)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .overlay(alignment: .topTrailing) {
                            removePhotoButton
                        }
                }
                #else
                if let uiImage = UIImage(data: photoData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 200)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .overlay(alignment: .topTrailing) {
                            removePhotoButton
                        }
                }
                #endif
            }
        }
    }

    private var removePhotoButton: some View {
        Button(action: { self.photoData = nil; selectedPhoto = nil }) {
            Image(systemName: "xmark.circle.fill")
                .font(.title3)
                .foregroundStyle(.white)
                .shadow(radius: 2)
        }
        .buttonStyle(.borderless)
        .padding(4)
    }

    // MARK: - Footer Stats

    private var footerStats: some View {
        HStack {
            // Writing timer
            HStack(spacing: 4) {
                Image(systemName: "timer")
                    .font(.caption2)
                Text(formatDuration(elapsedTime))
                    .font(.caption)
                    .monospacedDigit()
            }
            .foregroundStyle(.secondary)

            Spacer()

            // Word count
            Text("\(effectiveContent.split(separator: " ").count) words")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
    }

    // MARK: - Helpers

    private var effectiveContent: String {
        if template != nil && template != .freeWrite && template != .morningPages {
            return templateResponses.values.joined(separator: "\n\n")
        }
        return content
    }

    private func binding(for prompt: TemplatePrompt) -> Binding<String> {
        Binding(
            get: { templateResponses[prompt.id] ?? "" },
            set: { templateResponses[prompt.id] = $0 }
        )
    }

    private func startTimer() {
        writingStartTime = Date()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            Task { @MainActor in
                if let start = writingStartTime {
                    elapsedTime = Date().timeIntervalSince(start)
                }
            }
        }
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    private func formatDuration(_ interval: TimeInterval) -> String {
        let minutes = Int(interval) / 60
        let seconds = Int(interval) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    // MARK: - Save

    private func save() {
        stopTimer()

        // Crisis detection — check before saving
        if let alert = CrisisDetector.check(effectiveContent) {
            crisisAlert = alert
            showCrisisAlert = true
            // Still save the entry — don't block journaling, just show resources
        }

        // Build final content from template responses or free-form
        var finalContent: String
        if let template, template != .freeWrite, template != .morningPages {
            let parts = template.prompts.compactMap { prompt -> String? in
                guard let response = templateResponses[prompt.id], !response.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return nil }
                if let promptTitle = prompt.title {
                    return "**\(promptTitle)**\n\(response)"
                }
                return response
            }
            finalContent = parts.joined(separator: "\n\n")
        } else {
            finalContent = content
        }

        let trimmed = finalContent.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        if let entry {
            entry.content = trimmed
            entry.title = title.isEmpty ? nil : title
            entry.mood = mood
            entry.template = template
            entry.updatedAt = Date()
            entry.wordCount = trimmed.split(separator: " ").count
            entry.photoData = photoData
            entry.writingDuration += elapsedTime
        } else {
            let newEntry = JournalEntry(
                content: trimmed,
                title: title.isEmpty ? nil : title,
                mood: mood,
                template: template
            )
            newEntry.photoData = photoData
            newEntry.writingDuration = elapsedTime
            modelContext.insert(newEntry)

            // Record writing session
            let session = WritingSession(entryId: newEntry.id)
            session.finish(wordCount: trimmed.split(separator: " ").count)
            modelContext.insert(session)

            // AI Journaling Loop (5-step) in background
            Task {
                await AIJournalingLoop.shared.processEntry(newEntry, in: modelContext)
            }
        }

        dismiss()
    }
}
