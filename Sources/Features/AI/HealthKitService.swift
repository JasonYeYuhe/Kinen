import Foundation
import OSLog
#if canImport(HealthKit)
import HealthKit
#endif

/// On-device HealthKit integration. Reads sleep, steps, and heart rate
/// to correlate with journal mood. All processing is local.
@Observable @MainActor
final class HealthKitService {
    static let shared = HealthKitService()

    var isAvailable: Bool {
        #if canImport(HealthKit)
        HKHealthStore.isHealthDataAvailable()
        #else
        false
        #endif
    }

    /// Whether authorization has been requested at least once this session.
    /// HealthKit doesn't expose read auth status; we just attempt queries.
    /// Gate on UserDefaults("enableHealthKit") at call sites instead.
    private(set) var hasRequestedAuth = false
    var todaySleep: TimeInterval? // hours
    var todaySteps: Int?
    var todayRestingHR: Double?

    private let logger = Logger(subsystem: "com.jasonye.kinen", category: "HealthKit")

    #if canImport(HealthKit)
    private let store = HKHealthStore()

    private var readTypes: Set<HKObjectType> {
        Set([
            HKQuantityType(.stepCount),
            HKQuantityType(.restingHeartRate),
            HKCategoryType(.sleepAnalysis),
        ])
    }
    #endif

    func requestAuthorization() async -> Bool {
        #if canImport(HealthKit)
        guard isAvailable else { return false }
        do {
            try await store.requestAuthorization(toShare: [], read: readTypes)
            hasRequestedAuth = true
            logger.info("HealthKit authorization requested")
            return true
        } catch {
            logger.error("HealthKit authorization failed: \(error)")
            return false
        }
        #else
        return false
        #endif
    }

    /// Fetch today's health data (sleep, steps, resting HR).
    func fetchTodayData() async {
        #if canImport(HealthKit)
        guard isAvailable else { return }
        if !hasRequestedAuth {
            _ = await requestAuthorization()
        }

        async let steps = fetchSteps()
        async let sleep = fetchSleep()
        async let hr = fetchRestingHeartRate()

        todaySteps = await steps
        todaySleep = await sleep
        todayRestingHR = await hr

        logger.info("HealthKit data: steps=\(self.todaySteps ?? 0), sleep=\(self.todaySleep ?? 0, format: .fixed(precision: 1))h, HR=\(self.todayRestingHR ?? 0, format: .fixed(precision: 0))")
        #endif
    }

    /// Generate health-mood correlation insights from historical data.
    func generateCorrelationInsight(entries: [JournalEntry]) -> String? {
        #if canImport(HealthKit)
        // This is a placeholder for future deep analysis.
        // Full implementation would query historical HealthKit data
        // and correlate with entry mood scores.
        guard let sleep = todaySleep, let mood = entries.first?.mood else { return nil }

        if sleep < 6 && (mood == .bad || mood == .terrible) {
            return String(localized: "healthkit.insight.lowSleep")
        }
        if sleep > 7.5 && (mood == .good || mood == .great) {
            return String(localized: "healthkit.insight.goodSleep")
        }
        if let steps = todaySteps, steps > 8000 && (mood == .good || mood == .great) {
            return String(localized: "healthkit.insight.activeDay")
        }
        return nil
        #else
        return nil
        #endif
    }

    // MARK: - Private Queries

    #if canImport(HealthKit)
    private func fetchSteps() async -> Int? {
        let type = HKQuantityType(.stepCount)
        let predicate = HKQuery.predicateForSamples(withStart: Calendar.current.startOfDay(for: Date()), end: Date())

        do {
            let result = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Int?, Error>) in
                let query = HKStatisticsQuery(quantityType: type, quantitySamplePredicate: predicate) { _, stats, error in
                    if let error {
                        continuation.resume(throwing: error)
                    } else {
                        let steps = stats?.sumQuantity()?.doubleValue(for: .count())
                        continuation.resume(returning: steps.map(Int.init))
                    }
                }
                store.execute(query)
            }
            return result
        } catch {
            logger.error("Failed to fetch steps: \(error)")
            return nil
        }
    }

    private func fetchSleep() async -> TimeInterval? {
        let type = HKCategoryType(.sleepAnalysis)
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Calendar.current.startOfDay(for: Date())) ?? Date()
        let predicate = HKQuery.predicateForSamples(withStart: yesterday, end: Date())

        do {
            let result = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<TimeInterval?, Error>) in
                let query = HKSampleQuery(sampleType: type, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: [NSSortDescriptor(key: "startDate", ascending: true)]) { _, samples, error in
                    if let error {
                        continuation.resume(throwing: error)
                    } else {
                        // Filter to actual sleep stages
                        let sleepSamples = (samples as? [HKCategorySample])?.filter { sample in
                            [HKCategoryValueSleepAnalysis.asleepUnspecified.rawValue,
                             HKCategoryValueSleepAnalysis.asleepCore.rawValue,
                             HKCategoryValueSleepAnalysis.asleepDeep.rawValue,
                             HKCategoryValueSleepAnalysis.asleepREM.rawValue].contains(sample.value)
                        } ?? []

                        // Merge overlapping intervals to avoid double-counting
                        let totalSeconds = Self.mergedDuration(sleepSamples)
                        continuation.resume(returning: totalSeconds > 0 ? totalSeconds / 3600.0 : nil)
                    }
                }
                store.execute(query)
            }
            return result
        } catch {
            logger.error("Failed to fetch sleep: \(error)")
            return nil
        }
    }

    private func fetchRestingHeartRate() async -> Double? {
        let type = HKQuantityType(.restingHeartRate)
        let predicate = HKQuery.predicateForSamples(withStart: Calendar.current.startOfDay(for: Date()), end: Date())

        do {
            let result = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Double?, Error>) in
                let query = HKStatisticsQuery(quantityType: type, quantitySamplePredicate: predicate) { _, stats, error in
                    if let error {
                        continuation.resume(throwing: error)
                    } else {
                        let hr = stats?.averageQuantity()?.doubleValue(for: HKUnit(from: "count/min"))
                        continuation.resume(returning: hr)
                    }
                }
                store.execute(query)
            }
            return result
        } catch {
            logger.error("Failed to fetch resting HR: \(error)")
            return nil
        }
    }
    /// Merge overlapping time intervals and return total non-overlapping duration in seconds.
    private static func mergedDuration(_ samples: [HKCategorySample]) -> TimeInterval {
        let intervals = samples.map { (start: $0.startDate, end: $0.endDate) }
        return mergedDuration(intervals: intervals)
    }
    #endif

    /// Pure-function variant exposed for testing: merge overlapping (start, end) intervals
    /// and return total non-overlapping duration in seconds.
    static func mergedDuration(intervals: [(start: Date, end: Date)]) -> TimeInterval {
        guard !intervals.isEmpty else { return 0 }
        let sorted = intervals.sorted { $0.start < $1.start }
        var merged: [(start: Date, end: Date)] = []

        for interval in sorted {
            if let last = merged.last, interval.start <= last.end {
                merged[merged.count - 1].end = max(last.end, interval.end)
            } else {
                merged.append(interval)
            }
        }

        return merged.reduce(0) { $0 + $1.end.timeIntervalSince($1.start) }
    }

    private init() {}
}
