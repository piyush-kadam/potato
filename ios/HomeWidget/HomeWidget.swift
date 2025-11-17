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
        let timeline = Timeline(entries: [entry], policy: .after(Date().addingTimeInterval(900)))
        completion(timeline)
    }
    
    func loadData() -> SimpleEntry {
        guard let data = UserDefaults(suiteName: "group.com.potato.slideme") else {
            return SimpleEntry(date: Date(), categoryBudgets: [:], categorySpent: [:])
        }
        
        // Try ALL possible key variations
        var budgetsData: String? = nil
        var spentData: String? = nil
        
        // Try 1: Direct keys
        budgetsData = data.string(forKey: "categoryBudgets")
        spentData = data.string(forKey: "categorySpent")
        
        // Try 2: flutter. prefix
        if budgetsData == nil {
            budgetsData = data.string(forKey: "flutter.categoryBudgets")
        }
        if spentData == nil {
            spentData = data.string(forKey: "flutter.categorySpent")
        }
        
        // Try 3: HomeWidget. prefix
        if budgetsData == nil {
            budgetsData = data.string(forKey: "HomeWidget.categoryBudgets")
        }
        if spentData == nil {
            spentData = data.string(forKey: "HomeWidget.categorySpent")
        }
        
        let budgets = parseCategoryData(budgetsData ?? "{}")
        let spent = parseCategoryData(spentData ?? "{}")
        
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
                
                if entry.categoryBudgets.isEmpty {
                    Spacer()
                    Text("No budget data available")
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                        .frame(maxWidth: .infinity, alignment: .center)
                    Spacer()
                } else {
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
                                Text(name.capitalized)
                                    .font(.system(size: family == .systemLarge ? 14 : 12, weight: .semibold))
                                    .foregroundColor(.black)
                                    .lineLimit(1)
                                
                                GeometryReader { geo in
                                    ZStack(alignment: .leading) {
                                        RoundedRectangle(cornerRadius: 4)
                                            .fill(Color.gray.opacity(0.2))
                                        
                                        RoundedRectangle(cornerRadius: 4)
                                            .fill(remaining > 0 ? Color.green : Color.red)
                                            .frame(width: geo.size.width * CGFloat(min(spent / budget, 1.0)))
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