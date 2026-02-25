import XCTest
import SwiftData
@testable import WellnessForge

final class WellnessForgeTests: XCTestCase {
    var container: ModelContainer!
    var context: ModelContext!

    override func setUpWithError() throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        container = try ModelContainer(for: UserProfile.self, WellnessPlan.self, WellnessTask.self, configurations: config)
        context = ModelContext(container)
    }

    override func tearDownWithError() throws {
        container = nil
        context = nil
    }

    func testWellnessScoreCalculation() {
        // Arrange
        let snapshot = HealthSnapshot(
            steps: 5000,
            heartRateBPM: 70,
            activeCalories: 300,
            sleepHours: 7,
            hrv: 50
        )

        // Act
        let score = snapshot.wellnessScore

        // Assert
        // Steps: 5000/10000 * 30 = 15
        // Sleep: 7/8 * 30 = 26.25
        // HR: 70 is in [40, 100] -> 20
        // HRV: 50/50 * 20 = 20
        // Total: 15 + 26.25 + 20 + 20 = 81.25 -> 81
        XCTAssertEqual(score, 81, "Wellness score should be 81 for the given parameters")
    }

    func testSwiftDataPersistence() throws {
        // Arrange
        let task1 = WellnessTask(title: "Morning Stretch", dueTime: "08:00")
        let plan = WellnessPlan(title: "Test Plan", description: "Desc", category: .recovery, tasks: [task1])
        
        // Act
        context.insert(plan)
        try context.save()
        
        // Assert
        let descriptor = FetchDescriptor<WellnessPlan>()
        let fetchedPlans = try context.fetch(descriptor)
        
        XCTAssertEqual(fetchedPlans.count, 1)
        XCTAssertEqual(fetchedPlans.first?.title, "Test Plan")
        XCTAssertEqual(fetchedPlans.first?.tasks.count, 1)
        XCTAssertEqual(fetchedPlans.first?.tasks.first?.title, "Morning Stretch")
    }

    func testUserProfileInitialization() throws {
        // Arrange
        let user = UserProfile(name: "Test User", age: 30, weightKg: 75, heightCm: 180, fitnessGoal: .muscleGain)
        
        // Act
        context.insert(user)
        try context.save()
        
        // Assert
        let descriptor = FetchDescriptor<UserProfile>()
        let fetchedUsers = try context.fetch(descriptor)
        
        XCTAssertEqual(fetchedUsers.count, 1)
        XCTAssertEqual(fetchedUsers.first?.name, "Test User")
        XCTAssertEqual(fetchedUsers.first?.fitnessGoal, .muscleGain)
    }
}
