import AVFoundation
import AVFAudio
import Combine
import Foundation

/// Reads a passage or a question aloud. Speech stays on this Mac.
final class SpeechReader: NSObject, ObservableObject, AVSpeechSynthesizerDelegate {
    @Published var isSpeaking = false
    @Published var speakingSentenceId: String?

    private let speaker = AVSpeechSynthesizer()
    private let lock = NSLock()
    private var activeSession = 0
    private var sentenceIds: [String] = []
    private var startedCount = 0
    private var tokens: [ObjectIdentifier: Int] = [:]

    override init() {
        super.init()
        speaker.delegate = self
    }

    func speak(blocks: [(id: String, text: String)]) {
        stop()
        let cleaned = blocks.filter { !$0.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        guard !cleaned.isEmpty else { return }
        let session = currentSession()
        sentenceIds = cleaned.map(\.id)
        startedCount = 0
        isSpeaking = true
        for block in cleaned {
            let utterance = AVSpeechUtterance(string: block.text)
            utterance.rate = Float(0.43)
            utterance.pitchMultiplier = Float(1.05)
            utterance.postUtteranceDelay = 0.12
            utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
            remember(utterance, session: session)
            speaker.speak(utterance)
        }
    }

    func stop() {
        bumpSession()
        speaker.stopSpeaking(at: .immediate)
        clearTokens()
        sentenceIds = []
        startedCount = 0
        isSpeaking = false
        speakingSentenceId = nil
    }

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didStart utterance: AVSpeechUtterance) {
        let token = token(for: utterance)
        DispatchQueue.main.async { [weak self] in
            guard let self, let token, token == self.currentSession() else { return }
            if self.startedCount < self.sentenceIds.count {
                self.speakingSentenceId = self.sentenceIds[self.startedCount]
            }
            self.startedCount += 1
            self.isSpeaking = true
        }
    }

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        let token = token(for: utterance)
        forget(utterance)
        DispatchQueue.main.async { [weak self] in
            guard let self, let token, token == self.currentSession() else { return }
            if self.startedCount >= self.sentenceIds.count && !self.speaker.isSpeaking {
                self.isSpeaking = false
                self.speakingSentenceId = nil
            }
        }
    }

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        let token = token(for: utterance)
        forget(utterance)
        DispatchQueue.main.async { [weak self] in
            guard let self, let token, token == self.currentSession() else { return }
            if !self.speaker.isSpeaking {
                self.isSpeaking = false
                self.speakingSentenceId = nil
            }
        }
    }

    private func bumpSession() {
        lock.lock()
        activeSession += 1
        lock.unlock()
    }

    private func currentSession() -> Int {
        lock.lock()
        defer { lock.unlock() }
        return activeSession
    }

    private func remember(_ utterance: AVSpeechUtterance, session: Int) {
        lock.lock()
        tokens[ObjectIdentifier(utterance)] = session
        lock.unlock()
    }

    private func token(for utterance: AVSpeechUtterance) -> Int? {
        lock.lock()
        defer { lock.unlock() }
        return tokens[ObjectIdentifier(utterance)]
    }

    private func forget(_ utterance: AVSpeechUtterance) {
        lock.lock()
        tokens[ObjectIdentifier(utterance)] = nil
        lock.unlock()
    }

    private func clearTokens() {
        lock.lock()
        tokens.removeAll()
        lock.unlock()
    }
}
