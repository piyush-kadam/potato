import WidgetKit
import SwiftUI

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), categoryBudgets: [:], categorySpent: [:])
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        let data = UserDefaults(suiteName: "group.com.potato.slideme")
        let budgetsData = data?.string(forKey: "categoryBudgets") ?? "{}"
        let spentData = data?.string(forKey: "categorySpent") ?? "{}"
        
        let budgets = parseCategoryData(budgetsData)
        let spent = parseCategoryData(spentData)
        
        let entry = SimpleEntry(date: Date(), categoryBudgets: budgets, categorySpent: spent)
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        let data = UserDefaults(suiteName: "group.com.potato.slideme")
        let budgetsData = data?.string(forKey: "categoryBudgets") ?? "{}"
        let spentData = data?.string(forKey: "categorySpent") ?? "{}"
        
        let budgets = parseCategoryData(budgetsData)
        let spent = parseCategoryData(spentData)
        
        let entry = SimpleEntry(date: Date(), categoryBudgets: budgets, categorySpent: spent)
        let timeline = Timeline(entries: [entry], policy: .atEnd)
        completion(timeline)
    }
    
    func parseCategoryData(_ jsonString: String) -> [String: Double] {
        guard let data = jsonString.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return [:]
        }
        
        var result: [String: Double] = [:]
        for (key, value) in json {
            if let numValue = value as? NSNumber {
                result[key] = numValue.doubleValue
            }
        }
        return result
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let categoryBudgets: [String: Double]
    let categorySpent: [String: Double]
}

struct HomeWidgetEntryView: View {
    var entry: Provider.Entry

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Budget Tracker")
                .font(.headline)
                .padding(.bottom, 4)
            
            ForEach(Array(entry.categoryBudgets.keys.sorted()), id: \.self) { category in
                HStack {
                    Text(category)
                        .font(.system(size: 12))
                    Spacer()
                    Text("\(Int(entry.categorySpent[category] ?? 0))/\(Int(entry.categoryBudgets[category] ?? 0))")
                        .font(.system(size: 12, weight: .semibold))
                }
            }
        }
        .padding()
    }
}

@main
struct HomeWidget: Widget {
    let kind: String = "HomeWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            HomeWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Budget Widget")
        .description("Track your category budgets and spending.")
        .supportedFamilies([.systemMedium, .systemLarge])
    }
}