import Vision
import Foundation

struct FoodItem: Identifiable {
    let id = UUID()
    let name: String
    let calories: Int
    let protein: Int
    let carbs: Int
    let fats: Int
}

class NutritionService: ObservableObject {
    @Published var detectedItem: FoodItem? = nil
    @Published var rawLabel: String = "" // For debug/feedback
    
    // In a real app, this would query a database or API
    let foodDatabase: [String: FoodItem] = [
        "apple": FoodItem(name: "Apple", calories: 95, protein: 0, carbs: 25, fats: 0),
        "banana": FoodItem(name: "Banana", calories: 105, protein: 1, carbs: 27, fats: 0),
        "egg": FoodItem(name: "Boiled Egg", calories: 78, protein: 6, carbs: 0, fats: 5),
        "chicken_breast": FoodItem(name: "Chicken Breast (100g)", calories: 165, protein: 31, carbs: 0, fats: 4),
        "salad": FoodItem(name: "Garden Salad", calories: 50, protein: 2, carbs: 10, fats: 0),
        "pizza": FoodItem(name: "Pizza Slice", calories: 285, protein: 12, carbs: 36, fats: 10)
    ]

    func processClassifications(_ observations: [VNClassificationObservation]) {
        guard !observations.isEmpty else { return }
        
        // Update debug info with top result
        if let top = observations.first {
            DispatchQueue.main.async {
                self.rawLabel = "\(top.identifier) (\(Int(top.confidence * 100))%)"
            }
        }
        
        // Deep search through top 10 results for a specific match
        let topResults = observations.prefix(10)
        
        var bestItem: FoodItem? = nil
        
        for observation in topResults {
            let lowerLabel = observation.identifier.lowercased()
            if let key = foodDatabase.keys.first(where: { lowerLabel.contains($0) }) {
                // If we find a specific match with decent confidence (>20%), lock on!
                if observation.confidence > 0.2 {
                    bestItem = foodDatabase[key]
                    break
                }
            }
        }
        
        if let newItem = bestItem {
            if newItem.name != detectedItem?.name {
                DispatchQueue.main.async {
                    self.detectedItem = newItem
                }
            }
        }
    }
}
