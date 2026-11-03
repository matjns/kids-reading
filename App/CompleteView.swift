import SwiftUI

struct CompleteView: View {
    @EnvironmentObject private var model: AppModel
    @Environment(\.questTheme) private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var shown = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                if let passage = model.currentPassage, let outcome = model.outcome {
                    Text(passage.title)
                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                        .foregroundStyle(theme.muted)
                    Text(headline(outcome))
                        .font(QuestFont.display(36))
                        .foregroundStyle(theme.ink)
                    HStack(spacing: 10) {
                        ForEach(1...3, id: \.self) { index in
                            Image(systemName: index <= outcome.stars ? "star.fill" : "star")
                                .font(.system(size: 52))
                                .foregroundStyle(index <= outcome.stars ? theme.gold : theme.muted.opacity(0.35))
                                .scaleEffect(shown || reduceMotion ? 1 : 0.4)
                                .animation(
                                    reduceMotion ? nil : .spring(response: 0.4, dampingFraction: 0.7).delay(Double(index) * 0.08),
                                    value: shown
                                )
                        }
                    }
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel("\(outcome.stars) stars")
                    Text(starExplanation(outcome))
                        .font(.system(size: 18, design: .rounded))
                        .foregroundStyle(theme.muted)
                    Text("\(outcome.correct) of \(outcome.total) questions matched the story.")
                        .font(.system(size: 20, weight: .medium, design: .rounded))
                        .foregroundStyle(theme.ink)
                    if outcome.stars > outcome.previousBestStars && outcome.previousBestStars > 0 {
                        Text("That is a new best for this story.")
                            .font(.system(size: 18, weight: .semibold, design: .rounded))
                            .foregroundStyle(theme.meadow)
                    }
                    if let change = outcome.levelChange {
                        Text(change.message)
                            .font(.system(size: 20, weight: .semibold, design: .rounded))
                            .foregroundStyle(theme.highlightInk)
                            .padding(16)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(theme.highlight, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                    }
                    if !outcome.newBadges.isEmpty {
                        Text("New badges")
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundStyle(theme.ink)
                        ForEach(outcome.newBadges) { badge in
                            VStack(alignment: .leading, spacing: 4) {
                                Text(badge.title)
                                    .font(.system(size: 20, weight: .bold, design: .rounded))
                                Text(badge.howToEarn)
                                    .font(.system(size: 16, design: .rounded))
                                    .foregroundStyle(theme.muted)
                            }
                            .padding(14)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(theme.card, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                        }
                    }
                    HStack(spacing: 12) {
                        Button("Back to the map") { model.showMap() }
                            .buttonStyle(QuestButtonStyle(fill: theme.card, ink: theme.ink))
                        Button("Read another") { model.openRecommended() }
                            .buttonStyle(QuestButtonStyle(fill: theme.trail(outcome.recommendedLevel), ink: .white))
                            .keyboardShortcut(.defaultAction)
                    }
                    if outcome.stars < 3 {
                        Button("Try this story again") { model.openPassage(passage.id) }
                            .buttonStyle(QuestButtonStyle(fill: theme.card, ink: theme.ink, wide: false))
                    }
                }
            }
            .padding(32)
            .frame(maxWidth: 760, alignment: .leading)
            .frame(maxWidth: .infinity)
        }
        .onAppear { shown = true }
    }

    private func headline(_ outcome: AttemptOutcome) -> String {
        switch outcome.stars {
        case 3:
            return "Every question clicked."
        case 2:
            return "You caught most of it."
        default:
            return "You finished the story."
        }
    }

    private func starExplanation(_ outcome: AttemptOutcome) -> String {
        switch outcome.stars {
        case 3:
            return "3 stars means every answer matched the story."
        case 2:
            return "2 stars means most answers matched. You can replay for 3."
        default:
            return "1 star means you finished. Look-backs are there whenever you want another try."
        }
    }
}
