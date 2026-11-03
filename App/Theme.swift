import SwiftUI

struct QuestTheme {
    var parchment: Color
    var ink: Color
    var muted: Color
    var meadow: Color
    var woods: Color
    var peaks: Color
    var gold: Color
    var highlight: Color
    var highlightInk: Color
    var coral: Color
    var card: Color
    var stroke: Color

    static func resolve(_ scheme: ColorScheme) -> QuestTheme {
        if scheme == .dark {
            return QuestTheme(
                parchment: Color(red: 0.11, green: 0.10, blue: 0.09),
                ink: Color(red: 0.96, green: 0.93, blue: 0.86),
                muted: Color(red: 0.76, green: 0.71, blue: 0.62),
                meadow: Color(red: 0.42, green: 0.74, blue: 0.52),
                woods: Color(red: 0.36, green: 0.74, blue: 0.70),
                peaks: Color(red: 0.67, green: 0.73, blue: 0.96),
                gold: Color(red: 0.96, green: 0.79, blue: 0.38),
                highlight: Color(red: 0.96, green: 0.84, blue: 0.46),
                highlightInk: Color(red: 0.16, green: 0.11, blue: 0.04),
                coral: Color(red: 0.91, green: 0.58, blue: 0.45),
                card: Color(red: 0.18, green: 0.16, blue: 0.14),
                stroke: Color(red: 0.45, green: 0.40, blue: 0.32)
            )
        }
        return QuestTheme(
            parchment: Color(red: 0.969, green: 0.941, blue: 0.886),
            ink: Color(red: 0.145, green: 0.106, blue: 0.071),
            muted: Color(red: 0.38, green: 0.32, blue: 0.26),
            meadow: Color(red: 0.09, green: 0.40, blue: 0.27),
            woods: Color(red: 0.05, green: 0.38, blue: 0.38),
            peaks: Color(red: 0.22, green: 0.28, blue: 0.55),
            gold: Color(red: 0.72, green: 0.46, blue: 0.05),
            highlight: Color(red: 1.0, green: 0.88, blue: 0.55),
            highlightInk: Color(red: 0.16, green: 0.11, blue: 0.04),
            coral: Color(red: 0.70, green: 0.33, blue: 0.22),
            card: Color.white.opacity(0.78),
            stroke: Color(red: 0.145, green: 0.106, blue: 0.071).opacity(0.16)
        )
    }

    func trail(_ level: Int) -> Color {
        switch level {
        case 2:
            return woods
        case 3:
            return peaks
        default:
            return meadow
        }
    }
}

private struct QuestThemeKey: EnvironmentKey {
    static let defaultValue = QuestTheme.resolve(.light)
}

extension EnvironmentValues {
    var questTheme: QuestTheme {
        get { self[QuestThemeKey.self] }
        set { self[QuestThemeKey.self] = newValue }
    }
}

enum QuestFont {
    static func story(bigger: Bool, poem: Bool) -> Font {
        .system(size: bigger ? 26 : 22, weight: .regular, design: poem ? .serif : .rounded)
    }

    static func display(_ size: CGFloat) -> Font {
        .system(size: size, weight: .bold, design: .rounded)
    }
}
