import Foundation
import SwiftData

@Model
final class GameRecord {
    var difficulty: String
    var rows: Int
    var cols: Int
    var mineCount: Int
    var duration: TimeInterval
    var won: Bool
    var date: Date

    init(difficulty: String, rows: Int, cols: Int, mineCount: Int, duration: TimeInterval, won: Bool, date: Date = .now) {
        self.difficulty = difficulty
        self.rows = rows
        self.cols = cols
        self.mineCount = mineCount
        self.duration = duration
        self.won = won
        self.date = date
    }
}
