import SwiftUI

struct MapView: View {
    @EnvironmentObject private var model: AppModel
    @Environment(\.questTheme) private var theme

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            regionPicker
            if let catalog = model.catalog {
                recommendation(catalog)
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        if model.mapLevel > model.progress.highestUnlockedLevel {
                            Text(lockedCopy)
                                .font(.system(size: 18, weight: .medium, design: .rounded))
                                .foregroundStyle(theme.ink)
                                .padding(16)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(theme.highlight, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                                .padding(.horizontal, 24)
                                .padding(.bottom, 12)
                        }
                        let passages = catalog.passages(at: model.mapLevel)
                        ForEach(Array(passages.enumerated()), id: \.element.id) { index, passage in
                            HStack {
                                if index % 2 == 0 {
                                    node(passage, catalog: catalog)
                                    Spacer(minLength: 48)
                                } else {
                                    Spacer(minLength: 48)
                                    node(passage, catalog: catalog)
                                }
                            }
                            .padding(.horizontal, 28)
                            if index < passages.count - 1 {
                                HStack {
                                    Spacer()
                                    Capsule()
                                        .fill(theme.trail(model.mapLevel).opacity(0.45))
                                        .frame(width: 6, height: 28)
                                    Spacer()
                                }
                            }
                        }
                    }
                    .padding(.vertical, 18)
                }
            }
        }
    }

    private var regionPicker: some View {
        HStack(spacing: 10) {
            ForEach(1...3, id: \.self) { level in
                Button {
                    model.selectMapLevel(level)
                } label: {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(TrailGuide.name(for: level))
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                        Text(TrailGuide.blurb(for: level))
                            .font(.system(size: 12, weight: .medium, design: .rounded))
                            .lineLimit(2)
                    }
                    .foregroundStyle(model.mapLevel == level ? Color.white : theme.ink)
                    .padding(12)
                    .frame(maxWidth: .infinity, minHeight: 64, alignment: .leading)
                    .background(
                        model.mapLevel == level ? theme.trail(level) : theme.card,
                        in: RoundedRectangle(cornerRadius: 14, style: .continuous)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(theme.stroke, lineWidth: model.mapLevel == level ? 0 : 1)
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 22)
        .padding(.top, 16)
    }

    private func recommendation(_ catalog: Catalog) -> some View {
        let next = QuestRules.recommendedPassage(catalog: catalog, progress: model.progress)
        return HStack(alignment: .center, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Your next story")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(theme.muted)
                if let next {
                    Text(next.title)
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundStyle(theme.ink)
                    Text(TrailGuide.name(for: next.level))
                        .font(.system(size: 15, design: .rounded))
                        .foregroundStyle(theme.muted)
                } else {
                    Text("You have stars on every open story. Replay any stop to polish a page.")
                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                        .foregroundStyle(theme.ink)
                }
            }
            Spacer()
            if next != nil {
                Button("Read it") { model.openRecommended() }
                    .buttonStyle(QuestButtonStyle(fill: theme.trail(model.progress.recommendedLevel), ink: .white, wide: false))
            }
        }
        .padding(16)
        .background(theme.card, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .padding(.horizontal, 22)
        .padding(.top, 14)
    }

    private func node(_ passage: Passage, catalog: Catalog) -> some View {
        let unlocked = QuestRules.isPassageUnlocked(passage, catalog: catalog, progress: model.progress)
        let stat = model.progress.passageStats[passage.id]
        let isNext = QuestRules.recommendedPassage(catalog: catalog, progress: model.progress)?.id == passage.id
        return Button {
            model.openPassage(passage.id)
        } label: {
            HStack(alignment: .top, spacing: 12) {
                ZStack {
                    Circle()
                        .fill(unlocked ? theme.trail(passage.level) : theme.muted.opacity(0.35))
                        .frame(width: 48, height: 48)
                    if unlocked {
                        KindIcon(kind: passage.kind)
                            .font(.system(size: 20))
                            .foregroundStyle(Color.white)
                    } else {
                        Image(systemName: "lock.fill")
                            .foregroundStyle(Color.white)
                    }
                }
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text(passage.kind.kidLabel)
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                            .foregroundStyle(theme.trail(passage.level))
                        if isNext {
                            Text("Next")
                                .font(.system(size: 12, weight: .bold, design: .rounded))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(theme.highlight, in: Capsule())
                                .foregroundStyle(theme.highlightInk)
                        }
                    }
                    Text(passage.title)
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundStyle(theme.ink)
                        .multilineTextAlignment(.leading)
                    if let stat, stat.attempts > 0 {
                        StarRow(stars: stat.bestStars)
                    } else if unlocked {
                        Text("Ready to read")
                            .font(.system(size: 14, design: .rounded))
                            .foregroundStyle(theme.muted)
                    } else {
                        Text("Finish the story before this one")
                            .font(.system(size: 14, design: .rounded))
                            .foregroundStyle(theme.muted)
                    }
                }
                Spacer(minLength: 0)
            }
            .padding(14)
            .frame(maxWidth: 420, alignment: .leading)
            .background(theme.card, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(isNext ? theme.gold : theme.stroke, lineWidth: isNext ? 3 : 1)
            )
        }
        .buttonStyle(.plain)
        .disabled(!unlocked)
        .accessibilityHint(unlocked ? "Opens the story" : "Locked until the earlier story is finished")
    }

    private var lockedCopy: String {
        if model.mapLevel == 2 {
            return "Whispering Woods opens after four Meadow stories, or sooner if the questions feel easy."
        }
        return "Starlight Peaks opens after four Woods stories, or when your reading is ready for a steeper trail."
    }
}
