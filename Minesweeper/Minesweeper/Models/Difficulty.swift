import Foundation

enum Difficulty: Equatable, Hashable, Sendable, Codable {
    case easy
    case medium
    case hard
    case extreme
    case custom(rows: Int, cols: Int, mines: Int)

    static let presets: [Difficulty] = [.easy, .medium, .hard, .extreme]

    var rows: Int {
        switch self {
        case .easy: 9
        case .medium: 16
        case .hard: 16
        case .extreme: 20
        case .custom(let rows, _, _): rows
        }
    }

    var cols: Int {
        switch self {
        case .easy: 9
        case .medium: 16
        case .hard: 30
        case .extreme: 30
        case .custom(_, let cols, _): cols
        }
    }

    var mines: Int {
        switch self {
        case .easy: 10
        case .medium: 40
        case .hard: 99
        case .extreme: 145
        case .custom(_, _, let mines): mines
        }
    }

    var label: String {
        switch self {
        case .easy: "Easy"
        case .medium: "Medium"
        case .hard: "Hard"
        case .extreme: "Extreme"
        case .custom: "Custom"
        }
    }

    var key: String {
        switch self {
        case .easy: "easy"
        case .medium: "medium"
        case .hard: "hard"
        case .extreme: "extreme"
        case .custom: "custom"
        }
    }

    static func validated(rows: Int, cols: Int, mines: Int) -> Difficulty {
        let clampedRows = max(5, min(rows, 30))
        let clampedCols = max(5, min(cols, 30))
        let maxMines = (clampedRows * clampedCols) - 9
        let clampedMines = max(1, min(mines, maxMines))
        return .custom(rows: clampedRows, cols: clampedCols, mines: clampedMines)
    }

    // MARK: - Codable

    private enum CodingKeys: String, CodingKey {
        case type, rows, cols, mines
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(key, forKey: .type)
        if case .custom(let r, let c, let m) = self {
            try container.encode(r, forKey: .rows)
            try container.encode(c, forKey: .cols)
            try container.encode(m, forKey: .mines)
        }
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(String.self, forKey: .type)
        switch type {
        case "easy": self = .easy
        case "medium": self = .medium
        case "hard": self = .hard
        case "extreme": self = .extreme
        case "custom":
            let r = try container.decode(Int.self, forKey: .rows)
            let c = try container.decode(Int.self, forKey: .cols)
            let m = try container.decode(Int.self, forKey: .mines)
            self = .custom(rows: r, cols: c, mines: m)
        default: self = .easy
        }
    }
}
