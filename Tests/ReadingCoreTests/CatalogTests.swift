import XCTest
@testable import ReadingCore

final class CatalogTests: XCTestCase {
    func testShippedCatalogIsLargeBalancedAndKind() throws {
        let catalog = try CatalogLoader.loadBundled()
        XCTAssertGreaterThanOrEqual(catalog.passages.count, 40)
        for level in 1...3 {
            let peers = catalog.passages(at: level)
            XCTAssertGreaterThanOrEqual(peers.count, 10, "level \(level)")
            let kinds = Set(peers.map(\.kind))
            XCTAssertEqual(kinds, Set(PassageKind.allCases), "level \(level) should include every kind")
            var skillCounts: [QuestionSkill: Int] = [:]
            for passage in peers {
                XCTAssertTrue((3...5).contains(passage.questions.count))
                XCTAssertTrue(passage.questions.contains { $0.skill == .mainIdea })
                for question in passage.questions {
                    skillCounts[question.skill, default: 0] += 1
                }
            }
            for skill in QuestionSkill.allCases {
                XCTAssertGreaterThanOrEqual(skillCounts[skill] ?? 0, 3, "\(skill) on level \(level)")
            }
        }

        let all = catalog.passages
        XCTAssertGreaterThanOrEqual(all.filter { $0.kind == .fable }.count, 8)
        XCTAssertGreaterThanOrEqual(all.filter { $0.kind == .nonfiction }.count, 10)
        XCTAssertGreaterThanOrEqual(all.filter { $0.kind == .fiction }.count, 8)
        XCTAssertGreaterThanOrEqual(all.filter { $0.kind == .poem }.count, 4)

        var positionCounts = [Int](repeating: 0, count: 4)
        var longestCorrect = 0
        var questionTotal = 0
        for passage in all {
            for question in passage.questions {
                questionTotal += 1
                let index = question.choices.firstIndex { $0.id == question.answerId } ?? 0
                if index < positionCounts.count {
                    positionCounts[index] += 1
                }
                let correctLength = question.choices.first { $0.id == question.answerId }?.text.count ?? 0
                let otherMax = question.choices.filter { $0.id != question.answerId }.map(\.text.count).max() ?? 0
                if correctLength > otherMax { longestCorrect += 1 }
                let lowered = question.explanation.lowercased()
                for banned in ["stupid", "dumb", "idiot", "moron", "hate", "shut up", "wrong", "kill", "dead", "blood"] {
                    XCTAssertFalse(lowered.contains(banned), "\(passage.id) \(question.id) explanation contains \(banned)")
                }
            }
        }
        let busiest = positionCounts.max() ?? 0
        XCTAssertLessThan(Double(busiest) / Double(questionTotal), 0.45)
        XCTAssertLessThan(Double(longestCorrect) / Double(questionTotal), 0.70)
    }

    func testShippedTextHasNoLinksSecretsOrChildNames() throws {
        let catalog = try CatalogLoader.loadBundled()
        let blob = catalog.passages.map { passage in
            (
                [passage.id, passage.title, passage.attribution ?? ""]
                + passage.sentences.map(\.text)
                + passage.questions.flatMap { question in
                    [question.prompt, question.explanation] + question.choices.map(\.text)
                }
            ).joined(separator: "\n")
        }.joined(separator: "\n")
        let lowered = blob.lowercased()
        XCTAssertFalse(lowered.contains("http"))
        XCTAssertFalse(lowered.contains("www."))
        XCTAssertFalse(blob.contains("@"))
        for banned in ["stupid", "idiot", "moron", "kill", "killed", "dead", "blood", "gun", "weapon"] {
            XCTAssertFalse(lowered.contains(banned), banned)
        }
        let words = Set(lowered.split { !$0.isLetter }.map(String.init))
        let names = [
            "emma", "liam", "olivia", "noah", "oliver", "ava", "sophia", "sofia", "isabella", "mia",
            "charlotte", "amelia", "harper", "evelyn", "abigail", "emily", "ella", "elizabeth",
            "chloe", "camila", "penelope", "layla", "riley", "zoey", "nora", "hannah", "lillian",
            "addison", "aubrey", "ellie", "natalie", "leah", "aurora", "savannah", "audrey",
            "brooklyn", "bella", "claire", "skylar", "paisley", "everly", "caroline", "genesis",
            "emilia", "kennedy", "samantha", "maya", "kinsley", "naomi", "aaliyah", "elena",
            "ariana", "allison", "gabriella", "madelyn", "cora", "serenity", "autumn", "adeline",
            "hailey", "gianna", "valentina", "isla", "eliana", "quinn", "piper", "lydia", "alexa",
            "josephine", "emerson", "elijah", "william", "henry", "lucas", "benjamin", "theodore",
            "levi", "alexander", "jackson", "mateo", "daniel", "michael", "sebastian", "ethan",
            "logan", "owen", "samuel", "jacob", "asher", "aiden", "joseph", "wyatt", "david",
            "julian", "hudson", "grayson", "matthew", "ezra", "gabriel", "carter", "isaac",
            "jayden", "luca", "anthony", "dylan", "lincoln", "thomas", "maverick", "elias",
            "josiah", "charles", "caleb", "christopher", "ezekiel", "jaxon", "isaiah", "andrew",
            "joshua", "nathan", "nolan", "adrian", "cameron", "santiago", "aaron", "ryan",
            "cooper", "waylon", "roman", "jordan", "colton", "jose", "axel", "easton", "greyson",
            "james", "luke", "leo", "jack", "mason"
        ]
        for name in names where words.contains(name) {
            XCTFail("Found a child-style name in the stories: \(name)")
        }
    }

    func testInvalidStoryFileIsNamedInTheError() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("reading-quest-bad-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        try "{".data(using: .utf8)?.write(to: directory.appendingPathComponent("broken.json"))
        do {
            _ = try CatalogLoader.load(directory: directory)
            XCTFail("Expected a catalog problem")
        } catch let problem as CatalogProblem {
            XCTAssertTrue(problem.description.contains("broken.json"))
        }
    }
}
