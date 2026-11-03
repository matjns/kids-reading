import SwiftUI

struct RootView: View {
    @EnvironmentObject private var model: AppModel
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        themed(QuestTheme.resolve(colorScheme))
    }

    private func themed(_ theme: QuestTheme) -> some View {
        ZStack {
            theme.parchment.ignoresSafeArea()
            VStack(spacing: 0) {
                if model.route != .welcome && model.catalog != nil {
                    TopBar()
                }
                Group {
                    if model.catalog == nil {
                        LoadProblemView()
                    } else {
                        switch model.route {
                        case .welcome:
                            WelcomeView()
                        case .map:
                            MapView()
                        case .story:
                            StoryView()
                        case .complete:
                            CompleteView()
                        case .progress:
                            ProgressView()
                        }
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .environment(\.questTheme, theme)
        .navigationTitle("Reading Quest")
    }
}

private struct LoadProblemView: View {
    @EnvironmentObject private var model: AppModel
    @Environment(\.questTheme) private var theme

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("The stories could not be opened.")
                .font(QuestFont.display(32))
                .foregroundStyle(theme.ink)
            Text("Reading Quest needs its story files, and something is missing or mistyped. A parent can read the note below.")
                .font(.system(size: 20, weight: .regular, design: .rounded))
                .foregroundStyle(theme.muted)
            if let loadError = model.loadError {
                Text(loadError)
                    .font(.system(size: 14, design: .rounded))
                    .foregroundStyle(theme.ink)
                    .textSelection(.enabled)
                    .padding(14)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(theme.card, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            Button("Try again") { model.reloadStories() }
                .buttonStyle(QuestButtonStyle(fill: theme.meadow, ink: .white, wide: false))
        }
        .padding(32)
        .frame(maxWidth: 760, alignment: .leading)
    }
}
