import Foundation
import Combine

class DashboardViewModel: ObservableObject {
    @Published var greeting: String = ""
    @Published var motivationalQuote: String = ""
    @Published var dailyOracle: AIOracleReading? = nil
    
    private let aiService = AIModelService()
    private let quotes = [
        "Your health is your most important asset.",
        "Precision in wellness leads to peak performance.",
        "Forge a stronger version of yourself every day.",
        "Data-driven insights for a better life.",
        "Consistency is the hammer that forges excellence.",
    ]

    init() {
        updateGreeting()
        motivationalQuote = quotes.randomElement() ?? quotes[0]
    }

    func updateGreeting() {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5...11:  greeting = "Good Morning"
        case 12...17: greeting = "Good Afternoon"
        case 18...21: greeting = "Good Evening"
        default:      greeting = "Good Night"
        }
    }
    
    func updateOracle(snapshot: HealthSnapshot, meals: [LoggedMeal]) {
        self.dailyOracle = aiService.generateDailyOracle(snapshot: snapshot, meals: meals)
    }
}

