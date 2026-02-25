import Foundation
import HealthKit
import Combine

class HealthKitService: ObservableObject {
    private let store = HKHealthStore()
    
    @Published var snapshot: HealthSnapshot = HealthSnapshot()
    @Published var isAuthorized: Bool = false
    @Published var isLoading: Bool = false
    @Published var error: ForgeError? = nil

    init() {
        if !HKHealthStore.isHealthDataAvailable() {
            self.error = .healthKit("HealthKit is not available on this device.")
        }
    }

    func requestAuthorization() {
        isLoading = true
        let typesToRead: Set = [
            HKObjectType.quantityType(forIdentifier: .stepCount)!,
            HKObjectType.quantityType(forIdentifier: .heartRate)!,
            HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!,
            HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!,
            HKObjectType.quantityType(forIdentifier: .heartRateVariabilitySDNN)!
        ]

        store.requestAuthorization(toShare: nil, read: typesToRead) { success, error in
            DispatchQueue.main.async {
                self.isLoading = false
                self.isAuthorized = success
                if !success {
                    self.error = .healthKit(error?.localizedDescription ?? "Access Dennied")
                } else {
                    self.fetchLatestSnapshot()
                }
            }
        }
    }

    func fetchLatestSnapshot() {
        guard HKHealthStore.isHealthDataAvailable() else {
            self.error = .healthKit("HealthKit is not available on this device.")
            return
        }
        
        isLoading = true
        Task {
            var steps = 0
            var hr = 0.0
            var calories = 0.0
            var hrv = 0.0
            var sleep = 0.0

            do { steps = try await fetchTodaySteps() } catch { print("Steps fetch failed: \(error)") }
            do { hr = try await fetchLatestQuantity(.heartRate, unit: HKUnit.count().unitDivided(by: .minute())) } catch { print("HR fetch failed: \(error)") }
            do { calories = try await fetchLatestQuantity(.activeEnergyBurned, unit: .kilocalorie()) } catch { print("Calories fetch failed: \(error)") }
            
            if #available(iOS 11.0, *) {
                do { hrv = try await fetchLatestQuantity(.heartRateVariabilitySDNN, unit: .secondUnit(with: .milli)) } catch { print("HRV fetch failed: \(error)") }
            }
            
            do { sleep = try await fetchSleepLastNight() } catch { print("Sleep fetch failed: \(error)") }

            let finalSteps = steps
            let finalHr = hr
            let finalCalories = calories
            let finalHrv = hrv
            let finalSleep = sleep

            await MainActor.run {
                self.snapshot = HealthSnapshot(
                    steps: finalSteps,
                    heartRateBPM: finalHr,
                    activeCalories: finalCalories,
                    sleepHours: finalSleep,
                    hrv: finalHrv
                )
                self.isLoading = false
                self.error = nil // Clear error if fetches run (even with 0s)
                
                // Persist for Siri App Intent
                UserDefaults.standard.set(self.snapshot.wellnessScore, forKey: "latestWellnessScore")
            }
        }
    }

    private func fetchTodaySteps() async throws -> Int {
        let steps = HKQuantityType.quantityType(forIdentifier: .stepCount)!
        let now = Date()
        let startOfDay = Calendar.current.startOfDay(for: now)
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: now, options: .strictStartDate)
        
        return try await withCheckedThrowingContinuation { continuation in
            let query = HKStatisticsQuery(quantityType: steps, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, result, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                let sum = result?.sumQuantity()?.doubleValue(for: .count()) ?? 0
                continuation.resume(returning: Int(sum))
            }
            store.execute(query)
        }
    }

    private func fetchLatestQuantity(_ identifier: HKQuantityTypeIdentifier, unit: HKUnit) async throws -> Double {
        let type = HKQuantityType.quantityType(forIdentifier: identifier)!
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
        
        return try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(sampleType: type, predicate: nil, limit: 1, sortDescriptors: [sortDescriptor]) { _, samples, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                let value = (samples?.first as? HKQuantitySample)?.quantity.doubleValue(for: unit) ?? 0
                continuation.resume(returning: value)
            }
            store.execute(query)
        }
    }

    private func fetchSleepLastNight() async throws -> Double {
        let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!
        let calendar = Calendar.current
        let now = Date()
        let startOfYesterday = calendar.date(byAdding: .day, value: -1, to: calendar.startOfDay(for: now))!
        let predicate = HKQuery.predicateForSamples(withStart: startOfYesterday, end: now, options: .strictStartDate)
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)

        return try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(sampleType: sleepType, predicate: predicate, limit: 100, sortDescriptors: [sortDescriptor]) { _, samples, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                let totalSeconds = samples?.compactMap { sample -> TimeInterval? in
                    guard let sleepSample = sample as? HKCategorySample, sleepSample.value == HKCategoryValueSleepAnalysis.asleepUnspecified.rawValue || sleepSample.value == HKCategoryValueSleepAnalysis.asleepDeep.rawValue || sleepSample.value == HKCategoryValueSleepAnalysis.asleepCore.rawValue || sleepSample.value == HKCategoryValueSleepAnalysis.asleepREM.rawValue else { return nil }
                    return sleepSample.endDate.timeIntervalSince(sleepSample.startDate)
                }.reduce(0, +) ?? 0
                continuation.resume(returning: totalSeconds / 3600.0)
            }
            store.execute(query)
        }
    }
}
