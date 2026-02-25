import SwiftUI
import SwiftData

struct DailyOracleView: View {
    @EnvironmentObject var healthKit: HealthKitService
    @EnvironmentObject var dashboardVM: DashboardViewModel
    @Query(sort: \LoggedMeal.timestamp, order: .reverse) private var meals: [LoggedMeal]
    @State private var isLoading = true

    var todayMeals: [LoggedMeal] {
        let today = Calendar.current.startOfDay(for: Date())
        return meals.filter { $0.timestamp >= today }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [Color.purple.opacity(0.15), Color.indigo.opacity(0.1), Color(.systemBackground)],
                    startPoint: .top, endPoint: .bottom
                )
                .ignoresSafeArea()

                if isLoading {
                    VStack(spacing: 20) {
                        ProgressView().scaleEffect(1.5)
                        Text("Reading your vitals…")
                            .font(.headline).foregroundStyle(.secondary)
                    }
                } else if let reading = dashboardVM.dailyOracle {
                    ScrollView {
                        VStack(spacing: 28) {
                            ZStack {
                                Circle()
                                    .fill(Color.purple.opacity(0.15))
                                    .frame(width: 120, height: 120)
                                Image(systemName: reading.mood.icon)
                                    .font(.system(size: 54))
                                    .foregroundStyle(.purple)
                            }
                            .padding(.top, 30)

                            Text(reading.headline)
                                .font(.title).bold()
                                .multilineTextAlignment(.center)

                            Text(reading.body)
                                .font(.body)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 24)

                            Divider().padding(.horizontal)

                            VStack(spacing: 8) {
                                Label("WellnessForge Action", systemImage: "sparkles")
                                    .font(.caption).foregroundStyle(.purple).bold()
                                Text(reading.actionTip)
                                    .font(.headline)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal)
                            }
                            .padding()
                            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
                            .padding(.horizontal)

                            if !reading.directives.isEmpty {
                                VStack(alignment: .leading, spacing: 12) {
                                    Text("Forge Directives")
                                        .font(.headline)
                                        .padding(.horizontal)
                                    ForEach(reading.directives) { directive in
                                        DirectiveRow(directive: directive)
                                            .padding(.horizontal)
                                    }
                                }
                            }

                            HStack(spacing: 6) {
                                Image(systemName: "waveform.path.ecg")
                                Text("Wellness Score: \(healthKit.snapshot.wellnessScore) / 100")
                            }
                            .font(.footnote).foregroundStyle(.secondary)

                            Spacer(minLength: 40)
                        }
                    }
                }
            }
            .navigationTitle("Daily Oracle")
            .navigationBarTitleDisplayMode(.large)
            .onAppear { loadReading() }
            .refreshable { loadReading() }
        }
    }

    private func loadReading() {
        isLoading = true
        healthKit.fetchLatestSnapshot()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            dashboardVM.updateOracle(snapshot: healthKit.snapshot, meals: todayMeals)
            isLoading = false
        }
    }
}
