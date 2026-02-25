import SwiftUI
import SwiftData

struct DashboardView: View {
    @EnvironmentObject var healthKit: HealthKitService
    @EnvironmentObject var dashboardVM: DashboardViewModel
    @EnvironmentObject var planVM: PlanViewModel
    @EnvironmentObject var storeManager: StoreManager
    @StateObject private var weatherService = WeatherService()
    @State private var showMealScanner = false
    @State private var showARWorkout = false

    @Environment(\.modelContext) private var modelContext
    @Query private var plans: [WellnessPlan]
    @Query(sort: \LoggedMeal.timestamp, order: .reverse) private var meals: [LoggedMeal]
    
    var activePlan: WellnessPlan? { plans.first }
    var todayMeals: [LoggedMeal] {
        let today = Calendar.current.startOfDay(for: Date())
        return meals.filter { $0.timestamp >= today }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(dashboardVM.greeting)
                                    .font(.title3).foregroundStyle(.secondary)
                                if storeManager.isPremium {
                                    Text("PRO")
                                        .font(.caption2).bold()
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(Color.purple, in: Capsule())
                                        .foregroundStyle(.white)
                                }
                            }
                            Text("Your Wellness Coach")
                                .font(.title).bold()
                        }
                        .padding(.horizontal)

                        if let oracleAny = dashboardVM.dailyOracle as Any?, let oracle = oracleAny as? OracleReading {
                            OracleForecastCard(oracle: oracle)
                                .padding(.horizontal)
                                .transition(.move(edge: .top).combined(with: .opacity))
                        }

                        if healthKit.isLoading {
                            ShimmerView()
                                .frame(height: 120)
                                .cornerRadius(16)
                                .padding(.horizontal)
                        } else {
                            WellnessScoreCard(score: healthKit.snapshot.wellnessScore)
                                .padding(.horizontal)
                        }

                        if !healthKit.isLoading {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Forge Directives")
                                    .font(.headline)
                                    .padding(.horizontal)
                                
                                if let directives = dashboardVM.dailyOracle?.directives, !directives.isEmpty {
                                    ForEach(directives) { directive in
                                        DirectiveRow(directive: directive)
                                            .padding(.horizontal)
                                    }
                                } else {
                                    Text("Biology is in sync. Maintain current trajectory.")
                                        .font(.subheadline).foregroundStyle(.secondary)
                                        .padding(.horizontal)
                                }
                            }
                        }

                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                            HealthStatTile(icon: "figure.walk", label: "Steps", value: "\(healthKit.snapshot.steps.formatted())", color: .green)
                            HealthStatTile(icon: "flame.fill", label: "Burned", value: "\(Int(healthKit.snapshot.activeCalories)) kcal", color: .orange)
                            HealthStatTile(icon: "fork.knife", label: "Intake", value: "\(planVM.totalDailyCalories(for: todayMeals)) kcal", color: .yellow)
                            HealthStatTile(icon: "moon.stars.fill", label: "Sleep", value: String(format: "%.1f hrs", healthKit.snapshot.sleepHours), color: .indigo)
                            HealthStatTile(icon: "heart.fill", label: "Heart Rate", value: "\(Int(healthKit.snapshot.heartRateBPM)) BPM", color: .red)
                            HealthStatTile(icon: "waveform.path.ecg", label: "HRV", value: "\(Int(healthKit.snapshot.hrv)) ms", color: .purple)
                        }
                        .padding(.horizontal)
                        
                        // --- PRO FEATURES SECTION ---
                        if storeManager.isPremium {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Pro Tools")
                                    .font(.headline)
                                    .padding(.horizontal)
                                
                                HStack(spacing: 12) {
                                    Button(action: { showMealScanner = true }) {
                                        ProToolButton(icon: "camera.viewfinder", title: "Meal Scanner", subtitle: "AI vision analysis")
                                    }
                                    
                                    Button(action: { showARWorkout = true }) {
                                        ProToolButton(icon: "arkit", title: "AR Workout", subtitle: "Posture guide")
                                    }
                                }
                                .padding(.horizontal)
                            }
                        } else {
                            // Upsell Banner
                            Button(action: { /* App handles paywall via MainContainer usually, or trigger a state here */ }) {
                                HStack {
                                    Image(systemName: "sparkles")
                                    Text("Unlock WellnessForge PRO")
                                        .font(.headline)
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                }
                                .padding()
                                .foregroundStyle(.white)
                                .background(LinearGradient(colors: [.purple, .indigo], startPoint: .leading, endPoint: .trailing), in: RoundedRectangle(cornerRadius: 16))
                            }
                            .padding(.horizontal)
                        }
                        // --- END PRO FEATURES SECTION ---

                        if let plan = activePlan {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Active Plan: \(plan.title)")
                                    .font(.headline)
                                    .padding(.horizontal)
                                ProgressView(value: planVM.progressFraction(for: plan))
                                    .tint(.purple)
                                    .padding(.horizontal)
                            }
                        }

                        Text("\"\(dashboardVM.motivationalQuote)\"")
                            .font(.footnote).italic().foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .padding()
                            .frame(maxWidth: .infinity)
                    }
                    .padding(.top)
                }
                .refreshable { 
                    healthKit.fetchLatestSnapshot()
                    dashboardVM.updateOracle(snapshot: healthKit.snapshot, meals: todayMeals)
                }
                .onChange(of: healthKit.snapshot.id) { _, _ in
                    dashboardVM.updateOracle(snapshot: healthKit.snapshot, meals: todayMeals)
                }
                .onChange(of: meals.count) { _, _ in
                    dashboardVM.updateOracle(snapshot: healthKit.snapshot, meals: todayMeals)
                }
                .onAppear {
                    dashboardVM.updateOracle(snapshot: healthKit.snapshot, meals: todayMeals)
                }
                .sheet(isPresented: $showMealScanner) { MealScannerView() }
                .fullScreenCover(isPresented: $showARWorkout) { WorkoutARView() }
                
                if let error = healthKit.error {
                    ErrorOverlay(error: error) {
                        healthKit.fetchLatestSnapshot()
                    }
                } else if let error = weatherService.error {
                    ErrorOverlay(error: error) {
                        weatherService.fetchWeather()
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .refreshable { healthKit.fetchLatestSnapshot() }
            .onAppear { weatherService.fetchWeather() }
        }
    }
}

struct WellnessScoreCard: View {
    let score: Int
    @State private var animatedScore: Double = 0
    @State private var isPulsing = false
    
    var scoreColor: Color {
        score > 80 ? .green : score > 60 ? .yellow : score > 40 ? .orange : .red
    }
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Forge Score").font(.caption).foregroundStyle(.secondary)
                Text("\(Int(animatedScore))")
                    .font(.system(size: 48, weight: .bold))
                    .foregroundStyle(scoreColor)
                    .contentTransition(.numericText())
                Text("/ 100").font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            ZStack {
                // Pulsing Background Glow
                Circle()
                    .fill(scoreColor.opacity(0.15))
                    .scaleEffect(isPulsing ? 1.2 : 1.0)
                    .opacity(isPulsing ? 0.6 : 1.0)
                
                Circle()
                    .stroke(scoreColor.opacity(0.2), lineWidth: 12)
                
                Circle()
                    .trim(from: 0, to: CGFloat(animatedScore) / 100)
                    .stroke(scoreColor, style: StrokeStyle(lineWidth: 12, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .animation(.spring(response: 1.2, dampingFraction: 0.8), value: animatedScore)
                
                Image(systemName: "sparkles")
                    .font(.title)
                    .foregroundStyle(scoreColor)
                    .symbolEffect(.pulse, value: isPulsing)
            }
            .frame(width: 80, height: 80)
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(.white.opacity(0.1), lineWidth: 1))
        .onAppear {
            withAnimation(.spring(response: 1.5, dampingFraction: 0.7)) {
                animatedScore = Double(score)
            }
            withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                isPulsing = true
            }
            // Trigger haptic on score reveal
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()
        }
    }
}

struct HealthStatTile: View {
    let icon: String
    let label: String
    let value: String
    let color: Color
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon).foregroundStyle(color)
                Text(label).font(.caption).foregroundStyle(.secondary)
            }
            Text(value).font(.title3).bold()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14))
    }
}

struct WeatherCard: View {
    let weather: WeatherData
    var body: some View {
        HStack {
            Image(systemName: weather.conditionIcon)
                .font(.largeTitle)
                .foregroundStyle(.cyan)
            VStack(alignment: .leading) {
                Text("\(Int(weather.temperature))°C · \(weather.conditionText)")
                    .font(.headline)
                Text(weather.wellnessImpact)
                    .font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14))
    }
}

struct TaskRow: View {
    let task: WellnessTask
    let onToggle: () -> Void
    var body: some View {
        HStack {
            Button(action: onToggle) {
                Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(task.isCompleted ? .purple : .secondary)
                    .font(.title3)
            }
            VStack(alignment: .leading) {
                Text(task.title)
                    .strikethrough(task.isCompleted)
                    .foregroundStyle(task.isCompleted ? .secondary : .primary)
                Text(task.dueTime).font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
        }
    }
}

struct ProToolButton: View {
    let icon: String
    let title: String
    let subtitle: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(.purple)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline).bold()
                    .foregroundStyle(.primary)
                Text(subtitle)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.purple.opacity(0.3), lineWidth: 1)
        )
    }
}
