import Testing
@testable import Minesweeper

/// End-to-end user journey tests simulating real gameplay sequences.

// MARK: - Full Win Journey

@Suite("Win Journey")
@MainActor
struct WinJourneyTests {

    @Test func completeWinOnSmallBoard() {
        // 3x3 board, mine at (2,2). Tap (0,0) should flood-fill all safe cells.
        let board = GameBoard(rows: 3, cols: 3, minePositions: [(2, 2)])
        let vm = GameViewModel(board: board)

        #expect(vm.gameState == .ready)
        #expect(vm.smileyFace == "🙂")

        vm.tapCell(row: 0, col: 0)

        #expect(vm.gameState == .won)
        #expect(vm.smileyFace == "😎")
        // All non-mine cells revealed
        for r in 0..<3 {
            for c in 0..<3 {
                if r == 2 && c == 2 { continue }
                #expect(vm.board.grid[r][c].isRevealed == true)
            }
        }
    }

    @Test func winByRevealingCellsOneByOne() {
        // 3x3, mines at (0,0) and (0,1). 7 safe cells.
        let board = GameBoard(rows: 3, cols: 3, minePositions: [(0, 0), (0, 1)])
        let vm = GameViewModel(board: board)

        // Reveal safe cells manually
        vm.tapCell(row: 2, col: 2) // should flood fill most of the board
        // Check if already won (flood fill might get everything)
        if vm.gameState != .won {
            // Reveal remaining unrevealed safe cells
            for r in 0..<3 {
                for c in 0..<3 {
                    let cell = vm.board.grid[r][c]
                    if !cell.isMine && !cell.isRevealed {
                        vm.tapCell(row: r, col: c)
                    }
                }
            }
        }
        #expect(vm.gameState == .won)
    }
}

// MARK: - Full Loss Journey

@Suite("Loss Journey")
@MainActor
struct LossJourneyTests {

    @Test func hitMineImmediately() {
        let board = GameBoard(rows: 5, cols: 5, minePositions: [(2, 2)])
        let vm = GameViewModel(board: board)

        vm.tapCell(row: 2, col: 2)

        #expect(vm.gameState == .lost)
        #expect(vm.smileyFace == "😵")
        #expect(vm.board.grid[2][2].isTriggered == true)
    }

    @Test func playThenHitMine() {
        let board = GameBoard(rows: 5, cols: 5, minePositions: [(3, 3)])
        let vm = GameViewModel(board: board)

        vm.tapCell(row: 0, col: 0) // safe
        #expect(vm.gameState == .playing)

        vm.flagCell(row: 1, col: 1) // flag a cell
        #expect(vm.gameState == .playing)

        vm.tapCell(row: 3, col: 3) // hit mine
        #expect(vm.gameState == .lost)
    }

    @Test func allMinesRevealedOnLoss() {
        let board = GameBoard(rows: 5, cols: 5, minePositions: [(0, 0), (3, 3), (4, 4)])
        let vm = GameViewModel(board: board)

        vm.tapCell(row: 0, col: 0) // hit mine
        #expect(vm.gameState == .lost)

        // All unflagged mines should be revealed
        #expect(vm.board.grid[3][3].isRevealed == true)
        #expect(vm.board.grid[4][4].isRevealed == true)
    }

    @Test func resetAfterLossAndPlayAgain() {
        let board = GameBoard(rows: 5, cols: 5, minePositions: [(2, 2)])
        let vm = GameViewModel(board: board)

        vm.tapCell(row: 2, col: 2) // lose
        #expect(vm.gameState == .lost)

        vm.reset()
        #expect(vm.gameState == .ready)
        #expect(vm.smileyFace == "🙂")

        // Board is fresh
        for row in vm.board.grid {
            for cell in row {
                #expect(cell.state == .hidden)
            }
        }

        // Can play again
        vm.tapCell(row: 0, col: 0)
        #expect(vm.gameState == .playing || vm.gameState == .won)
    }
}

// MARK: - Flag Prevents Reveal

@Suite("Flag Protection")
@MainActor
struct FlagProtectionTests {

    @Test func flaggedCellCannotBeRevealedByTap() {
        let board = GameBoard(rows: 5, cols: 5, minePositions: [(4, 4)])
        let vm = GameViewModel(board: board)

        vm.flagCell(row: 0, col: 0)
        #expect(vm.board.grid[0][0].isFlagged == true)

        vm.tapCell(row: 0, col: 0) // should be ignored
        #expect(vm.board.grid[0][0].isFlagged == true)
        #expect(vm.board.grid[0][0].isRevealed == false)
    }

    @Test func flaggedMineCellProtectedFromTap() {
        let board = GameBoard(rows: 5, cols: 5, minePositions: [(2, 2)])
        let vm = GameViewModel(board: board)

        vm.flagCell(row: 2, col: 2) // flag the mine
        vm.tapCell(row: 2, col: 2) // try to tap it

        // Should NOT lose -- flag protects
        #expect(vm.gameState != .lost)
        #expect(vm.board.grid[2][2].isFlagged == true)
    }

    @Test func unflagThenRevealWorks() {
        let board = GameBoard(rows: 5, cols: 5, minePositions: [(4, 4)])
        let vm = GameViewModel(board: board)

        vm.flagCell(row: 0, col: 0)    // flag
        vm.flagCell(row: 0, col: 0)    // question
        vm.flagCell(row: 0, col: 0)    // back to hidden
        vm.tapCell(row: 0, col: 0)     // now can reveal

        #expect(vm.board.grid[0][0].isRevealed == true)
    }
}

// MARK: - Question Mark State

@Suite("Question Mark Journeys")
@MainActor
struct QuestionMarkTests {

    @Test func questionedCellCanBeRevealed() {
        let board = GameBoard(rows: 5, cols: 5, minePositions: [(4, 4)])
        let vm = GameViewModel(board: board)

        vm.flagCell(row: 0, col: 0)  // hidden -> flagged
        vm.flagCell(row: 0, col: 0)  // flagged -> questioned
        #expect(vm.board.grid[0][0].isQuestioned == true)

        vm.tapCell(row: 0, col: 0)   // can reveal a questioned cell
        #expect(vm.board.grid[0][0].isRevealed == true)
    }

    @Test func questionedMineExplodes() {
        let board = GameBoard(rows: 5, cols: 5, minePositions: [(2, 2)])
        let vm = GameViewModel(board: board)

        vm.flagCell(row: 2, col: 2)  // flag
        vm.flagCell(row: 2, col: 2)  // question
        #expect(vm.board.grid[2][2].isQuestioned == true)

        vm.tapCell(row: 2, col: 2)   // questioned mine -- boom
        #expect(vm.gameState == .lost)
    }

    @Test func questionedCellDoesNotCountAsFlag() {
        let board = GameBoard(rows: 5, cols: 5, minePositions: [(4, 4)])
        let vm = GameViewModel(board: board)

        vm.flagCell(row: 0, col: 0)  // flag => remainingMines = 0
        #expect(vm.remainingMines == 0)

        vm.flagCell(row: 0, col: 0)  // question => remainingMines = 1
        #expect(vm.remainingMines == 1)
    }

    @Test func fullCycleMultipleTimes() {
        let board = GameBoard(rows: 5, cols: 5, minePositions: [(4, 4)])
        let vm = GameViewModel(board: board)

        for _ in 0..<3 {
            vm.flagCell(row: 1, col: 1) // hidden -> flagged
            #expect(vm.board.grid[1][1].isFlagged == true)
            vm.flagCell(row: 1, col: 1) // flagged -> questioned
            #expect(vm.board.grid[1][1].isQuestioned == true)
            vm.flagCell(row: 1, col: 1) // questioned -> hidden
            #expect(vm.board.grid[1][1].isHidden == true)
        }
    }
}

// MARK: - Chord Reveal Journeys

@Suite("Chord Reveal Journeys")
@MainActor
struct ChordRevealJourneyTests {

    @Test func chordRevealSafelyRevealsNeighbors() {
        // 4x4 board, mine at (0,3)
        let board = GameBoard(rows: 4, cols: 4, minePositions: [(0, 3)])
        let vm = GameViewModel(board: board)

        // Reveal a cell
        vm.tapCell(row: 2, col: 0)

        // Flag the mine
        vm.flagCell(row: 0, col: 3)

        // Find a revealed number cell adjacent to the flag
        // (0,2) should have adjacentMines=1
        #expect(vm.board.grid[0][2].isRevealed == true)
        #expect(vm.board.grid[0][2].adjacentMines == 1)

        // Chord reveal on (0,2)
        vm.tapCell(row: 0, col: 2)
        // Should not lose
        #expect(vm.gameState != .lost)
    }

    @Test func chordRevealWithQuestionedCellRevealsIt() {
        // Questioned cells are NOT flags -- they don't protect during chord reveal.
        // Use a 5x5 board so flood fill doesn't immediately win.
        // Mines at (0,4) and (4,0) -- cell (0,3) has adjacentMines=1
        let board = GameBoard(rows: 5, cols: 5, minePositions: [(0, 4), (4, 0)])
        let vm = GameViewModel(board: board)

        vm.tapCell(row: 2, col: 2) // reveal some cells

        // Question the mine at (0,4) instead of flagging it
        vm.flagCell(row: 0, col: 4) // flag
        vm.flagCell(row: 0, col: 4) // question

        // Flag a non-mine cell adjacent to (0,3) to satisfy the chord count
        // (0,3) has adjacentMines=1. We need 1 adjacent flag.
        // Flag (1,4) which is adjacent to (0,3) and is NOT a mine
        vm.flagCell(row: 1, col: 4) // flag (wrong flag)

        let target = vm.board.grid[0][3]
        if target.isRevealed && target.adjacentMines == 1 {
            let adjFlags = vm.board.neighbors(of: 0, 3).filter { vm.board.grid[$0.0][$0.1].isFlagged }.count
            if adjFlags == 1 {
                vm.tapCell(row: 0, col: 3) // chord reveal
                // The questioned mine at (0,4) is isCovered, so it gets revealed = boom
                #expect(vm.gameState == .lost)
            }
        }
    }
}

// MARK: - Flood Fill Overwrite Journeys

@Suite("Flood Fill Overwrite Journeys")
@MainActor
struct FloodFillOverwriteJourneyTests {

    @Test func wrongFlagOverwrittenByFloodFillDuringPlay() {
        let board = GameBoard(rows: 5, cols: 5, minePositions: [(4, 4)])
        let vm = GameViewModel(board: board)

        vm.flagCell(row: 1, col: 1) // incorrectly flag a safe cell
        #expect(vm.board.grid[1][1].isFlagged == true)

        vm.tapCell(row: 0, col: 0) // flood fill should overwrite the flag

        #expect(vm.board.grid[1][1].isRevealed == true)
        #expect(vm.board.grid[1][1].isFlagged == false)
    }

    @Test func correctFlagSurvivesFloodFill() {
        let board = GameBoard(rows: 5, cols: 5, minePositions: [(2, 2)])
        let vm = GameViewModel(board: board)

        vm.flagCell(row: 2, col: 2) // correctly flag the mine
        vm.tapCell(row: 0, col: 0) // flood fill

        #expect(vm.board.grid[2][2].isFlagged == true)
        #expect(vm.board.grid[2][2].isMine == true)
        #expect(vm.gameState != .lost)
    }

    @Test func wrongFlagOverwriteCanLeadToWin() {
        // 3x3, mine at (2,2). Flag (1,1) wrongly, then tap (0,0).
        // Flood fill should overwrite the flag and reveal all safe cells => win.
        let board = GameBoard(rows: 3, cols: 3, minePositions: [(2, 2)])
        let vm = GameViewModel(board: board)

        vm.flagCell(row: 1, col: 1) // wrong flag
        vm.tapCell(row: 0, col: 0) // should flood fill, overwrite flag, and win

        #expect(vm.gameState == .won)
        #expect(vm.board.grid[1][1].isRevealed == true)
    }
}

// MARK: - Wrong Flag End-of-Game Journeys

@Suite("Wrong Flag End-of-Game Journeys")
@MainActor
struct WrongFlagEndGameJourneyTests {

    @Test func wrongFlagsHighlightedOnLoss() {
        let board = GameBoard(rows: 5, cols: 5, minePositions: [(2, 2), (3, 3)])
        let vm = GameViewModel(board: board)

        vm.flagCell(row: 0, col: 0) // wrong flag
        vm.flagCell(row: 1, col: 1) // wrong flag
        vm.tapCell(row: 2, col: 2) // hit mine => lose

        #expect(vm.gameState == .lost)
        #expect(vm.board.grid[0][0].isFlagged == true)
        #expect(vm.board.grid[0][0].isWrongFlag == true)
        #expect(vm.board.grid[1][1].isFlagged == true)
        #expect(vm.board.grid[1][1].isWrongFlag == true)
    }

    @Test func correctFlagsNotMarkedWrongOnLoss() {
        let board = GameBoard(rows: 5, cols: 5, minePositions: [(2, 2), (3, 3)])
        let vm = GameViewModel(board: board)

        vm.flagCell(row: 2, col: 2) // correct flag
        vm.tapCell(row: 3, col: 3) // hit other mine => lose

        #expect(vm.gameState == .lost)
        #expect(vm.board.grid[2][2].isFlagged == true)
        #expect(vm.board.grid[2][2].isWrongFlag == false)
    }

    @Test func wrongFlagsClearedOnReset() {
        let board = GameBoard(rows: 5, cols: 5, minePositions: [(2, 2)])
        let vm = GameViewModel(board: board)

        vm.flagCell(row: 0, col: 0) // wrong flag
        vm.tapCell(row: 2, col: 2) // lose
        #expect(vm.board.grid[0][0].isWrongFlag == true)

        vm.reset()

        for row in vm.board.grid {
            for cell in row {
                #expect(cell.isWrongFlag == false)
                #expect(cell.state == .hidden)
            }
        }
    }

    @Test func noWrongFlagsOnCleanLoss() {
        let board = GameBoard(rows: 5, cols: 5, minePositions: [(2, 2)])
        let vm = GameViewModel(board: board)

        vm.tapCell(row: 2, col: 2) // lose without placing any flags

        for row in vm.board.grid {
            for cell in row {
                #expect(cell.isWrongFlag == false)
            }
        }
    }
}

// MARK: - Difficulty Switch Mid-Game

@Suite("Difficulty Switch Journeys")
@MainActor
struct DifficultySwitchJourneyTests {

    @Test func switchDifficultyMidGameResetsEverything() {
        let board = GameBoard(rows: 9, cols: 9, minePositions: [
            (0, 4), (1, 5), (2, 6), (3, 7), (4, 8),
            (5, 3), (6, 2), (7, 1), (8, 0), (8, 8)
        ])
        let vm = GameViewModel(difficulty: .easy, board: board)

        vm.tapCell(row: 0, col: 0)
        vm.flagCell(row: 4, col: 4)
        #expect(vm.gameState == .playing)

        vm.changeDifficulty(.medium)

        #expect(vm.gameState == .ready)
        #expect(vm.elapsedSeconds == 0)
        #expect(vm.board.rows == 16)
        #expect(vm.board.cols == 16)
        #expect(vm.board.flagCount == 0)

        for row in vm.board.grid {
            for cell in row {
                #expect(cell.state == .hidden)
            }
        }
    }

    @Test func switchDifficultyAfterLoss() {
        let board = GameBoard(rows: 5, cols: 5, minePositions: [(2, 2)])
        let vm = GameViewModel(board: board)

        vm.tapCell(row: 2, col: 2) // lose
        vm.changeDifficulty(.hard)

        #expect(vm.gameState == .ready)
        #expect(vm.board.rows == 16)
        #expect(vm.board.cols == 30)
    }

    @Test func switchDifficultyAfterWin() {
        let board = GameBoard(rows: 3, cols: 3, minePositions: [(2, 2)])
        let vm = GameViewModel(board: board)

        vm.tapCell(row: 0, col: 0) // win
        vm.changeDifficulty(.extreme)

        #expect(vm.gameState == .ready)
        #expect(vm.board.rows == 20)
        #expect(vm.board.cols == 30)
    }

    @Test func rapidDifficultySwitchPreservesIntegrity() {
        let vm = GameViewModel(difficulty: .easy)

        vm.changeDifficulty(.medium)
        vm.changeDifficulty(.hard)
        vm.changeDifficulty(.extreme)
        vm.changeDifficulty(.easy)

        #expect(vm.gameState == .ready)
        #expect(vm.board.rows == 9)
        #expect(vm.board.cols == 9)

        // Game still playable
        vm.tapCell(row: 4, col: 4)
        #expect(vm.gameState == .playing || vm.gameState == .won)
    }
}

// MARK: - Reset Mid-Game

@Suite("Reset Journeys")
@MainActor
struct ResetJourneyTests {

    @Test func resetMidGamePreservesDifficulty() {
        let vm = GameViewModel(difficulty: .medium)
        vm.tapCell(row: 0, col: 0) // start playing
        vm.reset()

        #expect(vm.gameState == .ready)
        #expect(vm.difficulty == .medium)
        #expect(vm.board.rows == 16)
        #expect(vm.board.cols == 16)
    }

    @Test func multipleResetsAreStable() {
        let vm = GameViewModel(difficulty: .easy)
        for _ in 0..<10 {
            vm.tapCell(row: 0, col: 0)
            vm.reset()
        }
        #expect(vm.gameState == .ready)
        #expect(vm.board.rows == 9)
    }

    @Test func resetWithFlagsAndQuestionsClearsAll() {
        let board = GameBoard(rows: 5, cols: 5, minePositions: [(4, 4)])
        let vm = GameViewModel(board: board)

        vm.flagCell(row: 0, col: 0) // flag
        vm.flagCell(row: 1, col: 1) // flag
        vm.flagCell(row: 1, col: 1) // question
        vm.tapCell(row: 2, col: 2) // reveal

        vm.reset()

        #expect(vm.board.flagCount == 0)
        for row in vm.board.grid {
            for cell in row {
                #expect(cell.state == .hidden)
            }
        }
    }
}
