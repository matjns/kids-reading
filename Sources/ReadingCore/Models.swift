import Foundation

public enum PassageKind: String, Codable, Equatable, CaseIterable {
    case fiction
    case nonfiction
    case fable
    case poem

    public var kidLabel: String {
        switch self {
        case .fiction:
            return "Made-up story"
        case .nonfiction:
            return "Real facts"
        case .fable:
            return "Fable"
        case .poem:
            return "Poem"
        }
    }
}

public enum QuestionSkill: String, Codable, Equatable, CaseIterable {
    case mainIdea
    case detail
    case vocabulary
    case inference
    case sequence

    public var kidLabel: String {
        switch self {
        case .mainIdea:
            return "Main idea"
        case .detail:
            return "Find a detail"
        case .vocabulary:
            return "Word meaning"
        case .inference:
            return "Figure it out"
        case .sequence:
            return "Order of events"
        }
    }
}

public struct Sentence: Codable, Equatable, Identifiable {
    public var id: String
    public var text: String

    public init(id: String, text: String) {
        self.id = id
        self.text = text
    }
}

public struct Choice: Codable, Equatable, Identifiable {
    public var id: String
    public var text: String

    public init(id: String, text: String) {
        self.id = id
        self.text = text
    }
}

public struct Question: Codable, Equatable, Identifiable {
    public var id: String
    public var skill: QuestionSkill
    public var prompt: String
    public var choices: [Choice]
    public var answerId: String
    public var explanation: String
    public var lookBackSentenceIds: [String]

    public init(
        id: String,
        skill: QuestionSkill,
        prompt: String,
        choices: [Choice],
        answerId: String,
        explanation: String,
        lookBackSentenceIds: [String]
    ) {
        self.id = id
        self.skill = skill
        self.prompt = prompt
        self.choices = choices
        self.answerId = answerId
        self.explanation = explanation
        self.lookBackSentenceIds = lookBackSentenceIds
    }
}

public struct Passage: Codable, Equatable, Identifiable {
    public var id: String
    public var title: String
    public var kind: PassageKind
    public var level: Int
    public var order: Int
    public var attribution: String?
    public var sentences: [Sentence]
    public var questions: [Question]

    public init(
        id: String,
        title: String,
        kind: PassageKind,
        level: Int,
        order: Int,
        attribution: String? = nil,
        sentences: [Sentence],
        questions: [Question]
    ) {
        self.id = id
        self.title = title
        self.kind = kind
        self.level = level
        self.order = order
        self.attribution = attribution
        self.sentences = sentences
        self.questions = questions
    }

    public var wordCount: Int {
        sentences.reduce(0) { total, sentence in
            total + sentence.text.split { $0.isWhitespace || $0.isNewline }.count
        }
    }

    /// Text used for read-aloud. Poems keep line breaks. Other kinds flow as sentences.
    public var spokenText: String {
        let separator = kind == .poem ? "\n" : " "
        return sentences.map(\.text).joined(separator: separator)
    }
}

public struct Catalog: Equatable {
    public let passages: [Passage]

    public init(passages: [Passage]) {
        self.passages = passages.sorted { lhs, rhs in
            if lhs.level != rhs.level { return lhs.level < rhs.level }
            if lhs.order != rhs.order { return lhs.order < rhs.order }
            return lhs.id < rhs.id
        }
    }

    public func passage(id: String) -> Passage? {
        passages.first { $0.id == id }
    }

    public func passages(at level: Int) -> [Passage] {
        passages.filter { $0.level == level }
    }
}

public enum TrailGuide {
    public static let minimumLevel = 1
    public static let maximumLevel = 3

    public static func name(for level: Int) -> String {
        switch level {
        case 2:
            return "Whispering Woods"
        case 3:
            return "Starlight Peaks"
        default:
            return "Meadow Trail"
        }
    }

    public static func blurb(for level: Int) -> String {
        switch level {
        case 2:
            return "Longer tales and trickier clues."
        case 3:
            return "The fullest passages and the deepest questions."
        default:
            return "Shorter stories and a gentle start."
        }
    }

    public static func levelUpMessage(to level: Int) -> String {
        "You are reading so clearly that a new trail is open. Next stop: \(name(for: level))."
    }

    public static func levelDownMessage(to level: Int) -> String {
        "This trail is a little steep, and that is okay. Let's walk \(name(for: level)) for a bit and build your reading strength back up."
    }
}
