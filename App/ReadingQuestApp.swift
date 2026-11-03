import AppKit
import SwiftUI

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        true
    }
}

@main
struct ReadingQuestApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var model = AppModel()

    var body: some Scene {
        WindowGroup("Reading Quest") {
            RootView()
                .environmentObject(model)
                .frame(minWidth: 980, minHeight: 700)
        }
        .defaultSize(width: 1180, height: 800)
        .commands {
            CommandGroup(replacing: .newItem) {}
            CommandMenu("Story") {
                Button("Read to Me") {
                    model.readAloud()
                }
                .keyboardShortcut("r", modifiers: [.command])
                .disabled(model.route != .story || model.catalog == nil)
                Button("Adventure Map") {
                    model.showMap()
                }
                .keyboardShortcut("1", modifiers: [.command])
                .disabled(model.catalog == nil)
                Button("Progress") {
                    model.showProgress()
                }
                .keyboardShortcut("2", modifiers: [.command])
                .disabled(model.catalog == nil)
            }
        }
    }
}
