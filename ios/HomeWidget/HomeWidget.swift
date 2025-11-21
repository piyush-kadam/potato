import WidgetKit
import SwiftUI

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date())
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        let entry = SimpleEntry(date: Date())
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        let entry = SimpleEntry(date: Date())
        let timeline = Timeline(entries: [entry], policy: .after(Date().addingTimeInterval(900)))
        completion(timeline)
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
}

struct CategoryItem {
    let emoji: String
    let name: String
    let liquidColor: Color
}

struct LiquidContainer: View {
    let emoji: String
    let liquidColor: Color
    let fillPercentage: Double = 0.6 // 60% filled for visual appeal
    
    var body: some View {
        ZStack {
            // Glass container
            Circle()
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.white.opacity(0.3),
                            Color.white.opacity(0.1)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    Circle()
                        .stroke(Color.white.opacity(0.4), lineWidth: 1.5)
                )
                .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
            
            // Liquid inside
            GeometryReader { geo in
                let size = geo.size.width
                let fillHeight = size * CGFloat(fillPercentage)
                
                ZStack {
                    // Liquid with wave effect
                    Circle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    liquidColor.opacity(0.8),
                                    liquidColor.opacity(0.6)
                                ]),
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(width: size * 0.85, height: size * 0.85)
                        .blur(radius: 2)
                    
                    // Shine effect
                    Circle()
                        .fill(
                            RadialGradient(
                                gradient: Gradient(colors: [
                                    Color.white.opacity(0.3),
                                    Color.clear
                                ]),
                                center: .topLeading,
                                startRadius: 0,
                                endRadius: size * 0.5
                            )
                        )
                        .frame(width: size * 0.4, height: size * 0.4)
                        .offset(x: -size * 0.15, y: -size * 0.15)
                }
            }
            
            // Emoji on top
            Text(emoji)
                .font(.system(size: 28))
                .shadow(color: Color.black.opacity(0.2), radius: 2, x: 0, y: 1)
        }
    }
}

struct HomeWidgetEntryView: View {
    var entry: Provider.Entry
    @Environment(\.widgetFamily) var family
    
    let categories = [
        CategoryItem(emoji: "🍔", name: "Food", liquidColor: Color(red: 1.0, green: 0.6, blue: 0.2)),
        CategoryItem(emoji: "🛍️", name: "Shopping", liquidColor: Color(red: 0.9, green: 0.3, blue: 0.5)),
        CategoryItem(emoji: "✈️", name: "Travel", liquidColor: Color(red: 0.2, green: 0.6, blue: 1.0)),
        CategoryItem(emoji: "🎬", name: "Entertainment", liquidColor: Color(red: 0.7, green: 0.3, blue: 0.9)),
        CategoryItem(emoji: "💰", name: "Savings", liquidColor: Color(red: 1.0, green: 0.8, blue: 0.2))
    ]
    
    var body: some View {
        ZStack {
            // Background image
            if let bgImage = UIImage(named: "bgg") {
                Image(uiImage: bgImage)
                    .resizable()
                    .scaledToFill()
                    .opacity(0.3)
            }
            
            // Background color overlay
            Color(red: 0.3, green: 0.69, blue: 0.31)
                .opacity(0.85)
            
            VStack(spacing: family == .systemLarge ? 16 : 12) {
                // Top section: Mascot + Pay Now button
                HStack(spacing: 12) {
                    // Mascot image
                    if let mascotImage = UIImage(named: "mascot") {
                        Image(uiImage: mascotImage)
                            .resizable()
                            .scaledToFit()
                            .frame(height: family == .systemLarge ? 50 : 40)
                    }
                    
                    // Pay Now button
                    Link(destination: URL(string: "slideme://open")!) {
                        HStack {
                            Text("💳 Pay Now")
                                .font(.system(size: family == .systemLarge ? 18 : 16, weight: .bold))
                                .foregroundColor(.white)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: family == .systemLarge ? 50 : 40)
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color(red: 0.3, green: 0.69, blue: 0.31),
                                    Color(red: 0.25, green: 0.6, blue: 0.26)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .cornerRadius(12)
                        .shadow(color: Color.black.opacity(0.2), radius: 4, x: 0, y: 2)
                    }
                }
                .padding(.horizontal, family == .systemLarge ? 20 : 16)
                .padding(.top, family == .systemLarge ? 20 : 16)
                
                // Categories section
                let displayCount = family == .systemLarge ? 5 : 3
                let containerSize: CGFloat = family == .systemLarge ? 70 : 55
                
                HStack(spacing: family == .systemLarge ? 20 : 12) {
                    ForEach(0..<displayCount, id: \.self) { index in
                        if index < categories.count {
                            Link(destination: URL(string: "slideme://open")!) {
                                VStack(spacing: 4) {
                                    LiquidContainer(
                                        emoji: categories[index].emoji,
                                        liquidColor: categories[index].liquidColor
                                    )
                                    .frame(width: containerSize, height: containerSize)
                                    
                                    if family == .systemLarge {
                                        Text(categories[index].name)
                                            .font(.system(size: 11, weight: .medium))
                                            .foregroundColor(.white)
                                            .shadow(color: Color.black.opacity(0.3), radius: 1, x: 0, y: 1)
                                    }
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, family == .systemLarge ? 20 : 16)
                
                Spacer()
            }
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
        .configurationDisplayName("SlideMe Budget")
        .description("Quick access to your budget categories.")
        .supportedFamilies([.systemMedium, .systemLarge])
    }
}