import WidgetKit
import SwiftUI

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), categoryBudgets: [:], categorySpent: [:], debugInfo: "Loading...")
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        let entry = loadData()
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        let entry = loadData()
        let timeline = Timeline(entries: [entry], policy: .after(Date().addingTimeInterval(900)))
        completion(timeline)
    }
    
    func loadData() -> SimpleEntry {
        guard let sharedDefaults = UserDefaults(suiteName: "group.com.potato.slideme") else {
            return SimpleEntry(date: Date(), categoryBudgets: [:], categorySpent: [:], 
                             debugInfo: "❌ Cannot access App Group")
        }
        
        // Get ALL keys from UserDefaults
        var debugInfo = "🔍 Found Keys:\n"
        let allKeys = sharedDefaults.dictionaryRepresentation().keys.sorted()
        
        if allKeys.isEmpty {
            debugInfo = "❌ No keys found in UserDefaults"
        } else {
            for key in allKeys.prefix(10) {
                let value = sharedDefaults.object(forKey: key)
                let valuePreview = String(describing: value).prefix(30)
                debugInfo += "• \(key): \(valuePreview)...\n"
            }
        }
        
        // Try to read the data
        var budgetsJson: String? = nil
        var spentJson: String? = nil
        var foundBudgetKey = "none"
        var foundSpentKey = "none"
        
        // Try different key patterns
        let possibleBudgetKeys = [
            "categoryBudgets",
            "HomeWidget.categoryBudgets",
            "flutter.categoryBudgets"
        ]
        
        let possibleSpentKeys = [
            "categorySpent",
            "HomeWidget.categorySpent",
            "flutter.categorySpent"
        ]
        
        for key in possibleBudgetKeys {
            if let value = sharedDefaults.string(forKey: key) {
                budgetsJson = value
                foundBudgetKey = key
                break
            }
        }
        
        for key in possibleSpentKeys {
            if let value = sharedDefaults.string(forKey: key) {
                spentJson = value
                foundSpentKey = key
                break
            }
        }
        
        debugInfo += "\n✅ Budget key: \(foundBudgetKey)"
        debugInfo += "\n✅ Spent key: \(foundSpentKey)"
        
        let budgets = parseCategoryData(budgetsJson ?? "{}")
        let spent = parseCategoryData(spentJson ?? "{}")
        
        debugInfo += "\n📊 Budgets: \(budgets.count) items"
        debugInfo += "\n📊 Spent: \(spent.count) items"
        
        return SimpleEntry(date: Date(), categoryBudgets: budgets, categorySpent: spent, debugInfo: debugInfo)
    }
    
    func parseCategoryData(_ jsonString: String) -> [String: Double] {
        guard let data = jsonString.data(using: .utf8) else {
            return [:]
        }
        
        do {
            guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
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
                } else if let stringValue = value as? String, let doubleValue = Double(stringValue) {
                    result[key] = doubleValue
                }
            }
            return result
        } catch {
            return [:]
        }
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let categoryBudgets: [String: Double]
    let categorySpent: [String: Double]
    let debugInfo: String
}

struct HomeWidgetEntryView: View {
    var entry: Provider.Entry
    @Environment(\.widgetFamily) var family
    
    // Add this state to toggle debug mode
    @State private var showDebug = true
    
    func extractEmoji(from text: String) -> String {
        let emojiRegex = try! NSRegularExpression(pattern: "[\\p{Emoji_Presentation}\\p{Emoji}]", options: [])
        if let match = emojiRegex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)) {
            if let range = Range(match.range, in: text) {
                return String(text[range])
            }
        }
        return "📦"
    }
    
    func extractName(from text: String) -> String {
        let emojiRegex = try! NSRegularExpression(pattern: "[\\p{Emoji_Presentation}\\p{Emoji}]", options: [])
        let result = emojiRegex.stringByReplacingMatches(in: text, range: NSRange(text.startIndex..., in: text), withTemplate: "")
        return result.trimmingCharacters(in: .whitespaces)
    }
    
    var body: some View {
        ZStack {
            Color(red: 0.89, green: 0.95, blue: 0.99)
            
            VStack(alignment: .leading, spacing: family == .systemLarge ? 12 : 8) {
                HStack {
                    Text("💰 Budget Tracker")
                        .font(.system(size: family == .systemLarge ? 18 : 16, weight: .bold))
                        .foregroundColor(.black)
                    Spacer()
                }
                .padding(.bottom, 4)
                
                // SHOW DEBUG INFO ALWAYS (for now)
                if entry.categoryBudgets.isEmpty {
                    ScrollView {
                        Text(entry.debugInfo)
                            .font(.system(size: 9, design: .monospaced))
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                } else {
                    // Show normal budget display
                    let sortedCategories = entry.categoryBudgets.keys.sorted()
                    let displayCount = family == .systemLarge ? min(6, sortedCategories.count) : min(3, sortedCategories.count)
                    
                    ForEach(sortedCategories.prefix(displayCount), id: \.self) { category in
                        let budget = entry.categoryBudgets[category] ?? 0
                        let spent = entry.categorySpent[category] ?? 0
                        let remaining = budget - spent
                        let emoji = extractEmoji(from: category)
                        let name = extractName(from: category)
                        
                        HStack(spacing: 10) {
                            Text(emoji)
                                .font(.system(size: family == .systemLarge ? 28 : 24))
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(name.isEmpty ? "Category" : name.capitalized)
                                    .font(.system(size: family == .systemLarge ? 14 : 12, weight: .semibold))
                                    .foregroundColor(.black)
                                    .lineLimit(1)
                                
                                GeometryReader { geo in
                                    ZStack(alignment: .leading) {
                                        RoundedRectangle(cornerRadius: 4)
                                            .fill(Color.gray.opacity(0.2))
                                        
                                        if budget > 0 {
                                            RoundedRectangle(cornerRadius: 4)
                                                .fill(remaining > 0 ? Color.green : Color.red)
                                                .frame(width: geo.size.width * CGFloat(min(spent / budget, 1.0)))
                                        }
                                    }
                                }
                                .frame(height: 6)
                            }
                            
                            Spacer()
                            
                            VStack(alignment: .trailing, spacing: 2) {
                                Text("\(Int(spent))/\(Int(budget))")
                                    .font(.system(size: family == .systemLarge ? 13 : 11, weight: .bold))
                                    .foregroundColor(.black)
                                
                                Text("₹\(Int(remaining))")
                                    .font(.system(size: family == .systemLarge ? 11 : 9))
                                    .foregroundColor(remaining > 0 ? .green : .red)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                    
                    Spacer()
                }
            }
            .padding(family == .systemLarge ? 16 : 12)
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