import Combine
import SwiftUI

@Observable
@MainActor
final class GameViewModel {
    private(set) var board: GameBoard
    private(set) var gameState: GameState = .ready
    private(set) var elapsedSeconds: Int = 0
    var difficulty: Difficulty

    private var timerCancellable: AnyCancellable?
    private var startDate: Date?

    init(difficulty: Difficulty = .easy) {
        self.difficulty = difficulty
        self.board = GameBoard(rows: difficulty.rows, cols: difficulty.cols, mineCount: difficulty.mines)
    }

    init(difficulty: Difficulty = .easy, board: GameBoard) {
        self.difficulty = difficulty
        self.board = board
    }

    // MARK: - Computed

    var remainingMines: Int { board.remainingMines }
    var rows: Int { board.rows }
    var cols: Int { board.cols }

    var smileyFace: String {
        switch gameState {
        case .ready, .playing: "🙂"
        case .won: "😎"
        case .lost: "😵"
        }
    }

    func cell(at row: Int, col: Int) -> Cell {
        board.grid[row][col]
    }

    // MARK: - Actions

    func tapCell(row: Int, col: Int) {
        guard gameState == .ready || gameState == .playing else { return }

        if gameState == .ready {
            gameState = .playing
            startTimer()
        }

        let result = board.revealCell(row: row, col: col)

        switch result {
        case .mine:
            gameState = .lost
            board.revealAllMines()
            stopTimer()
            HapticManager.heavy()
        case .win:
            gameState = .won
            stopTimer()
            HapticManager.success()
        case .safe:
            HapticManager.light()
        case .alreadyRevealed:
            break
        }
    }

    func flagCell(row: Int, col: Int) {
        guard gameState == .ready || gameState == .playing else { return }

        if gameState == .ready {
            gameState = .playing
            startTimer()
        }

        board.toggleFlag(row: row, col: col)
        HapticManager.medium()
    }

    func reset() {
        stopTimer()
        board = GameBoard(rows: difficulty.rows, cols: difficulty.cols, mineCount: difficulty.mines)
        gameState = .ready
        elapsedSeconds = 0
        startDate = nil
    }

    func changeDifficulty(_ newDifficulty: Difficulty) {
        difficulty = newDifficulty
        reset()
    }

    // MARK: - Timer

    private func startTimer() {
        startDate = Date()
        timerCancellable = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self, let start = self.startDate else { return }
                self.elapsedSeconds = Int(Date().timeIntervalSince(start))
            }
    }

    private func stopTimer() {
        timerCancellable?.cancel()
        timerCancellable = nil
    }
}

// MARK: - Haptics

@MainActor
enum HapticManager {
    static func light() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    static func medium() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }

    static func heavy() {
        UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
    }

    static func success() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }
}
