import AppIntents
import SwiftUI

struct GetWellnessScoreIntent: AppIntent {
    static var title: LocalizedStringResource = "Get Wellness Forge Score"
    static var description = IntentDescription("Returns your current AI-calculated wellness score and energy prediction.")

    @MainActor
    func perform() async throws -> some IntentResult & ReturnsValue<Int> {
        // In a real app, this would fetch from the shared SwiftData container
        // Accessing the shared score for demo/shortcut purposes
        let score = UserDefaults.standard.integer(forKey: "latestWellnessScore")
        
        return .result(value: score, dialog: "Your Wellness Forge Score is \(score).")
    }
}

struct WellnessForgeShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: GetWellnessScoreIntent(),
            phrases: [
                "What is my \(.applicationName) score?",
                "Get my \(.applicationName) status",
                "Check \(.applicationName)"
            ],
            shortTitle: "Check Wellness Score",
            systemImageName: "sparkles"
        )
    }
}
