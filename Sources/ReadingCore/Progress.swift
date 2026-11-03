import Foundation

public struct PassageStat: Codable, Equatable {
    public var attempts: Int
    public var bestStars: Int
    public var lastCorrect: Int
    public var lastTotal: Int

    public init(attempts: Int, bestStars: Int, lastCorrect: Int, lastTotal: Int) {
        self.attempts = attempts
        self.bestStars = bestStars
        self.lastCorrect = lastCorrect
        self.lastTotal = lastTotal
    }
}

public struct AttemptRecord: Codable, Equatable, Identifiable {
    public var id: String
    public var passageId: String
    public var correct: Int
    public var total: Int
    public var stars: Int
    public var level: Int
    public var answeredAt: String

    public init(
        id: String,
        passageId: String,
        correct: Int,
        total: Int,
        stars: Int,
        level: Int,
        answeredAt: String
    ) {
        self.id = id
        self.passageId = passageId
        self.correct = correct
        self.total = total
        self.stars = stars
        self.level = level
        self.answeredAt = answeredAt
    }
}

public struct LevelChange: Equatable {
    public var fromLevel: Int
    public var toLevel: Int
    public var message: String

    public init(fromLevel: Int, toLevel: Int, message: String) {
        self.fromLevel = fromLevel
        self.toLevel = toLevel
        self.message = message
    }
}

public struct AttemptOutcome: Equatable {
    public var passageId: String
    public var correct: Int
    public var total: Int
    public var stars: Int
    public var previousBestStars: Int
    public var newBadges: [BadgeStatus]
    public var levelChange: LevelChange?
    public var recommendedLevel: Int

    public init(
        passageId: String,
        correct: Int,
        total: Int,
        stars: Int,
        previousBestStars: Int,
        newBadges: [BadgeStatus],
        levelChange: LevelChange?,
        recommendedLevel: Int
    ) {
        self.passageId = passageId
        self.correct = correct
        self.total = total
        self.stars = stars
        self.previousBestStars = previousBestStars
        self.newBadges = newBadges
        self.levelChange = levelChange
        self.recommendedLevel = recommendedLevel
    }
}

public struct Progress: Codable, Equatable {
    public var playerName: String
    public var biggerText: Bool
    public var recommendedLevel: Int
    public var highestUnlockedLevel: Int
    public var rollingCorrect: [Bool]
    public var passageStats: [String: PassageStat]
    public var correctKeys: [String]
    public var attempts: [AttemptRecord]

    public init(
        playerName: String = "",
        biggerText: Bool = false,
        recommendedLevel: Int = 1,
        highestUnlockedLevel: Int = 1,
        rollingCorrect: [Bool] = [],
        passageStats: [String: PassageStat] = [:],
        correctKeys: [String] = [],
        attempts: [AttemptRecord] = []
    ) {
        self.playerName = playerName
        self.biggerText = biggerText
        self.recommendedLevel = recommendedLevel
        self.highestUnlockedLevel = highestUnlockedLevel
        self.rollingCorrect = rollingCorrect
        self.passageStats = passageStats
        self.correctKeys = correctKeys
        self.attempts = attempts
    }

    public static let empty = Progress()

    public var totalStars: Int {
        passageStats.values.reduce(0) { $0 + $1.bestStars }
    }

    public var passagesFinished: Int {
        passageStats.values.filter { $0.attempts > 0 }.count
    }

    public var questionsCorrect: Int {
        correctKeys.count
    }

    public var questionsAnswered: Int {
        attempts.reduce(0) { $0 + $1.total }
    }

    enum CodingKeys: String, CodingKey {
        case playerName
        case biggerText
        case recommendedLevel
        case highestUnlockedLevel
        case rollingCorrect
        case passageStats
        case correctKeys
        case attempts
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        playerName = try container.decodeIfPresent(String.self, forKey: .playerName) ?? ""
        biggerText = try container.decodeIfPresent(Bool.self, forKey: .biggerText) ?? false
        recommendedLevel = try container.decodeIfPresent(Int.self, forKey: .recommendedLevel) ?? 1
        highestUnlockedLevel = try container.decodeIfPresent(Int.self, forKey: .highestUnlockedLevel) ?? 1
        rollingCorrect = try container.decodeIfPresent([Bool].self, forKey: .rollingCorrect) ?? []
        passageStats = try container.decodeIfPresent([String: PassageStat].self, forKey: .passageStats) ?? [:]
        correctKeys = try container.decodeIfPresent([String].self, forKey: .correctKeys) ?? []
        attempts = try container.decodeIfPresent([AttemptRecord].self, forKey: .attempts) ?? []
        playerName = NameRules.sanitize(playerName)
        if recommendedLevel < TrailGuide.minimumLevel { recommendedLevel = TrailGuide.minimumLevel }
        if recommendedLevel > TrailGuide.maximumLevel { recommendedLevel = TrailGuide.maximumLevel }
        if highestUnlockedLevel < recommendedLevel { highestUnlockedLevel = recommendedLevel }
        if highestUnlockedLevel > TrailGuide.maximumLevel { highestUnlockedLevel = TrailGuide.maximumLevel }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(playerName, forKey: .playerName)
        try container.encode(biggerText, forKey: .biggerText)
        try container.encode(recommendedLevel, forKey: .recommendedLevel)
        try container.encode(highestUnlockedLevel, forKey: .highestUnlockedLevel)
        try container.encode(rollingCorrect, forKey: .rollingCorrect)
        try container.encode(passageStats, forKey: .passageStats)
        try container.encode(correctKeys, forKey: .correctKeys)
        try container.encode(attempts, forKey: .attempts)
    }
}

public enum NameRules {
    public static let maximumLength = 24

    public static func sanitize(_ raw: String) -> String {
        let noBreaks = raw.replacingOccurrences(of: "\n", with: " ")
            .replacingOccurrences(of: "\r", with: " ")
        let trimmed = noBreaks.trimmingCharacters(in: .whitespacesAndNewlines)
        let collapsed = trimmed.split(whereSeparator: { $0.isWhitespace }).joined(separator: " ")
        return String(collapsed.prefix(maximumLength))
    }
}

public enum Adaptation {
    public static let windowSize = 8
    public static let minimumAnswers = 6
    public static let levelUpAccuracy = 0.80
    public static let levelDownAccuracy = 0.40
    public static let completionsToOpenNextTrail = 4
    public static let attemptHistoryLimit = 200
}

public struct ProgressStore {
    public let directory: URL
    public let fileURL: URL

    public init(directory: URL) {
        self.directory = directory
        self.fileURL = directory.appendingPathComponent("progress.json")
    }

    public static func defaultDirectory() -> URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? URL(fileURLWithPath: NSHomeDirectory(), isDirectory: true)
            .appendingPathComponent("Library", isDirectory: true)
            .appendingPathComponent("Application Support", isDirectory: true)
        return base.appendingPathComponent("Reading Quest", isDirectory: true)
    }

    public func load() -> Progress {
        guard let data = try? Data(contentsOf: fileURL) else {
            return .empty
        }
        do {
            return try JSONDecoder().decode(Progress.self, from: data)
        } catch {
            let backup = directory.appendingPathComponent("progress.unreadable.json")
            try? FileManager.default.removeItem(at: backup)
            try? FileManager.default.moveItem(at: fileURL, to: backup)
            return .empty
        }
    }

    public func save(_ progress: Progress) throws {
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(progress)
        try data.write(to: fileURL, options: .atomic)
    }

    public func erase() throws {
        if FileManager.default.fileExists(atPath: fileURL.path) {
            try FileManager.default.removeItem(at: fileURL)
        }
    }
}
