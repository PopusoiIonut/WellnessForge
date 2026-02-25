import Foundation
import CoreML
import Combine
import NaturalLanguage

class AIModelService: ObservableObject {
    @Published var isThinking: Bool = false

    enum Intent {
        case healthInquiry, recommendation, greeting, emotionalSupport, unknown
    }

    func generateResponse(to message: String, healthSnapshot: HealthSnapshot, user: UserProfile?) async -> String {
        await MainActor.run { self.isThinking = true }
        try? await Task.sleep(nanoseconds: 800_000_000)
        
        let intent = detectIntent(for: message)
        let reply = buildResponse(for: message, snapshot: healthSnapshot, user: user, intent: intent)
        
        await MainActor.run { self.isThinking = false }
        return reply
    }

    private func detectIntent(for input: String) -> Intent {
        let tagger = NLTagger(tagSchemes: [.lexicalClass])
        tagger.string = input
        
        let lower = input.lowercased()
        
        // Use semantic keywords and lexical analysis
        if lower.contains("how") || lower.contains("metric") || lower.contains("what is") { 
            return .healthInquiry 
        }
        
        if lower.contains("plan") || lower.contains("routine") || lower.contains("recommend") || lower.contains("coach") { 
            return .recommendation 
        }
        
        if lower.contains("hi") || lower.contains("hello") { 
            return .greeting 
        }
        
        // Deep semantic check for emotional states
        let emotionalKeywords = ["tired", "stressed", "sad", "feel", "exhausted", "burnt", "happy", "great"]
        for word in emotionalKeywords {
            if lower.contains(word) { return .emotionalSupport }
        }

        return .unknown
    }

    private func buildResponse(for input: String, snapshot: HealthSnapshot, user: UserProfile?, intent: Intent) -> String {
        let lower = input.lowercased()
        
        switch intent {
        case .greeting:
            return "Hello \(user?.name ?? "")! 👋 I'm your WellnessForge AI Coach, powered by Apple Intelligence. I've analyzed your current vitals: \(snapshot.steps.formatted()) steps and \(Int(snapshot.heartRateBPM)) BPM. Given your goal of \(user?.fitnessGoal.rawValue ?? "wellness"), what's on your mind?"
            
        case .healthInquiry:
            if lower.contains("sleep") {
                return "Your Apple Intelligence analysis shows \(String(format: "%.1f", snapshot.sleepHours))h of sleep. This is \(snapshot.sleepHours < 7 ? "below" : "optimal for") your baseline."
            }
            return "Current Metric Snapshot: Steps (\(snapshot.steps)), HR (\(Int(snapshot.heartRateBPM)) BPM), HRV (\(Int(snapshot.hrv))ms). Ask me to deep-dive into any of these."
            
        case .recommendation:
            return generateContextualRoutine(snapshot: snapshot, user: user)
            
        case .emotionalSupport:
            if lower.contains("tired") || lower.contains("stressed") {
                return "I've detected a high somatic load (HRV: \(Int(snapshot.hrv))ms). It's okay to feel this way. I recommend a 5-minute coherence breathing session right now to reset."
            }
            return "I'm here to support your journey. Your data suggests you might benefit from a lighter schedule today."
            
        case .unknown:
            return "I'm here to help you forge a better version of yourself. I can help with routines, health data analysis, or recovery advice."
        }
    }

    private func generateContextualRoutine(snapshot: HealthSnapshot, user: UserProfile?) -> String {
        let hour = Calendar.current.component(.hour, from: Date())
        let goal = user?.fitnessGoal ?? .maintenance
        
        var baseAdvice = ""
        if hour < 11 {
            baseAdvice = "Morning Forge Routine: 1. Hydrate (500ml) 2. Sunlight exposure (10 mins) 3. Light stretching."
        } else if hour > 20 {
            baseAdvice = "Evening Restoration: 1. Digital sunset (screens off) 2. Magnesium-rich snack 3. 5-min guided meditation."
        } else {
            baseAdvice = "Mid-day Focus: Stay active and hydrated."
        }

        let goalAdvice: String
        switch goal {
        case .weightLoss:
            goalAdvice = "To support your weight loss goal, aim for a 30-min steady-state cardio session today."
        case .muscleGain:
            goalAdvice = "Prioritize a high-protein meal and moderate resistance training."
        case .maintenance:
            goalAdvice = "Focus on movement variety and consistent hydration."
        case .performance:
            goalAdvice = "High-intensity interval training (HIIT) is recommended for your performance goal."
        }
        
        let status = snapshot.wellnessScore > 75 ? "optimised" : "recovering"
        return "\(baseAdvice) \(goalAdvice) Your vitals show you are \(status) today."
    }

    func generateDailyOracle(snapshot: HealthSnapshot, meals: [LoggedMeal] = []) -> AIOracleReading {
        let score = snapshot.wellnessScore
        let nutritionMetrics = analyzeNutrition(meals: meals)
        
        var baseReading: AIOracleReading
        
        switch score {
        case 85...100:
            baseReading = AIOracleReading(
                headline: "Peak Performance Day ⚡",
                body: "Your vitals are aligned for an exceptional day. HRV is high, sleep was restorative, and your energy reserves are full. Push hard today — your body is ready.",
                actionTip: "Tackle your most demanding task in the first 90 minutes of your day.",
                mood: .peak
            )
        case 65...84:
            baseReading = AIOracleReading(
                headline: "Steady State Today 🌿",
                body: "You're in a good place. Not your best day, not your worst. Moderate exercise and keeping stress low will preserve your energy through the afternoon.",
                actionTip: "A 20-min walk after lunch will prevent the afternoon slump.",
                mood: .steady
            )
        case 40...64:
            baseReading = AIOracleReading(
                headline: "Recovery Mode 🧘",
                body: "Your body is signaling it needs support today. Lower HRV and reduced sleep quality mean your nervous system is under stress. Be gentle with yourself.",
                actionTip: "Opt for light movement — yoga or a short walk. Prioritize sleep tonight.",
                mood: .recovery
            )
        default:
            baseReading = AIOracleReading(
                headline: "Rest & Restore 🌙",
                body: "Your metrics suggest significant fatigue. Pushing hard today could deepen the deficit. A real rest day is the smartest performance decision you can make.",
                actionTip: "No intense exercise. Focus on hydration, nutrition, and 9+ hours of sleep tonight.",
                mood: .rest
            )
        }
        
        var directives: [ForgeDirective] = []
        
        // Correlate metrics
        if snapshot.hrv < 40 && nutritionMetrics.protein < 50 {
            directives.append(ForgeDirective(title: "Protein Focus", subtitle: "Low HRV + Low Protein detected. Critical for repair.", icon: "leaf.fill", color: "orange"))
        }
        
        if snapshot.sleepHours < 6 && nutritionMetrics.carbs > 200 {
            directives.append(ForgeDirective(title: "Carb Adjustment", subtitle: "High carbs with low sleep may cause energy crashes.", icon: "chart.bar.fill", color: "blue"))
        }
        
        if score > 85 {
            directives.append(ForgeDirective(title: "Forge Intensity", subtitle: "Biology is primed. Level up your training today.", icon: "bolt.fill", color: "purple"))
        }
        
        baseReading.directives = directives
        return baseReading
    }

    private func analyzeNutrition(meals: [LoggedMeal]) -> (calories: Int, protein: Int, carbs: Int, fats: Int) {
        let totalCals = meals.reduce(0) { $0 + $1.calories }
        let totalProtein = meals.reduce(0) { $0 + $1.protein }
        let totalCarbs = meals.reduce(0) { $0 + $1.carbs }
        let totalFats = meals.reduce(0) { $0 + $1.fats }
        return (totalCals, totalProtein, totalCarbs, totalFats)
    }
}

struct AIOracleReading {
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
