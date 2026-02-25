import SwiftUI
import BackgroundTasks
import SwiftData

@main
struct WellnessForgeApp: App {
    @StateObject private var healthKit = HealthKitService()
    @StateObject private var dashboardVM = DashboardViewModel()
    @StateObject private var chatVM = ChatViewModel()
    @StateObject private var planVM = PlanViewModel()
    @StateObject private var storeManager = StoreManager()

    var body: some Scene {
        WindowGroup {
            ContentRootView()
                .environmentObject(healthKit)
                .environmentObject(dashboardVM)
                .environmentObject(chatVM)
                .environmentObject(planVM)
                .environmentObject(storeManager)
                .onAppear {
                    healthKit.requestAuthorization()
                    registerBackgroundTasks()
                }
        }
        .modelContainer(for: [UserProfile.self, WellnessPlan.self, WellnessTask.self, LoggedMeal.self])
        .onChange(of: scenePhase) { oldValue, newValue in
            if newValue == .background {
                scheduleBackgroundRefresh()
            }
        }
    }

    @Environment(\.scenePhase) var scenePhase

    private func registerBackgroundTasks() {
        BGTaskScheduler.shared.register(forTaskWithIdentifier: "BitForge-Lab.WellnessForge.refresh", using: nil) { task in
            self.handleBackgroundRefresh(task: task as! BGAppRefreshTask)
        }
    }

    private func scheduleBackgroundRefresh() {
        let request = BGAppRefreshTaskRequest(identifier: "BitForge-Lab.WellnessForge.refresh")
        request.earliestBeginDate = Date(timeIntervalSinceNow: 15 * 60) // 15 mins
        try? BGTaskScheduler.shared.submit(request)
    }

    private func handleBackgroundRefresh(task: BGAppRefreshTask) {
        scheduleBackgroundRefresh()
        healthKit.fetchLatestSnapshot()
        task.setTaskCompleted(success: true)
    }
}

struct ContentRootView: View {
    var body: some View {
        TabView {
            DashboardView()
                .tabItem {
                    Label("Dashboard", systemImage: "house.fill")
                }

            DailyOracleView()
                .tabItem {
                    Label("Oracle", systemImage: "sparkles")
                }

            ChatView()
                .tabItem {
                    Label("AI Coach", systemImage: "message.fill")
                }

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
        }
        .accentColor(.purple)
    }
}
