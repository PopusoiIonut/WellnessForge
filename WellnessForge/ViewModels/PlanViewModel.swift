import SwiftUI
import SwiftData

class PlanViewModel: ObservableObject {
    @Published var completedCount: Int = 0
    
    func totalDailyCalories(for meals: [LoggedMeal]) -> Int {
        meals.reduce(0) { $0 + $1.calories }
    }

    func toggleTask(_ task: WellnessTask, in plan: WellnessPlan) {
        task.isCompleted.toggle()
        updateProgress(for: plan)
    }

    func updateProgress(for plan: WellnessPlan) {
        completedCount = plan.tasks.filter { $0.isCompleted }.count
    }
    
    func progressFraction(for plan: WellnessPlan) -> Double {
        guard !plan.tasks.isEmpty else { return 0 }
        return Double(plan.tasks.filter { $0.isCompleted }.count) / Double(plan.tasks.count)
    }
}
