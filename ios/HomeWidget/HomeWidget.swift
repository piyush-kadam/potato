import WidgetKit
import SwiftUI

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), categoryBudgets: [:], categorySpent: [:])
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        let entry = loadData()
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        let entry = loadData()
        let timeline = Timeline(entries: [entry], policy: .after(Date().addingTimeInterval(900))) // Update every 15 minutes
        completion(timeline)
    }
    
    func loadData() -> SimpleEntry {
        print("📱 WIDGET DEBUG - Starting load...")
        
        guard let data = UserDefaults(suiteName: "group.com.potato.slideme") else {
            print("📱 WIDGET DEBUG - Failed to create UserDefaults")
            return SimpleEntry(date: Date(), categoryBudgets: [:], categorySpent: [:])
        }
        
        print("📱 WIDGET DEBUG - UserDefaults exists: true")
        
        // ✅ List ALL keys to see what's actually there
        print("📱 WIDGET DEBUG - All UserDefaults keys:")
        let dict = data.dictionaryRepresentation()
        for key in dict.keys.sorted() {
            print("📱 WIDGET DEBUG - Key found: \(key)")
        }
        
        // Try different key variations
        var budgetsData = data.string(forKey: "categoryBudgets")
        var spentData = data.string(forKey: "categorySpent")
        
        print("📱 WIDGET DEBUG - Direct key 'categoryBudgets': \(budgetsData ?? "nil")")
        print("📱 WIDGET DEBUG - Direct key 'categorySpent': \(spentData ?? "nil")")
        
        // Try with HomeWidget prefix
        if budgetsData == nil {
            budgetsData = data.string(forKey: "HomeWidget.categoryBudgets")
            print("📱 WIDGET DEBUG - Prefixed key 'HomeWidget.categoryBudgets': \(budgetsData ?? "nil")")
        }
        if spentData == nil {
            spentData = data.string(forKey: "HomeWidget.categorySpent")
            print("📱 WIDGET DEBUG - Prefixed key 'HomeWidget.categorySpent': \(spentData ?? "nil")")
        }
        
        let budgets = parseCategoryData(budgetsData ?? "{}")
        let spent = parseCategoryData(spentData ?? "{}")
        
        print("📱 WIDGET DEBUG - Parsed budgets count: \(budgets.count)")
        print("📱 WIDGET DEBUG - Parsed spent count: \(spent.count)")
        
        return SimpleEntry(date: Date(), categoryBudgets: budgets, categorySpent: spent)
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
            } else if let intValue = value as? Int {
                result[key] = Double(intValue)
            } else if let doubleValue = value as? Double {
                result[key] = doubleValue
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
    @Environment(\.widgetFamily) var family
    
    var body: some View {
        ZStack {
            Color(red: 0.89, green: 0.95, blue: 0.99)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("💰 Budget Tracker DEBUG")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.black)
                
                Divider()
                
                // Show what keys exist in UserDefaults
                if let data = UserDefaults(suiteName: "group.com.potato.slideme") {
                    let dict = data.dictionaryRepresentation()
                    
                    Text("📊 Total keys: \(dict.keys.count)")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.blue)
                    
                    Text("🔑 Keys found:")
                        .font(.system(size: 9))
                        .foregroundColor(.purple)
                    
                    // Show all keys (scrollable if needed)
                    ScrollView {
                        VStack(alignment: .leading, spacing: 2) {
                            ForEach(Array(dict.keys.sorted()), id: \.self) { key in
                                Text("• \(key)")
                                    .font(.system(size: 8))
                                    .foregroundColor(.red)
                                    .lineLimit(2)
                            }
                        }
                    }
                    
                    Divider()
                    
                    Text("Parsed: B:\(entry.categoryBudgets.count) S:\(entry.categorySpent.count)")
                        .font(.system(size: 9))
                        .foregroundColor(.green)
                } else {
                    Text("❌ Cannot access UserDefaults")
                        .font(.system(size: 10))
                        .foregroundColor(.red)
                }
                
                Spacer()
            }
            .padding(8)
        }
    }
}

@main
struct HomeWidget: Widget {
    let kind: String = "HomeWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            HomeWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Budget Tracker")
        .description("Track your category budgets and spending.")
        .supportedFamilies([.systemMedium, .systemLarge])
    }
}