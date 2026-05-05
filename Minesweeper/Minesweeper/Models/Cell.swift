import Foundation

enum CellState: Equatable, Sendable {
    case hidden
    case revealed
    case flagged
    case questioned
}

struct Cell: Equatable, Sendable {
    let row: Int
    let col: Int
    var isMine: Bool = false
    var state: CellState = .hidden
    var adjacentMines: Int = 0
    var isTriggered: Bool = false
    var isWrongFlag: Bool = false

    var isHidden: Bool { state == .hidden }
    var isRevealed: Bool { state == .revealed }
    var isFlagged: Bool { state == .flagged }
    var isQuestioned: Bool { state == .questioned }

    var isCovered: Bool { state == .hidden || state == .questioned }
}
