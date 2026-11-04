import Foundation

public struct BadgeStatus: Equatable, Identifiable {
    public var id: String
    public var title: String
    public var howToEarn: String
    public var earned: Bool

    public init(id: String, title: String, howToEarn: String, earned: Bool) {
        self.id = id
        self.title = title
        self.howToEarn = howToEarn
        self.earned = earned
    }
}

public enum Badges {
    public static let wordFinderGoal = 8
    public static let clueFinderGoal = 8
    public static let fableGoal = 5
    public static let factGoal = 5
    public static let poemGoal = 3
    public static let starGathererGoal = 20
    public static let starBrightGoal = 40
    public static let perfectGoal = 3

    public static func all(progress: ReadingProgress, catalog: Catalog) -> [BadgeStatus] {
        let finished = finishedIds(progress: progress, catalog: catalog)
        let finishedPassages = catalog.passages.filter { finished.contains($0.id) }
        let stars = progress.totalStars
        let perfectCount = finishedPassages.filter { (progress.passageStats[$0.id]?.bestStars ?? 0) >= 3 }.count
        let vocab = correctCount(skill: .vocabulary, progress: progress, catalog: catalog)
        let inference = correctCount(skill: .inference, progress: progress, catalog: catalog)

        let specs: [(String, String, String, Bool)] = [
            ("first-story", "First Story", "Finish 1 story.", finished.count >= 1),
            ("five-stories", "Trail Snacks", "Finish 5 stories.", finished.count >= 5),
            ("ten-stories", "Page Turner", "Finish 10 stories.", finished.count >= 10),
            ("twenty-stories", "Quest Walker", "Finish 20 stories.", finished.count >= 20),
            ("perfect-page", "Perfect Page", "Earn 3 stars on a story.", perfectCount >= 1),
            ("three-perfect", "Careful Reader", "Earn 3 stars on 3 different stories.", perfectCount >= perfectGoal),
            ("star-gatherer", "Star Gatherer", "Collect 20 stars.", stars >= starGathererGoal),
            ("star-bright", "Star Bright", "Collect 40 stars.", stars >= starBrightGoal),
            ("meadow-walker", "Meadow Walker", "Finish every Meadow Trail story.", trailComplete(1, progress: progress, catalog: catalog)),
            ("woods-walker", "Woods Walker", "Finish every Whispering Woods story.", trailComplete(2, progress: progress, catalog: catalog)),
            ("peak-walker", "Peak Walker", "Finish every Starlight Peaks story.", trailComplete(3, progress: progress, catalog: catalog)),
            ("new-heights", "New Heights", "Open the Starlight Peaks trail.", progress.highestUnlockedLevel >= 3),
            ("word-finder", "Word Finder", "Answer 8 word-meaning questions correctly.", vocab >= wordFinderGoal),
            ("clue-finder", "Clue Finder", "Answer 8 figure-it-out questions correctly.", inference >= clueFinderGoal),
            ("fable-fan", "Fable Fan", "Finish 5 fables.", finishedPassages.filter { $0.kind == .fable }.count >= fableGoal),
            ("fact-finder", "Fact Finder", "Finish 5 real-facts passages.", finishedPassages.filter { $0.kind == .nonfiction }.count >= factGoal),
            ("poet", "Poet's Friend", "Finish 3 poems.", finishedPassages.filter { $0.kind == .poem }.count >= poemGoal)
        ]

        return specs.map { BadgeStatus(id: $0.0, title: $0.1, howToEarn: $0.2, earned: $0.3) }
    }

    public static func finishedIds(progress: ReadingProgress, catalog: Catalog) -> Set<String> {
        Set(catalog.passages.compactMap { passage in
            (progress.passageStats[passage.id]?.attempts ?? 0) > 0 ? passage.id : nil
        })
    }

    public static func correctCount(skill: QuestionSkill, progress: ReadingProgress, catalog: Catalog) -> Int {
        let keys = Set(progress.correctKeys)
        var count = 0
        for passage in catalog.passages {
            for question in passage.questions where question.skill == skill {
                if keys.contains(correctKey(passageId: passage.id, questionId: question.id)) {
                    count += 1
                }
            }
        }
        return count
    }

    public static func correctKey(passageId: String, questionId: String) -> String {
        "\(passageId)|\(questionId)"
    }

    private static func trailComplete(_ level: Int, progress: ReadingProgress, catalog: Catalog) -> Bool {
        let peers = catalog.passages(at: level)
        guard !peers.isEmpty else { return false }
        return peers.allSatisfy { (progress.passageStats[$0.id]?.attempts ?? 0) > 0 }
    }
}
