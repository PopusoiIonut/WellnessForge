import SwiftUI
import SwiftData

struct ProfileSetupView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var name: String = ""
    @State private var age: Int = 25
    @State private var weightKg: Double = 70.0
    @State private var heightCm: Double = 175.0
    @State private var fitnessGoal: UserProfile.FitnessGoal = .maintenance
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Identity") {
                    TextField("Name", text: $name)
                        .textContentType(.name)
                }
                
                Section("Metrics") {
                    Stepper("Age: \(age)", value: $age, in: 10...100)
                    
                    HStack {
                        Text("Weight")
                        Spacer()
                        TextField("Weight", value: $weightKg, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                        Text("kg").foregroundStyle(.secondary)
                    }
                    
                    HStack {
                        Text("Height")
                        Spacer()
                        TextField("Height", value: $heightCm, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                        Text("cm").foregroundStyle(.secondary)
                    }
                }
                
                Section("Objective") {
                    Picker("Fitness Goal", selection: $fitnessGoal) {
                        ForEach(UserProfile.FitnessGoal.allCases, id: \.self) { goal in
                            Text(goal.rawValue).tag(goal)
                        }
                    }
                    .pickerStyle(.menu)
                }
            }
            .navigationTitle("Forge Your Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        saveProfile()
                    }
                    .disabled(name.isEmpty)
                    .bold()
                }
            }
        }
    }
    
    private func saveProfile() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        let newUser = UserProfile(
            name: name,
            age: age,
            weightKg: weightKg,
            heightCm: heightCm,
            fitnessGoal: fitnessGoal
        )
        modelContext.insert(newUser)
        try? modelContext.save()
        dismiss()
    }
}
