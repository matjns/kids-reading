import SwiftUI

struct ProgressView: View {
    @EnvironmentObject private var model: AppModel
    @Environment(\.questTheme) private var theme
    @State private var confirmReset = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Your progress")
                    .font(QuestFont.display(36))
                    .foregroundStyle(theme.ink)
                Text(adaptiveCopy)
                    .font(.system(size: 18, design: .rounded))
                    .foregroundStyle(theme.ink)
                    .fixedSize(horizontal: false, vertical: true)

                LazyVGrid(columns: [GridItem(.adaptive(minimum: 180), spacing: 12)], spacing: 12) {
                    stat("Stories finished", "\(model.progress.passagesFinished)")
                    stat("Stars", "\(model.progress.totalStars)")
                    stat("Questions gotten right", "\(model.progress.questionsCorrect)")
                    stat("Suggested trail", TrailGuide.name(for: model.progress.recommendedLevel))
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Name on this Mac")
                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                        .foregroundStyle(theme.ink)
                    TextField("Leave blank if you like", text: nameBinding)
                        .textFieldStyle(.roundedBorder)
                        .font(.system(size: 20, design: .rounded))
                        .onSubmit { model.saveName() }
                    Button("Save name") { model.saveName() }
                        .buttonStyle(QuestButtonStyle(fill: theme.card, ink: theme.ink, wide: false))
                }

                Button(model.progress.biggerText ? "Use regular text" : "Use bigger text") {
                    model.toggleBiggerText()
                }
                .buttonStyle(QuestButtonStyle(fill: theme.meadow, ink: .white, wide: false))

                if let catalog = model.catalog {
                    Text("Badges")
                        .font(QuestFont.display(26))
                        .foregroundStyle(theme.ink)
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 220), spacing: 12)], spacing: 12) {
                        ForEach(Badges.all(progress: model.progress, catalog: catalog)) { badge in
                            VStack(alignment: .leading, spacing: 6) {
                                HStack {
                                    Image(systemName: badge.earned ? "rosette" : "circle")
                                        .foregroundStyle(badge.earned ? theme.gold : theme.muted)
                                    Text(badge.title)
                                        .font(.system(size: 18, weight: .bold, design: .rounded))
                                        .foregroundStyle(theme.ink)
                                }
                                Text(badge.howToEarn)
                                    .font(.system(size: 15, design: .rounded))
                                    .foregroundStyle(theme.muted)
                            }
                            .padding(14)
                            .frame(maxWidth: .infinity, minHeight: 110, alignment: .topLeading)
                            .background(badge.earned ? theme.highlight.opacity(0.55) : theme.card, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .stroke(theme.stroke, lineWidth: 1)
                            )
                            .accessibilityLabel(badge.earned ? "\(badge.title), earned" : "\(badge.title), not yet")
                        }
                    }

                    Text("Recent stories")
                        .font(QuestFont.display(26))
                        .foregroundStyle(theme.ink)
                    if model.progress.attempts.isEmpty {
                        Text("Your map is still quiet. Finish a story and it will show up here.")
                            .font(.system(size: 18, design: .rounded))
                            .foregroundStyle(theme.muted)
                    } else {
                        ForEach(Array(model.progress.attempts.suffix(8).reversed())) { attempt in
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(catalog.passage(id: attempt.passageId)?.title ?? "Story")
                                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                                        .foregroundStyle(theme.ink)
                                    Text(attempt.answeredAt)
                                        .font(.system(size: 13, design: .rounded))
                                        .foregroundStyle(theme.muted)
                                }
                                Spacer()
                                Text("\(attempt.correct)/\(attempt.total)")
                                    .font(.system(size: 16, weight: .bold, design: .rounded))
                                    .foregroundStyle(theme.ink)
                                StarRow(stars: attempt.stars)
                            }
                            .padding(12)
                            .background(theme.card, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                        }
                    }
                }

                HStack(spacing: 12) {
                    Button("Back to the map") { model.backToMap() }
                        .buttonStyle(QuestButtonStyle(fill: theme.trail(model.progress.recommendedLevel), ink: .white))
                    Button("Start over") { confirmReset = true }
                        .buttonStyle(QuestButtonStyle(fill: theme.card, ink: theme.coral))
                }
            }
            .padding(28)
            .frame(maxWidth: 920, alignment: .leading)
            .frame(maxWidth: .infinity)
        }
        .confirmationDialog(
            "Erase stars and badges on this Mac?",
            isPresented: $confirmReset,
            titleVisibility: .visible
        ) {
            Button("Erase progress", role: .destructive) { model.resetProgress() }
            Button("Keep my stars", role: .cancel) {}
        } message: {
            Text("This clears the saved progress file. Stories in the app stay.")
        }
    }

    private var adaptiveCopy: String {
        let name = TrailGuide.name(for: model.progress.recommendedLevel)
        return "Right now the quest suggests \(name). If questions come easily, the next stories get richer. If they feel steep, the quest steps back to a gentler trail. Open trails stay on your map."
    }

    private func stat(_ title: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundStyle(theme.muted)
            Text(value)
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundStyle(theme.ink)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(14)
        .frame(maxWidth: .infinity, minHeight: 88, alignment: .topLeading)
        .background(theme.card, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var nameBinding: Binding<String> {
        Binding(
            get: { model.draftName },
            set: { model.draftName = $0 }
        )
    }
}
