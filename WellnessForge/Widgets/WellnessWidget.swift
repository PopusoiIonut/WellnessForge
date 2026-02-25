import WidgetKit
import SwiftUI
import SwiftData

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), score: 85)
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        let entry = SimpleEntry(date: Date(), score: 85)
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        // In a real app, this would fetch from the shared ModelContainer
        let entry = SimpleEntry(date: Date(), score: Int.random(in: 60...95))
        let timeline = Timeline(entries: [entry], policy: .atEnd)
        completion(timeline)
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let score: Int
}

struct WellnessWidgetEntryView : View {
    var entry: Provider.Entry

    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Image(systemName: "sparkles")
                    .foregroundStyle(.purple)
                Text("Forge Score")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Text("\(entry.score)")
                .font(.system(size: 42, weight: .bold))
                .foregroundStyle(entry.score > 80 ? .green : .orange)
            
            Spacer()
            
            Text("Updated \(entry.date, style: .time)")
                .font(.system(size: 8))
                .foregroundStyle(.tertiary)
        }
        .padding()
        .containerBackground(.fill.tertiary, for: .widget)
    }
}

struct WellnessWidget: Widget {
    let kind: String = "WellnessWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            WellnessWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Forge Score")
        .description("Track your wellness forge progress from your home screen.")
        .supportedFamilies([.systemSmall])
    }
}
