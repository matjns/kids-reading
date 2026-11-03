import SwiftUI

struct QuestButtonStyle: ButtonStyle {
    var fill: Color
    var ink: Color
    var wide: Bool = true

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 20, weight: .semibold, design: .rounded))
            .foregroundStyle(ink)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 18)
            .padding(.vertical, 12)
            .frame(maxWidth: wide ? .infinity : nil, minHeight: 56)
            .background(fill, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .opacity(configuration.isPressed ? 0.84 : 1)
    }
}

struct TopBar: View {
    @EnvironmentObject private var model: AppModel
    @Environment(\.questTheme) private var theme

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Reading Quest")
                        .font(QuestFont.display(22))
                        .foregroundStyle(theme.ink)
                    Text(greeting)
                        .font(.system(size: 15, weight: .medium, design: .rounded))
                        .foregroundStyle(theme.muted)
                }
                Spacer(minLength: 12)
                starPill
                Button("Map") { model.showMap() }
                    .buttonStyle(QuestButtonStyle(fill: theme.trail(model.progress.recommendedLevel), ink: .white, wide: false))
                    .disabled(model.catalog == nil)
                Button("Progress") { model.showProgress() }
                    .buttonStyle(QuestButtonStyle(fill: theme.card, ink: theme.ink, wide: false))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(theme.stroke, lineWidth: 1)
                    )
                    .disabled(model.catalog == nil)
            }
            if let saveWarning = model.saveWarning {
                Text(saveWarning)
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundStyle(theme.coral)
            }
        }
        .padding(.horizontal, 22)
        .padding(.vertical, 14)
        .background(theme.card)
    }

    private var greeting: String {
        if model.progress.playerName.isEmpty {
            return TrailGuide.name(for: model.progress.recommendedLevel)
        }
        return "\(model.progress.playerName) · \(TrailGuide.name(for: model.progress.recommendedLevel))"
    }

    private var starPill: some View {
        HStack(spacing: 6) {
            Image(systemName: "star.fill")
                .foregroundStyle(theme.gold)
            Text("\(model.progress.totalStars)")
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundStyle(theme.ink)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(theme.parchment, in: Capsule())
        .accessibilityLabel("\(model.progress.totalStars) stars")
    }
}

struct TrailSketch: View {
    @Environment(\.questTheme) private var theme

    var body: some View {
        Canvas { context, size in
            let sky = Path(CGRect(origin: .zero, size: size))
            context.fill(sky, with: .color(theme.meadow.opacity(0.12)))

            var hill = Path()
            hill.move(to: CGPoint(x: 0, y: size.height * 0.62))
            hill.addQuadCurve(
                to: CGPoint(x: size.width, y: size.height * 0.7),
                control: CGPoint(x: size.width * 0.55, y: size.height * 0.28)
            )
            hill.addLine(to: CGPoint(x: size.width, y: size.height))
            hill.addLine(to: CGPoint(x: 0, y: size.height))
            hill.closeSubpath()
            context.fill(hill, with: .color(theme.meadow))

            var trailLine = Path()
            trailLine.move(to: CGPoint(x: size.width * 0.12, y: size.height * 0.92))
            trailLine.addCurve(
                to: CGPoint(x: size.width * 0.86, y: size.height * 0.58),
                control1: CGPoint(x: size.width * 0.35, y: size.height * 0.78),
                control2: CGPoint(x: size.width * 0.62, y: size.height * 0.95)
            )
            context.stroke(trailLine, with: .color(theme.highlight), lineWidth: 8)

            let book = CGRect(x: size.width * 0.42, y: size.height * 0.34, width: size.width * 0.16, height: size.height * 0.22)
            context.fill(Path(roundedRect: book, cornerRadius: 8), with: .color(theme.parchment))
            var spine = Path()
            spine.move(to: CGPoint(x: book.midX, y: book.minY + 6))
            spine.addLine(to: CGPoint(x: book.midX, y: book.maxY - 6))
            context.stroke(spine, with: .color(theme.gold), lineWidth: 3)
        }
        .frame(height: 190)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .accessibilityHidden(true)
    }
}

struct StarRow: View {
    var stars: Int
    var total: Int = 3
    var size: CGFloat = 18

    @Environment(\.questTheme) private var theme

    var body: some View {
        HStack(spacing: 3) {
            ForEach(1...total, id: \.self) { index in
                Image(systemName: index <= stars ? "star.fill" : "star")
                    .font(.system(size: size))
                    .foregroundStyle(index <= stars ? theme.gold : theme.muted.opacity(0.45))
            }
        }
        .accessibilityLabel("\(stars) of \(total) stars")
    }
}

struct KindIcon: View {
    var kind: PassageKind

    var body: some View {
        Image(systemName: symbol)
            .accessibilityHidden(true)
    }

    private var symbol: String {
        switch kind {
        case .fable:
            return "book.fill"
        case .fiction:
            return "sparkles"
        case .nonfiction:
            return "globe"
        case .poem:
            return "quote.opening"
        }
    }
}
