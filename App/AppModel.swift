import SwiftUI

enum AppRoute: Equatable {
    case welcome
    case map
    case story
    case complete
    case progress
}

enum StoryPhase: Equatable {
    case reading
    case asking
}

@MainActor
final class AppModel: ObservableObject {
    @Published var catalog: Catalog?
    @Published var loadError: String?
    @Published var progress: ReadingProgress
    @Published var route: AppRoute = .welcome
    @Published var draftName: String
    @Published var mapLevel: Int
    @Published var passageId: String?
    @Published var phase: StoryPhase = .reading
    @Published var questionIndex = 0
    @Published var answers: [String: String] = [:]
    @Published var revealed = false
    @Published var saveWarning: String?
    @Published var showLeaveConfirm = false
    @Published var pendingExit: AppRoute?
    @Published var outcome: AttemptOutcome?

    let speech = SpeechReader()
    private let store: ProgressStore

    init() {
        let resolvedStore = ProgressStore(directory: ProgressStore.defaultDirectory())
        store = resolvedStore
        let loaded = resolvedStore.load()
        progress = loaded
        draftName = loaded.playerName
        mapLevel = loaded.recommendedLevel
        loadStories()
    }

    var currentPassage: Passage? {
        guard let catalog, let passageId else { return nil }
        return catalog.passage(id: passageId)
    }

    var currentQuestion: Question? {
        guard let passage = currentPassage else { return nil }
        guard passage.questions.indices.contains(questionIndex) else { return nil }
        return passage.questions[questionIndex]
    }

    func reloadStories() {
        loadStories()
    }

    func saveName() {
        progress.playerName = NameRules.sanitize(draftName)
        draftName = progress.playerName
        persist()
    }

    func startAdventure() {
        saveName()
        mapLevel = progress.recommendedLevel
        speech.stop()
        route = .map
    }

    func showMap() {
        guard !needsLeaveConfirm(before: .map) else { return }
        speech.stop()
        mapLevel = progress.recommendedLevel
        route = .map
    }

    func backToMap() {
        saveName()
        speech.stop()
        route = .map
    }

    func showProgress() {
        guard !needsLeaveConfirm(before: .progress) else { return }
        saveName()
        speech.stop()
        route = .progress
    }

    private func needsLeaveConfirm(before next: AppRoute) -> Bool {
        guard route == .story else { return false }
        pendingExit = next
        showLeaveConfirm = true
        return true
    }

    func selectMapLevel(_ level: Int) {
        guard (1...3).contains(level) else { return }
        mapLevel = level
    }

    func openPassage(_ id: String) {
        guard let catalog, let passage = catalog.passage(id: id) else { return }
        guard QuestRules.isPassageUnlocked(passage, catalog: catalog, progress: progress) else { return }
        speech.stop()
        passageId = id
        phase = .reading
        questionIndex = 0
        answers = [:]
        revealed = false
        outcome = nil
        route = .story
    }

    func openRecommended() {
        guard let catalog, let next = QuestRules.recommendedPassage(catalog: catalog, progress: progress) else {
            showMap()
            return
        }
        openPassage(next.id)
    }

    func beginQuestions() {
        phase = .asking
        questionIndex = 0
        revealed = false
        speech.stop()
    }

    func choose(_ choiceId: String) {
        guard phase == .asking, !revealed, let question = currentQuestion else { return }
        answers[question.id] = choiceId
        revealed = true
        speech.stop()
    }

    func chooseByIndex(_ index: Int) {
        guard let question = currentQuestion, question.choices.indices.contains(index) else { return }
        choose(question.choices[index].id)
    }

    func advanceQuestion() {
        guard revealed, let passage = currentPassage, let catalog else { return }
        if questionIndex + 1 < passage.questions.count {
            questionIndex += 1
            revealed = false
            speech.stop()
            return
        }
        outcome = QuestRules.record(
            passageId: passage.id,
            answers: answers,
            catalog: catalog,
            progress: &progress
        )
        persist()
        speech.stop()
        route = .complete
    }

    func requestLeaveStory() {
        pendingExit = .map
        showLeaveConfirm = true
    }

    func leaveStory() {
        let next = pendingExit ?? .map
        speech.stop()
        showLeaveConfirm = false
        pendingExit = nil
        if next == .progress {
            route = .progress
        } else {
            mapLevel = progress.recommendedLevel
            route = .map
        }
    }

    func cancelLeave() {
        showLeaveConfirm = false
        pendingExit = nil
    }

    func toggleBiggerText() {
        progress.biggerText.toggle()
        persist()
    }

    func resetProgress() {
        speech.stop()
        progress = .empty
        draftName = ""
        passageId = nil
        outcome = nil
        mapLevel = 1
        questionIndex = 0
        answers = [:]
        revealed = false
        do {
            try store.erase()
            saveWarning = nil
        } catch {
            saveWarning = "Progress could not be erased. \(error.localizedDescription)"
        }
        route = .welcome
    }

    func readAloud() {
        if speech.isSpeaking {
            speech.stop()
            return
        }
        guard route == .story, let passage = currentPassage else { return }
        if phase == .reading {
            speech.speak(blocks: passage.sentences.map { (id: $0.id, text: $0.text) })
            return
        }
        guard let question = currentQuestion else { return }
        var blocks: [(id: String, text: String)] = [(id: "prompt", text: question.prompt)]
        for (index, choice) in question.choices.enumerated() {
            blocks.append((id: "choice-\(index)", text: "Choice \(index + 1). \(choice.text)"))
        }
        speech.speak(blocks: blocks)
    }

    func feedback() -> AnswerFeedback? {
        guard revealed, let question = currentQuestion else { return nil }
        return Scoring.feedback(question: question, selectedChoiceId: answers[question.id] ?? "")
    }

    private func loadStories() {
        guard let directory = Self.passagesDirectory() else {
            catalog = nil
            loadError = "The story folder is missing from the app."
            return
        }
        do {
            catalog = try CatalogLoader.load(directory: directory)
            loadError = nil
        } catch {
            catalog = nil
            loadError = (error as? CatalogProblem)?.description ?? error.localizedDescription
        }
    }

    private func persist() {
        do {
            try store.save(progress)
            saveWarning = nil
        } catch {
            saveWarning = "Progress could not be saved. \(error.localizedDescription)"
        }
    }

    private static func passagesDirectory() -> URL? {
        guard let bundled = Bundle.main.resourceURL?.appendingPathComponent("Passages", isDirectory: true) else {
            return nil
        }
        if FileManager.default.fileExists(atPath: bundled.path) {
            return bundled
        }
        return nil
    }
}
