import SwiftData
import SwiftUI

@main
struct MinesweeperApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: GameRecord.self)
    }
}
