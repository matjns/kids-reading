import Foundation

public enum QuestRules {
    public static func isTrailUnlocked(_ level: Int, progress: ReadingProgress) -> Bool {
        level >= TrailGuide.minimumLevel
            && level <= TrailGuide.maximumLevel
            && level <= progress.highestUnlockedLevel
    }

    public static func isPassageUnlocked(_ passage: Passage, catalog: Catalog, progress: ReadingProgress) -> Bool {
        guard isTrailUnlocked(passage.level, progress: progress) else { return false }
        let peers = catalog.passages(at: passage.level)
        guard let index = peers.firstIndex(where: { $0.id == passage.id }) else { return false }
        if index == 0 { return true }
        let prior = peers[index - 1]
        return (progress.passageStats[prior.id]?.attempts ?? 0) > 0
    }

    public static func recommendedPassage(catalog: Catalog, progress: ReadingProgress) -> Passage? {
        let peers = catalog.passages(at: progress.recommendedLevel)
            .filter { isPassageUnlocked($0, catalog: catalog, progress: progress) }
        if let fresh = peers.first(where: { (progress.passageStats[$0.id]?.attempts ?? 0) == 0 }) {
            return fresh
        }
        return peers
            .filter { (progress.passageStats[$0.id]?.bestStars ?? 0) < 3 }
            .sorted { lhs, rhs in
                let leftStars = progress.passageStats[lhs.id]?.bestStars ?? 0
                let rightStars = progress.passageStats[rhs.id]?.bestStars ?? 0
                if leftStars != rightStars { return leftStars < rightStars }
                return lhs.order < rhs.order
            }
            .first
    }

    public static func completedCount(level: Int, catalog: Catalog, progress: ReadingProgress) -> Int {
        catalog.passages(at: level).filter { (progress.passageStats[$0.id]?.attempts ?? 0) > 0 }.count
    }

    public static func record(
        passageId: String,
        answers: [String: String],
        catalog: Catalog,
        progress: inout ReadingProgress,
        now: Date = Date(),
        identifier: String = UUID().uuidString
    ) -> AttemptOutcome? {
        guard let passage = catalog.passage(id: passageId) else { return nil }

        let beforeBadges = Set(Badges.all(progress: progress, catalog: catalog).filter(\.earned).map(\.id))
        let previousBest = progress.passageStats[passageId]?.bestStars ?? 0
        let playedAtRecommendedLevel = passage.level == progress.recommendedLevel

        var correct = 0
        var keys = progress.correctKeys
        var rolling = progress.rollingCorrect
        for question in passage.questions {
            let selected = answers[question.id] ?? ""
            let isCorrect = selected == question.answerId
            if isCorrect {
                correct += 1
                let key = Badges.correctKey(passageId: passage.id, questionId: question.id)
                if !keys.contains(key) {
                    keys.append(key)
                }
            }
            if playedAtRecommendedLevel {
                rolling.append(isCorrect)
            }
        }

        let total = passage.questions.count
        let stars = Scoring.stars(correct: correct, total: total)
        var stat = progress.passageStats[passageId] ?? PassageStat(attempts: 0, bestStars: 0, lastCorrect: 0, lastTotal: 0)
        stat.attempts += 1
        stat.lastCorrect = correct
        stat.lastTotal = total
        stat.bestStars = max(stat.bestStars, stars)

        var attempts = progress.attempts
        attempts.append(
            AttemptRecord(
                id: identifier,
                passageId: passage.id,
                correct: correct,
                total: total,
                stars: stars,
                level: passage.level,
                answeredAt: isoString(from: now)
            )
        )
        if attempts.count > Adaptation.attemptHistoryLimit {
            attempts.removeFirst(attempts.count - Adaptation.attemptHistoryLimit)
        }

        progress.correctKeys = keys
        progress.passageStats[passageId] = stat
        progress.attempts = attempts

        var levelChange: LevelChange?
        if playedAtRecommendedLevel {
            if rolling.count > Adaptation.windowSize {
                rolling.removeFirst(rolling.count - Adaptation.windowSize)
            }
            if rolling.count >= Adaptation.minimumAnswers {
                let hits = rolling.filter { $0 }.count
                let ratio = Double(hits) / Double(rolling.count)
                if ratio >= Adaptation.levelUpAccuracy, progress.recommendedLevel < TrailGuide.maximumLevel {
                    let fromLevel = progress.recommendedLevel
                    let toLevel = fromLevel + 1
                    progress.recommendedLevel = toLevel
                    rolling = []
                    levelChange = LevelChange(
                        fromLevel: fromLevel,
                        toLevel: toLevel,
                        message: TrailGuide.levelUpMessage(to: toLevel)
                    )
                } else if ratio <= Adaptation.levelDownAccuracy, progress.recommendedLevel > TrailGuide.minimumLevel {
                    let fromLevel = progress.recommendedLevel
                    let toLevel = fromLevel - 1
                    progress.recommendedLevel = toLevel
                    rolling = []
                    levelChange = LevelChange(
                        fromLevel: fromLevel,
                        toLevel: toLevel,
                        message: TrailGuide.levelDownMessage(to: toLevel)
                    )
                }
            }
        }
        progress.rollingCorrect = rolling
        refreshUnlocks(catalog: catalog, progress: &progress)

        let after = Badges.all(progress: progress, catalog: catalog)
        let freshBadges = after.filter { $0.earned && !beforeBadges.contains($0.id) }
        return AttemptOutcome(
            passageId: passage.id,
            correct: correct,
            total: total,
            stars: stars,
            previousBestStars: previousBest,
            newBadges: freshBadges,
            levelChange: levelChange,
            recommendedLevel: progress.recommendedLevel
        )
    }

    public static func refreshUnlocks(catalog: Catalog, progress: inout ReadingProgress) {
        if progress.recommendedLevel > progress.highestUnlockedLevel {
            progress.highestUnlockedLevel = progress.recommendedLevel
        }
        if completedCount(level: 1, catalog: catalog, progress: progress) >= Adaptation.completionsToOpenNextTrail {
            progress.highestUnlockedLevel = max(progress.highestUnlockedLevel, 2)
        }
        if completedCount(level: 2, catalog: catalog, progress: progress) >= Adaptation.completionsToOpenNextTrail {
            progress.highestUnlockedLevel = max(progress.highestUnlockedLevel, 3)
        }
        if progress.highestUnlockedLevel > TrailGuide.maximumLevel {
            progress.highestUnlockedLevel = TrailGuide.maximumLevel
        }
    }

    public static func isoString(from date: Date) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter.string(from: date)
    }
}
