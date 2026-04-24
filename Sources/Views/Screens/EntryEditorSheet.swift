import SwiftUI
import SwiftData
import PhotosUI
import StoreKit

struct EntryEditorSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(\.requestReview) private var requestReview

    let entry: JournalEntry? // nil = new entry

    @State private var content: String
    @State private var title: String
    @State private var mood: Mood?
    @State private var template: JournalTemplate?
    @State private var templateResponses: [String: String] = [:]
    @State private var aiPromptSuggestion: String?
    @State private var showingTemplatePicker = false
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var photoData: Data?
    @AppStorage("defaultMoodEnabled") private var defaultMoodEnabled = true
    @AppStorage("enableAutoSentiment") private var enableAutoSentiment = true
    @AppStorage("enableAutoTags") private var enableAutoTags = true
    @AppStorage("dailyWordGoal") private var dailyWordGoal = 0
    @State private var entryTags: [Tag] = []
    @State private var suggestedMood: Mood?
    @State private var moodSuggestionTask: Task<Void, Never>?
    @State private var showDuplicateAlert = false
    @State private var selectedJournal: Journal?
    @Query(sort: \Journal.createdAt) private var journals: [Journal]
    @State private var crisisAlert: CrisisDetector.CrisisAlert?
    @State private var showCrisisAlert = false
    @State private var toastMessage: String?
    @State private var writingStartTime: Date?
    @State private var elapsedTime: TimeInterval = 0
    @State private var timer: Timer?
    @State private var locationWeather = LocationWeatherService.shared
    @AppStorage("enableLocationWeather") private var enableLocationWeather = false
    @State private var fetchedLocationWeather: (location: String?, weather: String?) = (nil, nil)

    init(entry: JournalEntry?) {
        self.entry = entry
        _content = State(initialValue: entry?.content ?? "")
        _title = State(initialValue: entry?.title ?? "")
        _mood = State(initialValue: entry?.mood)
        _template = State(initialValue: entry?.template)
        _photoData = State(initialValue: entry?.photoData)
        _entryTags = State(initialValue: entry?.tags ?? [])
        _selectedJournal = State(initialValue: entry?.journal)

        // Restore template responses from saved content for template entries
        if let entry, let template = entry.template,
           template != .freeWrite, template != .morningPages {
            let prompts = template.prompts
            let parsed = Self.parseTemplateContent(entry.content, prompts: prompts)
            _templateResponses = State(initialValue: parsed)
        }
    }

    /// Parse saved content back into per-prompt responses.
    /// Primary format (new): "<!-- promptId -->\n**Title**\nresponse"
    /// Legacy fallback: "**Title**\nresponse" (matched by current-locale title)
    private static let markerRegex = try! NSRegularExpression(pattern: "<!-- ([\\w-]+) -->")

    static func parseTemplateContent(_ content: String, prompts: [TemplatePrompt]) -> [String: String] {
        var responses: [String: String] = [:]

        // Try stable ID markers first: <!-- promptId -->
        let promptIds = Set(prompts.map(\.id))
        let regex = markerRegex
        let nsContent = content as NSString
        let matches = regex.matches(in: content, range: NSRange(location: 0, length: nsContent.length))

        // Filter to only markers that match known prompt IDs
        var positions: [(id: String, markerEnd: String.Index)] = []
        for match in matches {
            let idRange = match.range(at: 1)
            let matchedId = nsContent.substring(with: idRange)
            if promptIds.contains(matchedId) {
                let utf16End = match.range.location + match.range.length
                let endIndex = String.Index(utf16Offset: utf16End, in: content)
                guard endIndex <= content.endIndex else { continue }
                positions.append((id: matchedId, markerEnd: endIndex))
            }
        }

        if !positions.isEmpty {
            // Parse using stable markers
            for (i, pos) in positions.enumerated() {
                let textEnd: String.Index
                if i + 1 < positions.count {
                    // Find the start of the next marker (go back to its <!-- )
                    let nextMatch = matches[i + 1]
                    let utf16Start = nextMatch.range.location
                    textEnd = min(String.Index(utf16Offset: utf16Start, in: content), content.endIndex)
                } else {
                    textEnd = content.endIndex
                }
                var text = String(content[pos.markerEnd..<textEnd])
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                // Strip the localized bold title line if present (first line matching **...**)
                if text.hasPrefix("**"), let titleEnd = text.range(of: "**", range: text.index(text.startIndex, offsetBy: 2)..<text.endIndex) {
                    text = String(text[titleEnd.upperBound...])
                        .trimmingCharacters(in: .whitespacesAndNewlines)
                }
                responses[pos.id] = text
            }
            return responses
        }

        // Legacy fallback: match by current-locale **Title**
        var headerPositions: [(id: String, range: Range<String.Index>)] = []
        for prompt in prompts {
            if let title = prompt.title, let range = content.range(of: "**\(title)**") {
                headerPositions.append((id: prompt.id, range: range))
            }
        }
        if headerPositions.isEmpty {
            if let first = prompts.first {
                responses[first.id] = content
            }
            return responses
        }
        headerPositions.sort { $0.range.lowerBound < $1.range.lowerBound }
        for (i, pos) in headerPositions.enumerated() {
            let textStart = pos.range.upperBound
            let textEnd = i + 1 < headerPositions.count ? headerPositions[i + 1].range.lowerBound : content.endIndex
            responses[pos.id] = String(content[textStart..<textEnd])
                .trimmingCharacters(in: .whitespacesAndNewlines)
        }
        return responses
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

                    // Tags
                    VStack(alignment: .leading, spacing: 6) {
                        Text(String(localized: "editor.tags.title"))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        TagEditor(selectedTags: $entryTags)
                    }

                    // Journal notebook picker
                    if !journals.isEmpty {
                        VStack(alignment: .leading, spacing: 6) {
                            Text(String(localized: "editor.journal"))
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    journalChip(nil, label: String(localized: "editor.journal.default"))
                                    ForEach(journals) { journal in
                                        journalChip(journal, label: journal.name)
                                    }
                                }
                            }
                        }
                    }

                    footerStats
                }
                .padding()
            }
            .navigationTitle(entry == nil ? String(localized: "editor.title.new") : String(localized: "editor.title.edit"))
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(String(localized: "editor.cancel")) { stopTimer(); dismiss() }
                }
                ToolbarItemGroup(placement: .primaryAction) {
                    Button(String(localized: "editor.save")) { save() }
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
                if entry == nil {
                    generateNewPrompt()
                    if enableLocationWeather {
                        Task { await fetchedLocationWeather = locationWeather.fetchLocationAndWeather() }
                    }
                }
            }
            .onChange(of: mood) { generateNewPrompt() }
            .onChange(of: content) { debounceMoodSuggestion() }
            .onDisappear { stopTimer(); moodSuggestionTask?.cancel() }
            .alert(String(localized: "editor.duplicate.title"), isPresented: $showDuplicateAlert) {
                Button(String(localized: "general.cancel"), role: .cancel) {}
                Button(String(localized: "editor.duplicate.saveAnyway")) { save() }
            } message: {
                Text(String(localized: "editor.duplicate.message"))
            }
            .toast($toastMessage)
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
        .frame(minWidth: 460, idealWidth: 600, minHeight: 400, idealHeight: 600)
        #else
        .presentationDetents([.large])
        #endif
    }

    // MARK: - Title

    private var titleSection: some View {
        TextField(String(localized: "editor.title.placeholder"), text: $title)
            .font(.title2)
            .fontWeight(.semibold)
            .textFieldStyle(.plain)
    }

    // MARK: - Mood

    private var moodSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(String(localized: "editor.mood.question"))
                .font(.subheadline)
                .foregroundStyle(.secondary)
            MoodPicker(selectedMood: $mood)

            // AI mood suggestion
            if mood == nil, let suggested = suggestedMood {
                Button {
                    withAnimation(.spring(duration: 0.3)) { mood = suggested }
                    suggestedMood = nil
                    HapticManager.selection()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "sparkles")
                            .font(.caption2)
                        Text(String(format: String(localized: "editor.mood.suggestion"), suggested.emoji, suggested.label))
                            .font(.caption)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(.purple.opacity(0.1))
                    .foregroundStyle(.purple)
                    .clipShape(Capsule())
                }
                .buttonStyle(.plain)
                .transition(.scale.combined(with: .opacity))
                .accessibilityLabel(String(format: String(localized: "editor.mood.suggestion.a11y"), suggested.label))
            }
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
                .help(String(localized: "editor.aiprompt.regenerate.accessibility"))
                .accessibilityLabel(String(localized: "editor.aiprompt.regenerate.accessibility"))
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
        guard !showingTemplatePicker else { return }
        aiPromptSuggestion = PromptGenerator.generatePrompt(
            currentMood: mood,
            recentEntries: []
        )
    }

    /// Cancels in-flight AI tasks before opening the template picker.
    /// Without this, a debounced mood-suggestion Task can resume mid-presentation
    /// and trigger a SwiftUI layout race that crashes silently on macOS.
    private func presentTemplatePicker() {
        moodSuggestionTask?.cancel()
        moodSuggestionTask = nil
        showingTemplatePicker = true
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

                Button(String(localized: "editor.template.change")) { presentTemplatePicker() }
                    .font(.caption)
            } else if entry == nil {
                Button(action: { presentTemplatePicker() }) {
                    Label(String(localized: "editor.template.use"), systemImage: "doc.text")
                        .font(.subheadline)
                }
                .buttonStyle(.bordered)
                .tint(.purple)
            }

            Spacer()

            VoiceRecorderButton(transcribedText: $content) { error in
                toastMessage = error
            }
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
                Label(String(localized: "editor.photo.add"), systemImage: "photo.badge.plus")
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
        .accessibilityLabel(String(localized: "editor.photo.remove.accessibility"))
    }

    // MARK: - Footer Stats

    private var footerStats: some View {
        let currentWords = effectiveContent.split(separator: " ").count
        return HStack {
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

            // Word count goal progress
            if dailyWordGoal > 0 {
                let progress = min(Double(currentWords) / Double(dailyWordGoal), 1.0)
                HStack(spacing: 6) {
                    ZStack {
                        Circle()
                            .stroke(.gray.opacity(0.2), lineWidth: 2)
                        Circle()
                            .trim(from: 0, to: progress)
                            .stroke(progress >= 1.0 ? Color.green : Color.purple, style: StrokeStyle(lineWidth: 2, lineCap: .round))
                            .rotationEffect(.degrees(-90))
                    }
                    .frame(width: 16, height: 16)
                    Text("\(currentWords)/\(dailyWordGoal)")
                        .font(.caption2)
                        .monospacedDigit()
                        .foregroundStyle(progress >= 1.0 ? .green : .secondary)
                }
                .sensoryFeedback(.success, trigger: currentWords >= dailyWordGoal)
            } else {
                // Just word count
                Text("\(currentWords) \(String(localized: "general.words"))")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
    }

    // MARK: - Helpers

    private var effectiveContent: String {
        if let template, template != .freeWrite, template != .morningPages {
            return template.prompts.compactMap { prompt in
                guard let response = templateResponses[prompt.id],
                      !response.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return nil }
                return response
            }.joined(separator: "\n\n")
        }
        return content
    }

    private func binding(for prompt: TemplatePrompt) -> Binding<String> {
        Binding(
            get: { templateResponses[prompt.id] ?? "" },
            set: { templateResponses[prompt.id] = $0 }
        )
    }

    private func journalChip(_ journal: Journal?, label: String) -> some View {
        let isSelected = selectedJournal?.id == journal?.id
        let color = journal?.color ?? .purple
        return Button {
            selectedJournal = journal
            HapticManager.selection()
        } label: {
            HStack(spacing: 4) {
                Image(systemName: journal?.icon ?? "tray.full")
                    .font(.caption)
                Text(label)
                    .font(.caption)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(isSelected ? color.opacity(0.2) : .secondary.opacity(0.08))
            .foregroundStyle(isSelected ? color : .secondary)
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
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

    // MARK: - Mood Suggestion

    private func debounceMoodSuggestion() {
        moodSuggestionTask?.cancel()
        let text = effectiveContent
        guard mood == nil, enableAutoSentiment, text.count >= 50 else {
            suggestedMood = nil
            return
        }
        moodSuggestionTask = Task {
            try? await Task.sleep(for: .seconds(2))
            guard !Task.isCancelled else { return }
            let score = await SentimentAnalyzer.shared.analyzeSentiment(text)
            guard !Task.isCancelled else { return }
            await MainActor.run {
                suggestedMood = moodFromSentiment(score)
            }
        }
    }

    private func moodFromSentiment(_ score: Double) -> Mood {
        if score < -0.4 { return .terrible }
        if score < -0.1 { return .bad }
        if score < 0.1 { return .neutral }
        if score < 0.4 { return .good }
        return .great
    }

    // MARK: - Duplicate Detection

    /// Normalize text for similarity comparison: strip template markers and formatting.
    private static func normalizeForComparison(_ text: String) -> String {
        var result = text
        // Remove template markers like <!-- promptId -->
        result = result.replacingOccurrences(of: "<!--[^>]*-->", with: "", options: .regularExpression)
        // Remove bold markers **text**
        result = result.replacingOccurrences(of: "\\*\\*[^*]*\\*\\*", with: "", options: .regularExpression)
        return result.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func checkForDuplicate(_ trimmed: String) -> Bool {
        guard entry == nil else { return false } // only for new entries
        let normalized = String(Self.normalizeForComparison(trimmed).prefix(200))
        guard !normalized.isEmpty else { return false }

        let oneHourAgo = Date().addingTimeInterval(-3600)
        let recentEntries = (try? modelContext.fetch(
            FetchDescriptor<JournalEntry>(predicate: #Predicate { $0.createdAt > oneHourAgo })
        )) ?? []

        for existing in recentEntries {
            let existingNorm = String(Self.normalizeForComparison(existing.content).prefix(200))
            guard !existingNorm.isEmpty else { continue }
            let similarity = Self.similarity(normalized, existingNorm)
            if similarity > 0.9 { return true }
        }
        return false
    }

    /// Simple character-level similarity (Dice coefficient on bigrams).
    private static func similarity(_ a: String, _ b: String) -> Double {
        let aBigrams = bigrams(a)
        let bBigrams = bigrams(b)
        guard !aBigrams.isEmpty && !bBigrams.isEmpty else { return 0 }
        let intersection = aBigrams.intersection(bBigrams).count
        return 2.0 * Double(intersection) / Double(aBigrams.count + bBigrams.count)
    }

    private static func bigrams(_ s: String) -> Set<String> {
        let chars = Array(s.lowercased())
        guard chars.count >= 2 else { return [] }
        return Set((0..<chars.count - 1).map { String(chars[$0]) + String(chars[$0 + 1]) })
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
                // Use stable prompt ID as locale-independent marker
                var section = "<!-- \(prompt.id) -->"
                if let promptTitle = prompt.title {
                    section += "\n**\(promptTitle)**"
                }
                section += "\n\(response)"
                return section
            }
            finalContent = parts.joined(separator: "\n\n")
        } else {
            finalContent = content
        }

        let trimmed = finalContent.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        // Duplicate detection for new entries
        if entry == nil && !showDuplicateAlert && checkForDuplicate(trimmed) {
            showDuplicateAlert = true
            return // will re-enter save() if user confirms
        }

        if let entry {
            // Snapshot current content for undo before overwriting
            if entry.content != trimmed {
                entry.snapshotForUndo()
            }
            entry.content = trimmed
            entry.title = title.isEmpty ? nil : title
            entry.mood = mood
            entry.template = template
            entry.updatedAt = Date()
            entry.wordCount = trimmed.split(separator: " ").count
            entry.photoData = photoData
            entry.writingDuration += elapsedTime
            entry.tags = entryTags
            entry.journal = selectedJournal
        } else {
            let newEntry = JournalEntry(
                content: trimmed,
                title: title.isEmpty ? nil : title,
                mood: mood,
                template: template
            )
            newEntry.photoData = photoData
            newEntry.writingDuration = elapsedTime
            newEntry.tags = entryTags
            newEntry.location = fetchedLocationWeather.location
            newEntry.weather = fetchedLocationWeather.weather
            newEntry.latitude = locationWeather.currentLatitude
            newEntry.longitude = locationWeather.currentLongitude
            newEntry.journal = selectedJournal
            modelContext.insert(newEntry)

            // Record writing session
            let session = WritingSession(entryId: newEntry.id)
            session.finish(wordCount: trimmed.split(separator: " ").count)
            modelContext.insert(session)

            // AI Journaling Loop (5-step) in background
            let sentiment = enableAutoSentiment
            let tags = enableAutoTags
            Task {
                await AIJournalingLoop.shared.processEntry(newEntry, in: modelContext, enableSentiment: sentiment, enableTags: tags)
            }

            // Request App Store review after 5th entry, at most once per 60 days
            requestAppReview()
        }

        HapticManager.notification(.success)
        WidgetDataProvider.syncAndReload(from: modelContext)
        dismiss()
    }

    private func requestAppReview() {
        let entryCountKey = "totalNewEntryCount"
        let lastReviewKey = "lastReviewRequestDate"
        let count = UserDefaults.standard.integer(forKey: entryCountKey) + 1
        UserDefaults.standard.set(count, forKey: entryCountKey)

        guard count >= 5 else { return }

        let lastRequest = UserDefaults.standard.object(forKey: lastReviewKey) as? Date ?? .distantPast
        guard Date().timeIntervalSince(lastRequest) > 60 * 86400 else { return } // 60 days

        UserDefaults.standard.set(Date(), forKey: lastReviewKey)
        requestReview()
    }
}
