import XCTest
@testable import ReadingCore

final class EngineTests: XCTestCase {
    func testStars() {
        XCTAssertEqual(Scoring.stars(correct: 3, total: 3), 3)
        XCTAssertEqual(Scoring.stars(correct: 4, total: 4), 3)
        XCTAssertEqual(Scoring.stars(correct: 5, total: 5), 3)
        XCTAssertEqual(Scoring.stars(correct: 2, total: 3), 2)
        XCTAssertEqual(Scoring.stars(correct: 3, total: 4), 2)
        XCTAssertEqual(Scoring.stars(correct: 3, total: 5), 2)
        XCTAssertEqual(Scoring.stars(correct: 4, total: 5), 2)
        XCTAssertEqual(Scoring.stars(correct: 1, total: 3), 1)
        XCTAssertEqual(Scoring.stars(correct: 0, total: 4), 1)
        XCTAssertEqual(Scoring.stars(correct: 2, total: 4), 1)
        XCTAssertEqual(Scoring.stars(correct: 2, total: 5), 1)
        XCTAssertEqual(Scoring.stars(correct: 0, total: 0), 0)
    }

    func testMissHighlightsAndCorrectDoesNot() {
        let question = sampleQuestion()
        let miss = Scoring.feedback(question: question, selectedChoiceId: "a")
        XCTAssertFalse(miss.correct)
        XCTAssertEqual(miss.headline, Scoring.missHeadline)
        XCTAssertTrue(miss.headline.lowercased().contains("look back"))
        XCTAssertEqual(miss.lookBackSentenceIds, ["s2"])
        XCTAssertEqual(miss.correctChoiceId, "b")
        XCTAssertEqual(miss.explanation, question.explanation)

        let hit = Scoring.feedback(question: question, selectedChoiceId: "b")
        XCTAssertTrue(hit.correct)
        XCTAssertEqual(hit.headline, Scoring.correctHeadline)
        XCTAssertTrue(hit.lookBackSentenceIds.isEmpty)
    }

    func testNameStaysBlankAndHasNoInventedDefault() {
        XCTAssertEqual(ReadingProgress.empty.playerName, "")
        XCTAssertEqual(NameRules.sanitize("   "), "")
        XCTAssertEqual(NameRules.sanitize("\n\n"), "")
        XCTAssertEqual(NameRules.sanitize("  River   Guide  "), "River Guide")
        let long = String(repeating: "a", count: 40)
        XCTAssertEqual(NameRules.sanitize(long).count, NameRules.maximumLength)
        XCTAssertNotEqual(NameRules.sanitize(""), "Reader")
    }

    func testLevelUpAfterStrongAnswersAndDoesNotPassThree() {
        let catalog = Catalog(passages: [
            samplePassage(id: "one", level: 1, order: 1, questionCount: 3),
            samplePassage(id: "two", level: 1, order: 2, questionCount: 3),
            samplePassage(id: "peak", level: 3, order: 1, questionCount: 3)
        ])
        var progress = ReadingProgress()
        let first = QuestRules.record(
            passageId: "one",
            answers: correctAnswers(catalog.passage(id: "one")!),
            catalog: catalog,
            progress: &progress,
            now: Date(timeIntervalSince1970: 1_700_000_000),
            identifier: "attempt-1"
        )
        XCTAssertEqual(first?.stars, 3)
        XCTAssertNil(first?.levelChange)
        XCTAssertEqual(progress.recommendedLevel, 1)

        let second = QuestRules.record(
            passageId: "two",
            answers: correctAnswers(catalog.passage(id: "two")!),
            catalog: catalog,
            progress: &progress,
            identifier: "attempt-2"
        )
        XCTAssertEqual(second?.levelChange?.fromLevel, 1)
        XCTAssertEqual(second?.levelChange?.toLevel, 2)
        XCTAssertEqual(progress.recommendedLevel, 2)
        XCTAssertEqual(progress.highestUnlockedLevel, 2)
        XCTAssertTrue(second?.levelChange?.message.contains("Whispering Woods") ?? false)
        XCTAssertTrue(progress.rollingCorrect.isEmpty)

        progress.recommendedLevel = 3
        progress.highestUnlockedLevel = 3
        progress.rollingCorrect = []
        let third = QuestRules.record(
            passageId: "peak",
            answers: correctAnswers(catalog.passage(id: "peak")!),
            catalog: catalog,
            progress: &progress,
            identifier: "attempt-3"
        )
        XCTAssertEqual(progress.recommendedLevel, 3)
        XCTAssertNil(third?.levelChange)
    }

    func testLevelDownIsGentleAndOffTrailAnswersDoNotMoveTheLevel() {
        let catalog = Catalog(passages: [
            samplePassage(id: "meadow", level: 1, order: 1, questionCount: 3),
            samplePassage(id: "woods", level: 2, order: 1, questionCount: 3),
            samplePassage(id: "woods-2", level: 2, order: 2, questionCount: 3)
        ])
        var progress = ReadingProgress(recommendedLevel: 2, highestUnlockedLevel: 2)
        _ = QuestRules.record(
            passageId: "meadow",
            answers: [:],
            catalog: catalog,
            progress: &progress,
            identifier: "off-trail"
        )
        XCTAssertEqual(progress.recommendedLevel, 2)
        XCTAssertTrue(progress.rollingCorrect.isEmpty)

        let first = QuestRules.record(
            passageId: "woods",
            answers: [:],
            catalog: catalog,
            progress: &progress,
            identifier: "miss-1"
        )
        XCTAssertEqual(first?.stars, 1)
        XCTAssertNil(first?.levelChange)
        XCTAssertEqual(progress.rollingCorrect.count, 3)

        let second = QuestRules.record(
            passageId: "woods-2",
            answers: [:],
            catalog: catalog,
            progress: &progress,
            identifier: "miss-2"
        )
        XCTAssertEqual(second?.levelChange?.toLevel, 1)
        XCTAssertEqual(progress.recommendedLevel, 1)
        XCTAssertEqual(progress.highestUnlockedLevel, 2)
        XCTAssertTrue(second?.levelChange?.message.contains("Meadow Trail") ?? false)
        XCTAssertFalse(second?.levelChange?.message.lowercased().contains("wrong") ?? true)
    }

    func testBestStarsNeverDropAndCorrectKeysDoNotDouble() {
        let catalog = Catalog(passages: [samplePassage(id: "one", level: 1, order: 1, questionCount: 3)])
        var progress = ReadingProgress()
        let passage = catalog.passage(id: "one")!
        _ = QuestRules.record(
            passageId: "one",
            answers: correctAnswers(passage),
            catalog: catalog,
            progress: &progress,
            identifier: "best"
        )
        XCTAssertEqual(progress.passageStats["one"]?.bestStars, 3)
        XCTAssertEqual(progress.correctKeys.count, 3)
        _ = QuestRules.record(
            passageId: "one",
            answers: [:],
            catalog: catalog,
            progress: &progress,
            identifier: "retry"
        )
        XCTAssertEqual(progress.passageStats["one"]?.bestStars, 3)
        XCTAssertEqual(progress.passageStats["one"]?.attempts, 2)
        XCTAssertEqual(progress.passageStats["one"]?.lastCorrect, 0)
        XCTAssertEqual(progress.correctKeys.count, 3)
    }

    func testUnlockOrderAndTrailGates() {
        let meadow = (1...4).map { samplePassage(id: "m\($0)", level: 1, order: $0, questionCount: 3) }
        let catalog = Catalog(passages: meadow + [
            samplePassage(id: "w1", level: 2, order: 1, questionCount: 3),
            samplePassage(id: "p1", level: 3, order: 1, questionCount: 3)
        ])
        var progress = ReadingProgress()
        XCTAssertTrue(QuestRules.isPassageUnlocked(catalog.passage(id: "m1")!, catalog: catalog, progress: progress))
        XCTAssertFalse(QuestRules.isPassageUnlocked(catalog.passage(id: "m2")!, catalog: catalog, progress: progress))
        XCTAssertFalse(QuestRules.isTrailUnlocked(2, progress: progress))

        for passage in meadow {
            _ = QuestRules.record(
                passageId: passage.id,
                answers: [:],
                catalog: catalog,
                progress: &progress,
                identifier: passage.id
            )
        }
        XCTAssertTrue(QuestRules.isTrailUnlocked(2, progress: progress))
        XCTAssertTrue(QuestRules.isPassageUnlocked(catalog.passage(id: "w1")!, catalog: catalog, progress: progress))
        XCTAssertFalse(QuestRules.isTrailUnlocked(3, progress: progress))
        XCTAssertEqual(progress.recommendedLevel, 1)
        XCTAssertEqual(QuestRules.recommendedPassage(catalog: catalog, progress: progress)?.level, 1)
    }

    func testBadgesAppearOnce() {
        let passages = (1...5).map { samplePassage(id: "p\($0)", level: 1, order: $0, questionCount: 3, kind: .fable) }
        let catalog = Catalog(passages: passages)
        var progress = ReadingProgress()
        var earned: [String] = []
        for passage in passages {
            let outcome = QuestRules.record(
                passageId: passage.id,
                answers: correctAnswers(passage),
                catalog: catalog,
                progress: &progress,
                identifier: passage.id
            )
            earned.append(contentsOf: outcome?.newBadges.map(\.id) ?? [])
        }
        XCTAssertEqual(earned.filter { $0 == "first-story" }.count, 1)
        XCTAssertEqual(earned.filter { $0 == "five-stories" }.count, 1)
        XCTAssertTrue(earned.contains("perfect-page"))
        XCTAssertTrue(earned.contains("fable-fan"))
        XCTAssertFalse(Badges.all(progress: progress, catalog: catalog).first { $0.id == "word-finder" }?.earned ?? true)
        XCTAssertTrue(Badges.all(progress: progress, catalog: catalog).first { $0.id == "meadow-walker" }?.earned ?? false)
        let again = QuestRules.record(
            passageId: "p1",
            answers: correctAnswers(catalog.passage(id: "p1")!),
            catalog: catalog,
            progress: &progress,
            identifier: "repeat"
        )
        XCTAssertTrue(again?.newBadges.isEmpty ?? false)
    }

    func testStoreRoundTripAndUnreadableFile() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("reading-quest-tests-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let store = ProgressStore(directory: directory)
        var progress = ReadingProgress(playerName: "Trail Guide", biggerText: true, recommendedLevel: 2, highestUnlockedLevel: 2)
        progress.rollingCorrect = [true, false, true]
        progress.passageStats["fox-and-the-grapes"] = PassageStat(attempts: 1, bestStars: 2, lastCorrect: 2, lastTotal: 3)
        try store.save(progress)
        let loaded = store.load()
        XCTAssertEqual(loaded.playerName, "Trail Guide")
        XCTAssertEqual(loaded.biggerText, true)
        XCTAssertEqual(loaded.recommendedLevel, 2)
        XCTAssertEqual(loaded.passageStats["fox-and-the-grapes"]?.bestStars, 2)
        XCTAssertEqual(loaded.rollingCorrect, [true, false, true])

        try "not json".data(using: .utf8)?.write(to: store.fileURL)
        let recovered = store.load()
        XCTAssertEqual(recovered, .empty)
        XCTAssertTrue(FileManager.default.fileExists(atPath: directory.appendingPathComponent("progress.unreadable.json").path))
        XCTAssertTrue(ProgressStore.defaultDirectory().lastPathComponent == "Reading Quest")
    }

    func testRecommendedRetryPicksFewerStars() {
        let catalog = Catalog(passages: [
            samplePassage(id: "m1", level: 1, order: 1, questionCount: 4),
            samplePassage(id: "m2", level: 1, order: 2, questionCount: 4)
        ])
        var progress = ReadingProgress()
        _ = QuestRules.record(
            passageId: "m1",
            answers: correctAnswers(catalog.passage(id: "m1")!),
            catalog: catalog,
            progress: &progress,
            identifier: "full"
        )
        _ = QuestRules.record(
            passageId: "m2",
            answers: ["q1": "b"],
            catalog: catalog,
            progress: &progress,
            identifier: "partial"
        )
        XCTAssertEqual(QuestRules.recommendedPassage(catalog: catalog, progress: progress)?.id, "m2")
    }

    private func sampleQuestion() -> Question {
        Question(
            id: "q1",
            skill: .mainIdea,
            prompt: "What is this story mostly about?",
            choices: [
                Choice(id: "a", text: "A small detail"),
                Choice(id: "b", text: "The big idea"),
                Choice(id: "c", text: "A different story")
            ],
            answerId: "b",
            explanation: "The whole story points to the big idea, not just one small moment.",
            lookBackSentenceIds: ["s2"]
        )
    }

    private func samplePassage(
        id: String,
        level: Int,
        order: Int,
        questionCount: Int,
        kind: PassageKind = .fiction
    ) -> Passage {
        let skills: [QuestionSkill] = [.mainIdea, .detail, .vocabulary, .inference, .sequence]
        let questions = (0..<questionCount).map { index in
            Question(
                id: "q\(index + 1)",
                skill: skills[index],
                prompt: "Question \(index + 1) about the story?",
                choices: [
                    Choice(id: "a", text: "First choice"),
                    Choice(id: "b", text: "Second choice"),
                    Choice(id: "c", text: "Third choice")
                ],
                answerId: "b",
                explanation: "The story supports the second choice, and the other choices do not fit.",
                lookBackSentenceIds: ["s1"]
            )
        }
        return Passage(
            id: id,
            title: "Title \(id)",
            kind: kind,
            level: level,
            order: order,
            attribution: kind == .fable ? "A retelling of a public-domain fable by Aesop." : nil,
            sentences: [
                Sentence(id: "s1", text: "The sample story has a beginning."),
                Sentence(id: "s2", text: "It also has a middle."),
                Sentence(id: "s3", text: "It ends with a clear last moment.")
            ],
            questions: questions
        )
    }

    private func correctAnswers(_ passage: Passage) -> [String: String] {
        Dictionary(uniqueKeysWithValues: passage.questions.map { ($0.id, $0.answerId) })
    }
}
