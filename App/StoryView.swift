import SwiftUI

struct StoryView: View {
    @EnvironmentObject private var model: AppModel

    var body: some View {
        StoryBody(speech: model.speech)
    }
}

private struct StoryBody: View {
    @ObservedObject var speech: SpeechReader
    @EnvironmentObject private var model: AppModel
    @Environment(\.questTheme) private var theme

    var body: some View {
        Group {
            if let passage = model.currentPassage {
                GeometryReader { geo in
                    if model.phase == .asking && geo.size.width >= 900 {
                        HStack(spacing: 0) {
                            passageColumn(passage)
                                .frame(width: geo.size.width * 0.46)
                            Rectangle().fill(theme.stroke).frame(width: 1)
                            questionColumn(passage)
                        }
                    } else if model.phase == .asking {
                        VStack(spacing: 0) {
                            passageColumn(passage)
                                .frame(maxHeight: geo.size.height * 0.42)
                            Rectangle().fill(theme.stroke).frame(height: 1)
                            questionColumn(passage)
                        }
                    } else {
                        passageColumn(passage)
                    }
                }
            } else {
                Text("That story is not on the map.")
                    .font(QuestFont.display(28))
                    .foregroundStyle(theme.ink)
                    .padding(32)
            }
        }
        .confirmationDialog(
            "Leave this story?",
            isPresented: leaveBinding,
            titleVisibility: .visible
        ) {
            Button("Leave without stars", role: .destructive) { model.leaveStory() }
            Button("Keep reading", role: .cancel) { model.cancelLeave() }
        } message: {
            Text("Stars for this story are saved after the last question.")
        }
        .background(shortcutCatcher)
    }

    private func passageColumn(_ passage: Passage) -> some View {
        let lookBack = Set(model.feedback()?.lookBackSentenceIds ?? [])
        return ScrollViewReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    HStack(spacing: 8) {
                        Text(passage.kind.kidLabel)
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(theme.trail(passage.level).opacity(0.15), in: Capsule())
                            .foregroundStyle(theme.trail(passage.level))
                        Text(TrailGuide.name(for: passage.level))
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .foregroundStyle(theme.muted)
                    }
                    Text(passage.title)
                        .font(QuestFont.display(32))
                        .foregroundStyle(theme.ink)
                    if !lookBack.isEmpty {
                        Label("Look back in the story", systemImage: "arrow.turn.down.right")
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundStyle(theme.highlightInk)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(theme.highlight, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                    VStack(alignment: .leading, spacing: passage.kind == .poem ? 4 : 8) {
                        ForEach(passage.sentences) { sentence in
                            sentenceView(sentence, passage: passage, lookBack: lookBack)
                                .id(sentence.id)
                        }
                    }
                    if let note = passage.attribution {
                        Text(note)
                            .font(.system(size: 13, design: .rounded))
                            .foregroundStyle(theme.muted)
                    }
                    if model.phase == .reading {
                        HStack(spacing: 12) {
                            readButton
                            Button("I'm ready for the questions") { model.beginQuestions() }
                                .buttonStyle(QuestButtonStyle(fill: theme.trail(passage.level), ink: .white))
                                .keyboardShortcut(.defaultAction)
                        }
                    }
                    Button("Leave story") { model.requestLeaveStory() }
                        .buttonStyle(QuestButtonStyle(fill: theme.card, ink: theme.ink, wide: false))
                }
                .padding(24)
                .frame(maxWidth: 760, alignment: .leading)
            }
            .onChange(of: lookBackKey) { _, _ in
                guard let first = model.feedback()?.lookBackSentenceIds.first else { return }
                withAnimation(.easeInOut(duration: 0.25)) {
                    proxy.scrollTo(first, anchor: .center)
                }
            }
        }
    }

    private func sentenceView(_ sentence: Sentence, passage: Passage, lookBack: Set<String>) -> some View {
        let highlighted = lookBack.contains(sentence.id)
        let speaking = speech.speakingSentenceId == sentence.id
        return Text(sentence.text)
            .font(QuestFont.story(bigger: model.progress.biggerText, poem: passage.kind == .poem))
            .foregroundStyle(highlighted ? theme.highlightInk : theme.ink)
            .frame(maxWidth: .infinity, alignment: passage.kind == .poem ? .center : .leading)
            .padding(.horizontal, 10)
            .padding(.vertical, highlighted || speaking ? 8 : 2)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(highlighted ? theme.highlight : (speaking ? theme.gold.opacity(0.25) : Color.clear))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(highlighted ? theme.gold : Color.clear, lineWidth: 2)
            )
            .accessibilityLabel(highlighted ? "Look back. \(sentence.text)" : sentence.text)
    }

    private func questionColumn(_ passage: Passage) -> some View {
        guard let question = model.currentQuestion else {
            return AnyView(EmptyView())
        }
        let feedback = model.feedback()
        return AnyView(
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Question \(model.questionIndex + 1) of \(passage.questions.count)")
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundStyle(theme.muted)
                    Text(question.skill.kidLabel)
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(theme.gold.opacity(0.2), in: Capsule())
                        .foregroundStyle(theme.ink)
                    Text(question.prompt)
                        .font(QuestFont.story(bigger: model.progress.biggerText, poem: false))
                        .foregroundStyle(theme.ink)
                        .fixedSize(horizontal: false, vertical: true)
                    if !model.revealed {
                        Text("Press 1, 2, 3, or 4, or tap an answer.")
                            .font(.system(size: 14, design: .rounded))
                            .foregroundStyle(theme.muted)
                    }
                    ForEach(Array(question.choices.enumerated()), id: \.element.id) { index, choice in
                        choiceButton(index: index, choice: choice, feedback: feedback)
                    }
                    if let feedback {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(feedback.headline)
                                .font(.system(size: 22, weight: .bold, design: .rounded))
                                .foregroundStyle(feedback.correct ? theme.meadow : theme.coral)
                            Text(feedback.explanation)
                                .font(.system(size: model.progress.biggerText ? 20 : 18, design: .rounded))
                                .foregroundStyle(theme.ink)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .padding(16)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(theme.card, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                        Button(model.questionIndex + 1 == passage.questions.count ? "See my stars" : "Next question") {
                            model.advanceQuestion()
                        }
                        .buttonStyle(QuestButtonStyle(fill: theme.trail(passage.level), ink: .white))
                        .keyboardShortcut(.defaultAction)
                    }
                    readButton
                }
                .padding(24)
                .frame(maxWidth: 680, alignment: .leading)
            }
        )
    }

    private func choiceButton(index: Int, choice: Choice, feedback: AnswerFeedback?) -> some View {
        let revealed = feedback != nil
        let isCorrectChoice = feedback?.correctChoiceId == choice.id
        let isSelected = model.answers[model.currentQuestion?.id ?? ""] == choice.id
        let fill: Color
        let ink: Color
        if revealed && isCorrectChoice {
            fill = theme.meadow
            ink = .white
        } else if revealed && isSelected {
            fill = theme.coral.opacity(0.18)
            ink = theme.ink
        } else {
            fill = theme.card
            ink = theme.ink
        }
        return Button {
            model.choose(choice.id)
        } label: {
            HStack(alignment: .center, spacing: 12) {
                Text("\(index + 1)")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .frame(width: 36, height: 36)
                    .background(Circle().fill(ink.opacity(revealed && isCorrectChoice ? 0.2 : 0.08)))
                Text(choice.text)
                    .font(.system(size: model.progress.biggerText ? 20 : 18, weight: .semibold, design: .rounded))
                    .multilineTextAlignment(.leading)
                Spacer(minLength: 8)
                if revealed && isCorrectChoice {
                    Image(systemName: "checkmark.circle.fill")
                } else if revealed && isSelected {
                    Image(systemName: "arrow.uturn.backward.circle")
                }
            }
            .foregroundStyle(ink)
            .padding(12)
            .frame(maxWidth: .infinity, minHeight: 64, alignment: .leading)
            .background(fill, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(theme.stroke, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .allowsHitTesting(!revealed)
        .accessibilityHint("Answer \(index + 1)")
    }

    private var readButton: some View {
        Button(speech.isSpeaking ? "Stop reading" : "Read to me") {
            model.readAloud()
        }
        .buttonStyle(QuestButtonStyle(fill: theme.card, ink: theme.ink, wide: false))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(theme.stroke, lineWidth: 1)
        )
    }

    private var lookBackKey: String {
        (model.feedback()?.lookBackSentenceIds ?? []).joined(separator: ",")
    }

    private var leaveBinding: Binding<Bool> {
        Binding(
            get: { model.showLeaveConfirm },
            set: { model.showLeaveConfirm = $0 }
        )
    }

    @ViewBuilder
    private var shortcutCatcher: some View {
        if model.phase == .asking && !model.revealed {
            ZStack {
                ForEach(0..<4, id: \.self) { number in
                    Button("Answer \(number + 1)") {
                        model.chooseByIndex(number)
                    }
                    .keyboardShortcut(KeyEquivalent(Character("\(number + 1)")), modifiers: [])
                    .opacity(0)
                    .frame(width: 0, height: 0)
                    .accessibilityHidden(true)
                }
            }
        }
    }
}
