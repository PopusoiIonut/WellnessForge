import Foundation
import Combine

struct PredictionResult {
    let state: SlumpState
    let confidence: Double
    let message: String

    enum SlumpState {
        case highEnergy, steady, impendingSlump, criticalFatigue
    }
}

class ActivityPredictionService: ObservableObject {
    @Published var currentPrediction: PredictionResult?

    func predictSlump(snapshot: HealthSnapshot, user: UserProfile?) {
        let hour = Calendar.current.component(.hour, from: Date())
        let goal = user?.fitnessGoal ?? .maintenance
        
        // Circadian Factor: Usually energy dips around 2-4 PM and before bed
        var circadianLoad = 0.0
        if (14...16).contains(hour) { circadianLoad = 15.0 }
        if (21...23).contains(hour) { circadianLoad = 25.0 }
        
        let sleepDebt = max(0, 8.0 - snapshot.sleepHours)
        let somaticLoad = 100.0 - snapshot.hrv
        
        // Goal Adjustment: Performance goals might tolerate higher loads, weight loss needs more recovery awareness
        let goalMultiplier = goal == .performance ? 0.8 : 1.2
        
        let fatigueIndex = ((sleepDebt * 12) + (somaticLoad / 1.5) + circadianLoad) * goalMultiplier
        
        var state: PredictionResult.SlumpState = .steady
        var message = "Your energy levels are predicted to be stable."
        
        if fatigueIndex > 70 {
            state = .criticalFatigue
            message = "Critical fatigue imminent. Your body needs deep recovery. Avoid intense physical or cognitive stress."
        } else if fatigueIndex > 45 {
            state = .impendingSlump
            message = hour < 12 ? "Early fatigue detected. Consider a protein-rich snack and light movement." : "Afternoon slump predicted. A 10-minute digital detox or hydration is recommended."
        } else if fatigueIndex < 25 && snapshot.hrv > 55 {
            state = .highEnergy
            message = "Optimal state detected! Your baseline and current vitals suggest you are ready for a high-intensity 'Forge' session."
        }
        
        DispatchQueue.main.async {
            self.currentPrediction = PredictionResult(
                state: state,
                confidence: 0.92,
                message: message
            )
        }
    }
}
