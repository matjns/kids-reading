import Foundation

public struct AnswerFeedback: Equatable {
    public var correct: Bool
    public var headline: String
    public var explanation: String
    public var lookBackSentenceIds: [String]
    public var correctChoiceId: String

    public init(
        correct: Bool,
        headline: String,
        explanation: String,
        lookBackSentenceIds: [String],
        correctChoiceId: String
    ) {
        self.correct = correct
        self.headline = headline
        self.explanation = explanation
        self.lookBackSentenceIds = lookBackSentenceIds
        self.correctChoiceId = correctChoiceId
    }
}

public enum Scoring {
    public static let correctHeadline = "Yes! You found it."
    public static let missHeadline = "Not quite. Let's look back in the story."

    /// Stars for a finished passage. Finishing always earns at least one star.
    /// Every question correct earns three. About 60 percent or more earns two.
    public static func stars(correct: Int, total: Int) -> Int {
        guard total > 0, correct >= 0 else { return 0 }
        let capped = min(correct, total)
        if capped == total { return 3 }
        let ratio = Double(capped) / Double(total)
        if ratio >= 0.6 { return 2 }
        return 1
    }

    public static func feedback(question: Question, selectedChoiceId: String) -> AnswerFeedback {
        let correct = selectedChoiceId == question.answerId
        return AnswerFeedback(
            correct: correct,
            headline: correct ? correctHeadline : missHeadline,
            explanation: question.explanation,
            lookBackSentenceIds: correct ? [] : question.lookBackSentenceIds,
            correctChoiceId: question.answerId
        )
    }
}
