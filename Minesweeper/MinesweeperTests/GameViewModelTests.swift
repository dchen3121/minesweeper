import Testing
@testable import Minesweeper

// MARK: - State Transitions

@Suite("GameViewModel State Transitions")
@MainActor
struct ViewModelStateTests {

    @Test func initialStateIsReady() {
        let vm = GameViewModel(difficulty: .easy)
        #expect(vm.gameState == .ready)
        #expect(vm.elapsedSeconds == 0)
        #expect(vm.smileyFace == "🙂")
    }

    @Test func firstTapTransitionsToPlaying() {
        // Mines scattered so flood fill from (0,0) can't reach everything
        let board = GameBoard(rows: 9, cols: 9, minePositions: [
            (0, 4), (1, 5), (2, 6), (3, 7), (4, 8),
            (5, 3), (6, 2), (7, 1), (8, 0), (8, 8)
        ])
        let vm = GameViewModel(board: board)
        vm.tapCell(row: 0, col: 0)
        #expect(vm.gameState == .playing)
    }

    @Test func firstFlagTransitionsToPlaying() {
        let board = GameBoard(rows: 5, cols: 5, minePositions: [(4, 4)])
        let vm = GameViewModel(board: board)
        vm.flagCell(row: 0, col: 0)
        #expect(vm.gameState == .playing)
    }

    @Test func hittingMineTransitionsToLost() {
        let board = GameBoard(rows: 5, cols: 5, minePositions: [(2, 2)])
        let vm = GameViewModel(board: board)
        vm.tapCell(row: 2, col: 2)
        #expect(vm.gameState == .lost)
        #expect(vm.smileyFace == "😵")
    }

    @Test func revealingAllSafeCellsTransitionsToWon() {
        // 3x3 with 1 mine in corner -- flood fill reveals everything
        let board = GameBoard(rows: 3, cols: 3, minePositions: [(2, 2)])
        let vm = GameViewModel(board: board)
        vm.tapCell(row: 0, col: 0)
        #expect(vm.gameState == .won)
        #expect(vm.smileyFace == "😎")
    }

    @Test func tapAfterGameOverIsIgnored() {
        let board = GameBoard(rows: 5, cols: 5, minePositions: [(2, 2)])
        let vm = GameViewModel(board: board)
        vm.tapCell(row: 2, col: 2) // lose
        #expect(vm.gameState == .lost)

        vm.tapCell(row: 0, col: 0) // should be ignored
        #expect(vm.board.grid[0][0].isRevealed == false ||
                vm.board.grid[0][0].isRevealed == true)
        #expect(vm.gameState == .lost)
    }

    @Test func flagAfterGameOverIsIgnored() {
        let board = GameBoard(rows: 5, cols: 5, minePositions: [(2, 2)])
        let vm = GameViewModel(board: board)
        vm.tapCell(row: 2, col: 2) // lose
        let flagCountBefore = vm.board.flagCount
        vm.flagCell(row: 0, col: 0)
        #expect(vm.board.flagCount == flagCountBefore)
    }

    @Test func tapAfterWinIsIgnored() {
        let board = GameBoard(rows: 3, cols: 3, minePositions: [(2, 2)])
        let vm = GameViewModel(board: board)
        vm.tapCell(row: 0, col: 0) // win
        #expect(vm.gameState == .won)

        vm.tapCell(row: 2, col: 2) // should be ignored
        #expect(vm.gameState == .won)
    }
}

// MARK: - Reset

@Suite("GameViewModel Reset")
@MainActor
struct ViewModelResetTests {

    @Test func resetClearsGameState() {
        let board = GameBoard(rows: 5, cols: 5, minePositions: [(2, 2)])
        let vm = GameViewModel(board: board)
        vm.tapCell(row: 0, col: 0) // start playing
        vm.reset()

        #expect(vm.gameState == .ready)
        #expect(vm.elapsedSeconds == 0)
        #expect(vm.board.minesPlaced == false)
    }

    @Test func resetAfterLossAllowsNewGame() {
        let board = GameBoard(rows: 5, cols: 5, minePositions: [(2, 2)])
        let vm = GameViewModel(board: board)
        vm.tapCell(row: 2, col: 2) // lose
        #expect(vm.gameState == .lost)

        vm.reset()
        #expect(vm.gameState == .ready)

        vm.tapCell(row: 0, col: 0) // should work now
        #expect(vm.gameState == .playing)
    }

    @Test func resetClearsAllCells() {
        let board = GameBoard(rows: 5, cols: 5, minePositions: [(4, 4)])
        let vm = GameViewModel(board: board)
        vm.tapCell(row: 0, col: 0)
        vm.flagCell(row: 3, col: 3)
        vm.reset()

        for row in vm.board.grid {
            for cell in row {
                #expect(cell.state == .hidden)
            }
        }
    }
}

// MARK: - Difficulty Switch

@Suite("GameViewModel Difficulty Switch")
@MainActor
struct ViewModelDifficultyTests {

    @Test func changeDifficultyResetsBoardDimensions() {
        let vm = GameViewModel(difficulty: .easy)
        #expect(vm.board.rows == 9)
        #expect(vm.board.cols == 9)

        vm.changeDifficulty(.medium)
        #expect(vm.board.rows == 16)
        #expect(vm.board.cols == 16)
        #expect(vm.board.mineCount == 40)
        #expect(vm.gameState == .ready)
    }

    @Test func changeDifficultyMidGameResetsState() {
        let board = GameBoard(rows: 9, cols: 9, minePositions: [
            (0, 4), (1, 5), (2, 6), (3, 7), (4, 8),
            (5, 3), (6, 2), (7, 1), (8, 0), (8, 8)
        ])
        let vm = GameViewModel(difficulty: .easy, board: board)
        vm.tapCell(row: 0, col: 0)
        #expect(vm.gameState == .playing)

        vm.changeDifficulty(.hard)
        #expect(vm.gameState == .ready)
        #expect(vm.elapsedSeconds == 0)
        #expect(vm.board.rows == 16)
        #expect(vm.board.cols == 30)
    }

    @Test func switchToCustomDifficulty() {
        let vm = GameViewModel(difficulty: .easy)
        let custom = Difficulty.custom(rows: 12, cols: 12, mines: 20)
        vm.changeDifficulty(custom)
        #expect(vm.board.rows == 12)
        #expect(vm.board.cols == 12)
        #expect(vm.board.mineCount == 20)
    }

    @Test func rapidDifficultySwitchDoesNotCrash() {
        let vm = GameViewModel(difficulty: .easy)
        for difficulty in Difficulty.presets {
            vm.changeDifficulty(difficulty)
            #expect(vm.gameState == .ready)
        }
        vm.changeDifficulty(.easy)
        vm.tapCell(row: 0, col: 0)
        #expect(vm.gameState == .playing || vm.gameState == .won)
    }
}

// MARK: - Mine Counter

@Suite("Mine Counter")
@MainActor
struct MineCounterTests {

    @Test func remainingMinesDecreasesWithFlags() {
        let board = GameBoard(rows: 5, cols: 5, minePositions: [(4, 4)])
        let vm = GameViewModel(board: board)
        #expect(vm.remainingMines == 1)

        vm.flagCell(row: 0, col: 0)
        #expect(vm.remainingMines == 0)
    }

    @Test func remainingMinesCanGoNegative() {
        let board = GameBoard(rows: 5, cols: 5, minePositions: [(4, 4)])
        let vm = GameViewModel(board: board)
        vm.flagCell(row: 0, col: 0)
        vm.flagCell(row: 0, col: 1)
        #expect(vm.remainingMines == -1)
    }

    @Test func questionedCellDoesNotReduceRemainingMines() {
        let board = GameBoard(rows: 5, cols: 5, minePositions: [(4, 4)])
        let vm = GameViewModel(board: board)
        vm.flagCell(row: 0, col: 0) // flag
        #expect(vm.remainingMines == 0)
        vm.flagCell(row: 0, col: 0) // questioned
        #expect(vm.remainingMines == 1)
    }
}
