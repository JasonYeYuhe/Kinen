import XCTest
import SwiftData
@testable import Kinen

@MainActor
final class SampleDataLoaderTests: XCTestCase {

    private func makeContext() throws -> ModelContext {
        let schema = Schema([
            JournalEntry.self,
            Tag.self,
            EntryInsight.self,
            WritingSession.self,
            Journal.self,
        ])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [config])
        return ModelContext(container)
    }

    private func fetchAllEntries(_ context: ModelContext) throws -> [JournalEntry] {
        try context.fetch(FetchDescriptor<JournalEntry>())
    }

    func testLoadInsertsExpectedEntryCount() throws {
        let ctx = try makeContext()
        let inserted = SampleDataLoader.loadSampleEntries(into: ctx)
        XCTAssertEqual(inserted, SampleDataLoader.entryCount)
        XCTAssertEqual(SampleDataLoader.sampleEntryCount(in: ctx), SampleDataLoader.entryCount)
    }

    func testLoadIsIdempotent() throws {
        let ctx = try makeContext()
        _ = SampleDataLoader.loadSampleEntries(into: ctx)
        let secondInsert = SampleDataLoader.loadSampleEntries(into: ctx)
        XCTAssertEqual(secondInsert, 0)
        XCTAssertEqual(SampleDataLoader.sampleEntryCount(in: ctx), SampleDataLoader.entryCount)
    }

    func testClearRemovesOnlySampleEntries() throws {
        let ctx = try makeContext()
        // Insert a real user entry first
        let real = JournalEntry(content: "My real entry", title: "Real")
        ctx.insert(real)
        try ctx.save()

        _ = SampleDataLoader.loadSampleEntries(into: ctx)
        XCTAssertEqual(try fetchAllEntries(ctx).count, SampleDataLoader.entryCount + 1)

        let removed = SampleDataLoader.clearSampleEntries(from: ctx)
        XCTAssertEqual(removed, SampleDataLoader.entryCount)

        let remaining = try fetchAllEntries(ctx)
        XCTAssertEqual(remaining.count, 1)
        XCTAssertEqual(remaining.first?.content, "My real entry")
        XCTAssertEqual(remaining.first?.isSampleData, false)
        XCTAssertEqual(SampleDataLoader.sampleEntryCount(in: ctx), 0)
    }

    func testEverySampleEntryHasRequiredFields() throws {
        let ctx = try makeContext()
        _ = SampleDataLoader.loadSampleEntries(into: ctx)
        let entries = try fetchAllEntries(ctx)
        XCTAssertEqual(entries.count, SampleDataLoader.entryCount)

        for entry in entries {
            XCTAssertTrue(entry.isSampleData, "every sample entry must have isSampleData=true")
            XCTAssertNotNil(entry.mood, "sample entry missing mood: \(entry.displayTitle)")
            XCTAssertNotNil(entry.weather, "sample entry missing weather: \(entry.displayTitle)")
            XCTAssertNotNil(entry.location, "sample entry missing location: \(entry.displayTitle)")
            XCTAssertNotNil(entry.latitude, "sample entry missing latitude: \(entry.displayTitle)")
            XCTAssertNotNil(entry.longitude, "sample entry missing longitude: \(entry.displayTitle)")
            XCTAssertGreaterThanOrEqual(entry.safeTags.count, 2, "sample entry must have ≥2 tags")
            XCTAssertGreaterThanOrEqual(entry.safeInsights.count, 1, "sample entry must have ≥1 insight")
            XCTAssertGreaterThan(entry.wordCount, 5, "sample entry word count too low")
            XCTAssertGreaterThan(entry.writingDuration, 0, "sample entry writing duration must be set")
        }
    }

    func testGeographicDiversity() throws {
        let ctx = try makeContext()
        _ = SampleDataLoader.loadSampleEntries(into: ctx)
        let entries = try fetchAllEntries(ctx)
        let cities = Set(entries.compactMap { $0.location })
        // Must span 5 distinct cities so MapScreen has clusters
        XCTAssertGreaterThanOrEqual(cities.count, 5, "sample data must span ≥5 cities")
    }

    func testMoodDistributionContainsBothExtremes() throws {
        let ctx = try makeContext()
        _ = SampleDataLoader.loadSampleEntries(into: ctx)
        let entries = try fetchAllEntries(ctx)
        let moods = Set(entries.compactMap { $0.mood })
        XCTAssertTrue(moods.contains(.great), "must include great mood")
        XCTAssertTrue(moods.contains(.terrible) || moods.contains(.bad), "must include negative mood for variety")
        XCTAssertGreaterThanOrEqual(moods.count, 4, "must use ≥4 mood levels")
    }

    func testRealEntryDefaultsIsSampleDataFalse() {
        let entry = JournalEntry(content: "User-created entry")
        XCTAssertFalse(entry.isSampleData)
    }

    func testPartialDeleteUpdatesSampleCount() throws {
        let ctx = try makeContext()
        _ = SampleDataLoader.loadSampleEntries(into: ctx)
        let entries = try fetchAllEntries(ctx).filter { $0.isSampleData }
        guard let first = entries.first else {
            XCTFail("expected sample entries to exist")
            return
        }
        ctx.delete(first)
        try ctx.save()
        XCTAssertEqual(SampleDataLoader.sampleEntryCount(in: ctx), SampleDataLoader.entryCount - 1)
    }

    func testInsightTypesAreValid() throws {
        let ctx = try makeContext()
        _ = SampleDataLoader.loadSampleEntries(into: ctx)
        let entries = try fetchAllEntries(ctx)
        let validTypes: Set<InsightType> = [.sentiment, .pattern, .suggestion, .topicExtraction, .streak]
        for entry in entries {
            for insight in entry.safeInsights {
                XCTAssertTrue(validTypes.contains(insight.type), "unexpected insight type: \(insight.type)")
            }
        }
    }
}
