import Foundation
import SwiftData

@Model
class UserProfile: Identifiable {
    var id: UUID = UUID()
    var name: String = ""
    var age: Int = 0
    var weightKg: Double = 0.0
    var heightCm: Double = 0.0
    var fitnessGoalRaw: String = ""

    var fitnessGoal: FitnessGoal {
        get { FitnessGoal(rawValue: fitnessGoalRaw) ?? .maintenance }
        set { fitnessGoalRaw = newValue.rawValue }
    }

    init(name: String, age: Int, weightKg: Double, heightCm: Double, fitnessGoal: FitnessGoal) {
        self.name = name
        self.age = age
        self.weightKg = weightKg
        self.heightCm = heightCm
        self.fitnessGoalRaw = fitnessGoal.rawValue
    }

    enum FitnessGoal: String, Codable, CaseIterable {
        case weightLoss = "Weight Loss"
        case muscleGain = "Muscle Gain"
        case maintenance = "Maintenance"
        case performance = "Performance"
    }
}

@Model
class WellnessTask: Identifiable {
    var id: UUID = UUID()
    var title: String = ""
    var isCompleted: Bool = false
    var dueTime: String = ""
    
    init(title: String, isCompleted: Bool = false, dueTime: String) {
        self.title = title
        self.isCompleted = isCompleted
        self.dueTime = dueTime
    }
}

@Model
class WellnessPlan: Identifiable {
    var id: UUID = UUID()
    var title: String = ""
    var details: String = ""
    var categoryRaw: String = ""
    
    @Relationship(deleteRule: .cascade)
    var tasks: [WellnessTask] = []

    var category: PlanCategory {
        get { PlanCategory(rawValue: categoryRaw) ?? .activity }
        set { categoryRaw = newValue.rawValue }
    }
    
    var description: String { details }

    init(title: String, details: String, category: PlanCategory, tasks: [WellnessTask]) {
        self.title = title
        self.details = details
        self.categoryRaw = category.rawValue
        self.tasks = tasks
    }

    enum PlanCategory: String, Codable {
        case recovery, activity, nutrition, mindfulness
    }

    static var preview: WellnessPlan {
        let plan = WellnessPlan(
            title: "Vital Recovery",
            details: "A gentle plan to restore your energy levels.",
            category: .recovery,
            tasks: [
                WellnessTask(title: "10 min Morning Stretch", dueTime: "08:00"),
                WellnessTask(title: "Hydrate: 500ml Water", dueTime: "10:00"),
                WellnessTask(title: "20 min Evening Walk", dueTime: "18:00")
            ]
        )
        return plan
    }
}

@Model
class LoggedMeal: Identifiable {
    var id: UUID = UUID()
    var name: String = ""
    var calories: Int = 0
    var protein: Int = 0
    var carbs: Int = 0
    var fats: Int = 0
    var timestamp: Date = Date()
    
    init(name: String, calories: Int, protein: Int, carbs: Int, fats: Int, timestamp: Date = Date()) {
        self.name = name
        self.calories = calories
        self.protein = protein
        self.carbs = carbs
        self.fats = fats
        self.timestamp = timestamp
    }
}

struct HealthSnapshot: Identifiable {
    let id = UUID()
    var steps: Int = 0
    var heartRateBPM: Double = 0
    var activeCalories: Double = 0
    var sleepHours: Double = 0
    var hrv: Double = 0 // ms

    var wellnessScore: Int {
        let stepScore = min(Double(steps) / 10000.0 * 30, 30)
        let sleepScore = min(sleepHours / 8.0 * 30, 30)
        let hrScore = heartRateBPM > 40 && heartRateBPM < 100 ? 20.0 : 10.0
        let hrvScore = min(hrv / 50.0 * 20, 20)
        return Int(stepScore + sleepScore + hrScore + hrvScore)
    }
}

struct AIMessage: Identifiable {
    let id = UUID()
    let role: Role
    let content: String
    let timestamp = Date()

    enum Role {
        case user
        case assistant
    }
}

struct ForgeDirective: Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String
    let icon: String
    let color: String
}

struct OracleReading {
    let headline: String
    let body: String
    let actionTip: String
    let mood: Mood
    var directives: [ForgeDirective] = []

    enum Mood {
        case peak, steady, recovery, rest

        var color: String {
            switch self {
            case .peak: return "purple"
            case .steady: return "green"
            case .recovery: return "orange"
            case .rest: return "blue"
            }
        }

        var icon: String {
            switch self {
            case .peak: return "bolt.fill"
            case .steady: return "leaf.fill"
            case .recovery: return "figure.mind.and.body"
            case .rest: return "moon.stars.fill"
            }
        }
    }
}
