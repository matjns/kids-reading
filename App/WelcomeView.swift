import SwiftUI

struct WelcomeView: View {
    @EnvironmentObject private var model: AppModel
    @Environment(\.questTheme) private var theme

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                TrailSketch()
                Text("Reading Quest")
                    .font(QuestFont.display(52))
                    .foregroundStyle(theme.ink)
                Text("Short stories, fables, poems, and real facts. Read one, then show what you noticed.")
                    .font(.system(size: 22, weight: .regular, design: .rounded))
                    .foregroundStyle(theme.muted)
                    .fixedSize(horizontal: false, vertical: true)

                VStack(alignment: .leading, spacing: 8) {
                    Text("Your name, if you want one")
                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                        .foregroundStyle(theme.ink)
                    TextField("Leave blank if you like", text: nameBinding)
                        .textFieldStyle(.roundedBorder)
                        .font(.system(size: 22, design: .rounded))
                        .onSubmit { model.saveName() }
                        .accessibilityLabel("Your name, optional")
                    Text("You can skip this. The name stays on this Mac.")
                        .font(.system(size: 15, design: .rounded))
                        .foregroundStyle(theme.muted)
                }

                Button(model.progress.passagesFinished > 0 ? "Continue the adventure" : "Start the adventure") {
                    model.startAdventure()
                }
                .buttonStyle(QuestButtonStyle(fill: theme.meadow, ink: .white))
                .keyboardShortcut(.defaultAction)

                Text("Works offline. No account. Your stars stay on this Mac.")
                    .font(.system(size: 15, design: .rounded))
                    .foregroundStyle(theme.muted)
            }
            .padding(32)
            .frame(maxWidth: 760, alignment: .leading)
            .frame(maxWidth: .infinity)
        }
    }

    private var nameBinding: Binding<String> {
        Binding(
            get: { model.draftName },
            set: { model.draftName = $0 }
        )
    }
}
