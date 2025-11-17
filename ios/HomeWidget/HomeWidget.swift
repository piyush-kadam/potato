import WidgetKit
import SwiftUI
import FirebaseCore
import FirebaseFirestore

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), categoryBudgets: [:], categorySpent: [:], isLoading: true)
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        // For preview, return placeholder
        let entry = SimpleEntry(date: Date(), categoryBudgets: [:], categorySpent: [:], isLoading: true)
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        // Initialize Firebase if needed
        if FirebaseApp.app() == nil {
            FirebaseApp.configure()
        }
        
        // Get the user ID (you'll need to store this in UserDefaults from Flutter)
        let userId = UserDefaults(suiteName: "group.com.potato.slideme")?.string(forKey: "userId") ?? ""
        
        if userId.isEmpty {
            // No user ID, return empty entry
            let entry = SimpleEntry(date: Date(), categoryBudgets: [:], categorySpent: [:], isLoading: false)
            let timeline = Timeline(entries: [entry], policy: .after(Date().addingTimeInterval(900)))
            completion(timeline)
            return
        }
        
        // Fetch data from Firestore
        let db = Firestore.firestore()
        db.collection("Users").document(userId).getDocument { document, error in
            var budgets: [String: Double] = [:]
            var spent: [String: Double] = [:]
            
            if let document = document, document.exists {
                let data = document.data()
                
                // Parse categoryBudgets
                if let categoryBudgets = data?["categoryBudgets"] as? [String: Any] {
                    for (key, value) in categoryBudgets {
                        if let numValue = value as? NSNumber {
                            budgets[key] = numValue.doubleValue
                        }
                    }
                }
                
                // Parse categorySpent
                if let categorySpent = data?["categorySpent"] as? [String: Any] {
                    for (key, value) in categorySpent {
                        if let numValue = value as? NSNumber {
                            spent[key] = numValue.doubleValue
                        }
                    }
                }
            }
            
            let entry = SimpleEntry(date: Date(), categoryBudgets: budgets, categorySpent: spent, isLoading: false)
            // Refresh every 15 minutes
            let timeline = Timeline(entries: [entry], policy: .after(Date().addingTimeInterval(900)))
            completion(timeline)
        }
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let categoryBudgets: [String: Double]
    let categorySpent: [String: Double]
    let isLoading: Bool
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
                // Header
                HStack {
                    Text("💰 Budget Tracker")
                        .font(.system(size: family == .systemLarge ? 18 : 16, weight: .bold))
                        .foregroundColor(.black)
                    Spacer()
                }
                .padding(.bottom, 4)
                
                if entry.isLoading {
                    Spacer()
                    ProgressView()
                    Spacer()
                } else if entry.categoryBudgets.isEmpty {
                    Spacer()
                    Text("No budget data available")
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                        .frame(maxWidth: .infinity, alignment: .center)
                    Spacer()
                } else {
                    // Categories
                    let sortedCategories = entry.categoryBudgets.keys.sorted()
                    let displayCount = family == .systemLarge ? min(6, sortedCategories.count) : min(3, sortedCategories.count)
                    
                    ForEach(sortedCategories.prefix(displayCount), id: \.self) { category in
                        let budget = entry.categoryBudgets[category] ?? 0
                        let spent = entry.categorySpent[category] ?? 0
                        let remaining = budget - spent
                        let emoji = extractEmoji(from: category)
                        let name = extractName(from: category)
                        
                        HStack(spacing: 10) {
                            // Emoji
                            Text(emoji)
                                .font(.system(size: family == .systemLarge ? 28 : 24))
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(name.capitalized)
                                    .font(.system(size: family == .systemLarge ? 14 : 12, weight: .semibold))
                                    .foregroundColor(.black)
                                    .lineLimit(1)
                                
                                // Progress bar
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
                            
                            // Amount
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
    
    init() {
        // Initialize Firebase when widget loads
        if FirebaseApp.app() == nil {
            FirebaseApp.configure()
        }
    }

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            HomeWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Budget Tracker")
        .description("Track your category budgets and spending.")
        .supportedFamilies([.systemMedium, .systemLarge])
    }
}