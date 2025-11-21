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

struct LiquidWave: Shape {
    var offset: CGFloat
    var animatableData: CGFloat {
        get { offset }
        set { offset = newValue }
    }

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let width = rect.width
        let height = rect.height
        path.move(to: CGPoint(x: 0, y: height * 0.2))
        // Create wave
        for x in stride(from: 0, through: width, by: 1) {
            let relativeX = x / width
            let sine = sin(relativeX * .pi * 2 + offset)
            let y = height * 0.2 + sine * 5
            path.addLine(to: CGPoint(x: x, y: y))
        }
        path.addLine(to: CGPoint(x: width, y: height))
        path.addLine(to: CGPoint(x: 0, y: height))
        path.closeSubpath()
        return path
    }
}

struct LiquidContainer: View {
    let emoji: String
    let liquidColor: Color
    @State private var waveOffset: CGFloat = 0

    var body: some View {
        ZStack {
            // Glass container background
            Circle()
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.white.opacity(0.25),
                            Color.white.opacity(0.1)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    Circle()
                        .stroke(Color.white.opacity(0.5), lineWidth: 2)
                )
                .shadow(color: Color.black.opacity(0.15), radius: 5, x: 0, y: 3)
            // Liquid fill (full)
            Circle()
                .fill(liquidColor.opacity(0.85))
                .padding(4)
            // Animated wave on top
            LiquidWave(offset: waveOffset)
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            liquidColor.opacity(0.6),
                            liquidColor.opacity(0.4)
                        ]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .clipShape(Circle())
                .padding(4)
                .onAppear {
                    withAnimation(Animation.linear(duration: 2).repeatForever(autoreverses: false)) {
                        waveOffset = .pi * 2
                    }
                }
            // Glass shine effect
            Circle()
                .fill(
                    RadialGradient(
                        gradient: Gradient(colors: [
                            Color.white.opacity(0.4),
                            Color.clear
                        ]),
                        center: UnitPoint(x: 0.3, y: 0.3),
                        startRadius: 0,
                        endRadius: 30
                    )
                )
                .blur(radius: 1)
            // Emoji on top
            Text(emoji)
                .font(.system(size: 32))
                .shadow(color: Color.black.opacity(0.3), radius: 2, x: 0, y: 2)
        }
    }
}

struct NeoPopButton: View {
    let family: WidgetFamily

    var body: some View {
        ZStack {
            // Shadow layers for 3D effect
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.black.opacity(0.3))
                .offset(x: 4, y: 4)
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(red: 0.2, green: 0.5, blue: 0.2))
                .offset(x: 2, y: 2)
            // Main button
            RoundedRectangle(cornerRadius: 12)
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color(red: 0.35, green: 0.75, blue: 0.35),
                            Color(red: 0.3, green: 0.69, blue: 0.31)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color(red: 0.4, green: 0.8, blue: 0.4), lineWidth: 2)
                )
            // Button content
            HStack(spacing: 8) {
                Text("💳")
                    .font(.system(size: family == .systemLarge ? 20 : 18))
                Text("Pay Now")
                    .font(.system(size: family == .systemLarge ? 18 : 16, weight: .bold))
                    .foregroundColor(.white)
                    .shadow(color: Color.black.opacity(0.3), radius: 1, x: 0, y: 1)
            }
        }
    }
}

struct HomeWidgetEntryView: View {
    var entry: Provider.Entry
    @Environment(\.widgetFamily) var family

    let categories = [
        CategoryItem(emoji: "🍔", name: "Food", liquidColor: Color(red: 1.0, green: 0.6, blue: 0.2)),
        CategoryItem(emoji: "🛍️", name: "Shopping", liquidColor: Color(red: 0.9, green: 0.3, blue: 0.5)),
        CategoryItem(emoji: "✈️", name: "Travel", liquidColor: Color(red: 0.3, green: 0.7, blue: 1.0)),
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
            VStack(spacing: 0) {
                // Top spacing
                Spacer()
                    .frame(height: family == .systemLarge ? 20 : 16)
                // Top section: Mascot + Pay Now button
                HStack(spacing: 12) {
                    // Mascot image
                    if let mascotImage = UIImage(named: "mascot") {
                        Image(uiImage: mascotImage)
                            .resizable()
                            .scaledToFit()
                            .frame(height: family == .systemLarge ? 50 : 40)
                    }
                    // Pay Now button with NeoPop style
                    NeoPopButton(family: family)
                        .frame(height: family == .systemLarge ? 50 : 40)
                }
                .padding(.horizontal, family == .systemLarge ? 24 : 20)
                // Space between button and categories
                Spacer()
                    .frame(height: family == .systemLarge ? 24 : 18)
                // "Categories" label
                HStack {
                    Text("Categories")
                        .font(.system(size: family == .systemLarge ? 16 : 14, weight: .bold))
                        .foregroundColor(.white)
                        .shadow(color: Color.black.opacity(0.3), radius: 2, x: 0, y: 1)
                    Spacer()
                }
                .padding(.horizontal, family == .systemLarge ? 24 : 20)
                .padding(.bottom, family == .systemLarge ? 12 : 8)
                // Categories section - ALWAYS SHOW 5
                let containerSize: CGFloat = family == .systemLarge ? 60 : 50
                HStack(spacing: family == .systemLarge ? 14 : 10) {
                    ForEach(0..<5, id: \.self) { index in
                        Link(destination: URL(string: "slideme://category?name=\(categories[index].name)")!) {
                            VStack(spacing: 4) {
                                LiquidContainer(
                                    emoji: categories[index].emoji,
                                    liquidColor: categories[index].liquidColor
                                )
                                .frame(width: containerSize, height: containerSize)
                                if family == .systemLarge {
                                    Text(categories[index].name)
                                        .font(.system(size: 10, weight: .medium))
                                        .foregroundColor(.white)
                                        .shadow(color: Color.black.opacity(0.3), radius: 1, x: 0, y: 1)
                                        .lineLimit(1)
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, family == .systemLarge ? 24 : 20)
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
