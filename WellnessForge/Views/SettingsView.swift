import SwiftUI
import SwiftData

struct SettingsView: View {
    @EnvironmentObject var healthKit: HealthKitService
    @EnvironmentObject var storeManager: StoreManager
    @Environment(\.modelContext) private var modelContext
    @Query private var users: [UserProfile]
    @State private var showPaywall = false
    @State private var showingProfileSetup = false
    @State private var showingResetAlert = false
    
    var user: UserProfile? { users.first }

    var body: some View {
        NavigationStack {
            Form {
                if let user = user {
                    Section("Your Profile") {
                        HStack {
                            Image(systemName: "person.circle.fill")
                                .font(.largeTitle)
                                .foregroundStyle(.purple)
                            VStack(alignment: .leading) {
                                HStack {
                                    TextField("Your name", text: Bindable(user).name)
                                        .font(.headline)
                                    if storeManager.isPremium {
                                        Text("PRO")
                                            .font(.caption2).bold()
                                            .padding(.horizontal, 4)
                                            .background(Color.purple, in: Capsule())
                                            .foregroundStyle(.white)
                                    }
                                }
                                Text("Age \(user.age)").font(.caption).foregroundStyle(.secondary)
                            }
                        }
                        Stepper("Age: \(user.age)", value: Bindable(user).age, in: 10...100)
                        Picker("Fitness Goal", selection: Bindable(user).fitnessGoalRaw) {
                            ForEach(UserProfile.FitnessGoal.allCases, id: \.rawValue) { goal in
                                Text(goal.rawValue).tag(goal.rawValue)
                            }
                        }
                    }
                } else {
                    Button(action: {
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        showingProfileSetup = true
                    }) {
                        Text("Create Profile")
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 4)
                    }
                }

                Section("Subscription") {
                    if storeManager.isPremium {
                        Label("You are a PRO member", systemImage: "checkmark.seal.fill")
                            .foregroundStyle(.purple)
                    } else {
                        Button("Upgrade to WellnessForge PRO") {
                            showPaywall = true
                        }
                        .foregroundStyle(.purple)
                    }
                }

                Section("Health Data") {
                    HStack {
                        Label("HealthKit Access", systemImage: "heart.fill")
                        Spacer()
                        Text(healthKit.isAuthorized ? "Granted ✅" : "Not Granted ❌")
                            .foregroundStyle(healthKit.isAuthorized ? .green : .red)
                            .font(.caption)
                    }
                    Button("Re-request HealthKit Access") {
                        healthKit.requestAuthorization()
                    }
                    Button("Refresh Health Data") {
                        healthKit.fetchLatestSnapshot()
                    }
                }

                Section("About WellnessForge") {
                    LabeledContent("Version", value: "1.0.0")
                    LabeledContent("AI Engine", value: "On-Device (Core ML)")
                    LabeledContent("Weather", value: "Open-Meteo (Free)")
                    LabeledContent("Data Privacy", value: "100% On-Device 🔒")
                }

                Section {
                    VStack(spacing: 4) {
                        Text("WellnessForge")
                            .font(.headline)
                        Text("Forge a healthier version of yourself.\nAll data stays on your device.")
                            .font(.caption).foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                }

                Section {
                    Button("Reset All Data", role: .destructive) {
                        showingResetAlert = true
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .navigationTitle("Settings")
            .sheet(isPresented: $showPaywall) { SubscriptionView() }
            .sheet(isPresented: $showingProfileSetup) { ProfileSetupView() }
            .alert("Reset All Data?", isPresented: $showingResetAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Reset", role: .destructive) {
                    if let user = user {
                        modelContext.delete(user)
                    }
                }
            } message: {
                Text("This will permanently delete your profile and progress. This action cannot be undone.")
            }
        }
    }
}
