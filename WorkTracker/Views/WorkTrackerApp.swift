import SwiftUI

@main
struct WorkTrackerApp: App {
    @AppStorage("appearanceSetting") private var appearanceSetting: String = "system"

    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(colorScheme)
        }
    }

    private var colorScheme: ColorScheme? {
        switch appearanceSetting {
        case "light": return .light
        case "dark": return .dark
        default: return nil  // follow system
        }
    }
}

