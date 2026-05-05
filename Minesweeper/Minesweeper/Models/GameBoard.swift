import Foundation

enum GameState: Equatable, Sendable {
    case ready
    case playing
    case won
    case lost
}

enum RevealResult: Equatable, Sendable {
    case safe
    case mine
    case win
    case alreadyRevealed
}

struct GameBoard: Sendable {
    let rows: Int
    let cols: Int
    let mineCount: Int
    private(set) var grid: [[Cell]]
    private(set) var minesPlaced: Bool = false

    init(rows: Int, cols: Int, mineCount: Int) {
        self.rows = rows
        self.cols = cols
        self.mineCount = mineCount
        self.grid = (0..<rows).map { row in
            (0..<cols).map { col in
                Cell(row: row, col: col)
            }
        }
    }

    /// Test-only initializer with pre-placed mines at specified positions.
    init(rows: Int, cols: Int, minePositions: [(Int, Int)]) {
        self.rows = rows
        self.cols = cols
        self.mineCount = minePositions.count
        self.grid = (0..<rows).map { row in
            (0..<cols).map { col in
                Cell(row: row, col: col)
            }
        }
        for (r, c) in minePositions {
            grid[r][c].isMine = true
        }
        computeAdjacentCounts()
        minesPlaced = true
    }

    var flagCount: Int {
        grid.flatMap { $0 }.filter(\.isFlagged).count
    }

    var remainingMines: Int {
        mineCount - flagCount
    }

    var revealedCount: Int {
        grid.flatMap { $0 }.filter(\.isRevealed).count
    }

    var totalSafeCells: Int {
        rows * cols - mineCount
    }

    var isWon: Bool {
        revealedCount == totalSafeCells
    }

    // MARK: - Mine Placement

    mutating func placeMines(excludingRow safeRow: Int, excludingCol safeCol: Int) {
        guard !minesPlaced else { return }

        let safeZone = neighbors(of: safeRow, safeCol) + [(safeRow, safeCol)]
        let safeSet = Set(safeZone.map { $0.0 * cols + $0.1 })

        var candidates = [Int]()
        for i in 0..<(rows * cols) where !safeSet.contains(i) {
            candidates.append(i)
        }

        let actualMineCount = min(mineCount, candidates.count)
        let canPreventInstantWin = actualMineCount < candidates.count - 1

        for attempt in 0..<100 {
            clearMines()
            candidates.shuffle()

            for i in 0..<actualMineCount {
                let idx = candidates[i]
                grid[idx / cols][idx % cols].isMine = true
            }
            computeAdjacentCounts()

            if !canPreventInstantWin || attempt == 99 {
                break
            }
            if !wouldInstantWin(fromRow: safeRow, col: safeCol) {
                break
            }
        }

        minesPlaced = true
    }

    private mutating func clearMines() {
        for r in 0..<rows {
            for c in 0..<cols {
                grid[r][c].isMine = false
                grid[r][c].adjacentMines = 0
            }
        }
    }

    /// Simulates a flood fill from the given cell without mutating state.
    /// Returns true if revealing that cell would win the game.
    private func wouldInstantWin(fromRow row: Int, col: Int) -> Bool {
        var revealCount = 0
        var queue = [(row, col)]
        var visited = Set<Int>()
        visited.insert(row * cols + col)

        while !queue.isEmpty {
            let (r, c) = queue.removeFirst()
            guard !grid[r][c].isMine else { continue }
            revealCount += 1
            if grid[r][c].adjacentMines == 0 {
                for (nr, nc) in neighbors(of: r, c) {
                    let key = nr * cols + nc
                    if !visited.contains(key) {
                        visited.insert(key)
                        queue.append((nr, nc))
                    }
                }
            }
        }
        return revealCount >= totalSafeCells
    }

    private mutating func computeAdjacentCounts() {
        for r in 0..<rows {
            for c in 0..<cols {
                if grid[r][c].isMine { continue }
                var count = 0
                for (nr, nc) in neighbors(of: r, c) {
                    if grid[nr][nc].isMine { count += 1 }
                }
                grid[r][c].adjacentMines = count
            }
        }
    }

    // MARK: - Reveal

    mutating func revealCell(row: Int, col: Int) -> RevealResult {
        guard isValid(row: row, col: col) else { return .alreadyRevealed }
        let cell = grid[row][col]

        if cell.isRevealed {
            return chordReveal(row: row, col: col)
        }
        guard cell.isCovered else { return .alreadyRevealed }

        if !minesPlaced {
            placeMines(excludingRow: row, excludingCol: col)
        }

        if grid[row][col].isMine {
            grid[row][col].state = .revealed
            grid[row][col].isTriggered = true
            return .mine
        }

        floodFillReveal(row: row, col: col)

        return isWon ? .win : .safe
    }

    private mutating func floodFillReveal(row: Int, col: Int) {
        var queue = [(row, col)]
        var visited = Set<Int>()
        visited.insert(row * cols + col)

        while !queue.isEmpty {
            let (r, c) = queue.removeFirst()
            guard !grid[r][c].isRevealed, !grid[r][c].isMine else { continue }

            grid[r][c].state = .revealed

            if grid[r][c].adjacentMines == 0 {
                for (nr, nc) in neighbors(of: r, c) {
                    let key = nr * cols + nc
                    if !visited.contains(key) {
                        visited.insert(key)
                        queue.append((nr, nc))
                    }
                }
            }
        }
    }

    private mutating func chordReveal(row: Int, col: Int) -> RevealResult {
        let cell = grid[row][col]
        guard cell.isRevealed, cell.adjacentMines > 0 else { return .alreadyRevealed }

        let neighborCells = neighbors(of: row, col)
        let adjacentFlags = neighborCells.filter { grid[$0.0][$0.1].isFlagged }.count

        guard adjacentFlags == cell.adjacentMines else { return .alreadyRevealed }

        var hitMine = false
        for (nr, nc) in neighborCells where grid[nr][nc].isCovered {
            if grid[nr][nc].isMine {
                grid[nr][nc].state = .revealed
                grid[nr][nc].isTriggered = true
                hitMine = true
            } else {
                floodFillReveal(row: nr, col: nc)
            }
        }

        if hitMine { return .mine }
        return isWon ? .win : .safe
    }

    // MARK: - Flag

    mutating func toggleFlag(row: Int, col: Int) {
        guard isValid(row: row, col: col) else { return }
        switch grid[row][col].state {
        case .hidden:
            grid[row][col].state = .flagged
        case .flagged:
            grid[row][col].state = .questioned
        case .questioned:
            grid[row][col].state = .hidden
        case .revealed:
            break
        }
    }

    // MARK: - Game Over

    mutating func revealAllMines() {
        for r in 0..<rows {
            for c in 0..<cols {
                if grid[r][c].isMine && !grid[r][c].isFlagged {
                    grid[r][c].state = .revealed
                }
                if !grid[r][c].isMine && grid[r][c].isFlagged {
                    grid[r][c].isWrongFlag = true
                }
            }
        }
    }

    // MARK: - Helpers

    func neighbors(of row: Int, _ col: Int) -> [(Int, Int)] {
        var result = [(Int, Int)]()
        for dr in -1...1 {
            for dc in -1...1 {
                if dr == 0 && dc == 0 { continue }
                let nr = row + dr
                let nc = col + dc
                if isValid(row: nr, col: nc) {
                    result.append((nr, nc))
                }
            }
        }
        return result
    }

    func isValid(row: Int, col: Int) -> Bool {
        row >= 0 && row < rows && col >= 0 && col < cols
    }
}
