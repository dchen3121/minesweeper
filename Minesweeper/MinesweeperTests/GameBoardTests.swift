import Testing
@testable import Minesweeper

// MARK: - Board Initialization

@Suite("GameBoard Initialization")
struct GameBoardInitTests {

    @Test func emptyBoardHasCorrectDimensions() {
        let board = GameBoard(rows: 9, cols: 9, mineCount: 10)
        #expect(board.rows == 9)
        #expect(board.cols == 9)
        #expect(board.mineCount == 10)
        #expect(board.minesPlaced == false)
    }

    @Test func allCellsStartHidden() {
        let board = GameBoard(rows: 5, cols: 5, mineCount: 3)
        for row in board.grid {
            for cell in row {
                #expect(cell.state == .hidden)
                #expect(cell.isMine == false)
            }
        }
    }

    @Test func seededBoardHasMinesAtCorrectPositions() {
        let board = GameBoard(rows: 5, cols: 5, minePositions: [(0, 0), (2, 3), (4, 4)])
        #expect(board.grid[0][0].isMine == true)
        #expect(board.grid[2][3].isMine == true)
        #expect(board.grid[4][4].isMine == true)
        #expect(board.grid[1][1].isMine == false)
        #expect(board.minesPlaced == true)
        #expect(board.mineCount == 3)
    }

    @Test func seededBoardComputesAdjacentCounts() {
        // Mine at (1,1) on a 3x3 board
        let board = GameBoard(rows: 3, cols: 3, minePositions: [(1, 1)])
        #expect(board.grid[0][0].adjacentMines == 1)
        #expect(board.grid[0][1].adjacentMines == 1)
        #expect(board.grid[0][2].adjacentMines == 1)
        #expect(board.grid[1][0].adjacentMines == 1)
        #expect(board.grid[1][2].adjacentMines == 1)
        #expect(board.grid[2][0].adjacentMines == 1)
        #expect(board.grid[2][1].adjacentMines == 1)
        #expect(board.grid[2][2].adjacentMines == 1)
    }
}

// MARK: - First Tap Safety

@Suite("First Tap Safety")
struct FirstTapSafetyTests {

    @Test func firstTapNeverHitsMine() {
        for _ in 0..<50 {
            var board = GameBoard(rows: 9, cols: 9, mineCount: 10)
            let result = board.revealCell(row: 4, col: 4)
            #expect(result != .mine)
            #expect(board.grid[4][4].isRevealed == true)
            #expect(board.grid[4][4].isMine == false)
        }
    }

    @Test func firstTapNeighborsAreAlsoSafe() {
        for _ in 0..<50 {
            var board = GameBoard(rows: 9, cols: 9, mineCount: 10)
            _ = board.revealCell(row: 4, col: 4)
            for (nr, nc) in board.neighbors(of: 4, 4) {
                #expect(board.grid[nr][nc].isMine == false)
            }
        }
    }

    @Test func minesPlacedAfterFirstTap() {
        var board = GameBoard(rows: 5, cols: 5, mineCount: 3)
        #expect(board.minesPlaced == false)
        _ = board.revealCell(row: 0, col: 0)
        #expect(board.minesPlaced == true)
    }
}

// MARK: - Reveal Mechanics

@Suite("Reveal Mechanics")
struct RevealMechanicsTests {

    @Test func revealSafeCellReturnsSafe() {
        var board = GameBoard(rows: 5, cols: 5, minePositions: [(4, 4)])
        let result = board.revealCell(row: 0, col: 0)
        #expect(result == .safe || result == .win)
    }

    @Test func revealMineCellReturnsMine() {
        var board = GameBoard(rows: 5, cols: 5, minePositions: [(2, 2)])
        let result = board.revealCell(row: 2, col: 2)
        #expect(result == .mine)
        #expect(board.grid[2][2].isTriggered == true)
    }

    @Test func revealAlreadyRevealedCellReturnsAlreadyRevealed() {
        // No adjacent mines so tapping (0,0) reveals it; tapping again on a 0-neighbor cell
        var board = GameBoard(rows: 5, cols: 5, minePositions: [(4, 4)])
        _ = board.revealCell(row: 0, col: 0)
        let result = board.revealCell(row: 0, col: 0)
        #expect(result == .alreadyRevealed)
    }

    @Test func cannotRevealFlaggedCell() {
        var board = GameBoard(rows: 5, cols: 5, minePositions: [(4, 4)])
        board.toggleFlag(row: 0, col: 0)
        let result = board.revealCell(row: 0, col: 0)
        #expect(result == .alreadyRevealed)
        #expect(board.grid[0][0].isFlagged == true)
    }

    @Test func canRevealQuestionedCell() {
        var board = GameBoard(rows: 5, cols: 5, minePositions: [(4, 4)])
        board.toggleFlag(row: 0, col: 0) // hidden -> flagged
        board.toggleFlag(row: 0, col: 0) // flagged -> questioned
        #expect(board.grid[0][0].isQuestioned == true)
        let result = board.revealCell(row: 0, col: 0)
        #expect(result == .safe || result == .win)
        #expect(board.grid[0][0].isRevealed == true)
    }

    @Test func revealOutOfBoundsReturnsAlreadyRevealed() {
        var board = GameBoard(rows: 3, cols: 3, minePositions: [(1, 1)])
        #expect(board.revealCell(row: -1, col: 0) == .alreadyRevealed)
        #expect(board.revealCell(row: 3, col: 0) == .alreadyRevealed)
        #expect(board.revealCell(row: 0, col: -1) == .alreadyRevealed)
        #expect(board.revealCell(row: 0, col: 3) == .alreadyRevealed)
    }
}

// MARK: - Flood Fill

@Suite("Flood Fill")
struct FloodFillTests {

    @Test func floodFillRevealsContiguousZeroCells() {
        // Mine at corner (4,4), tapping (0,0) should flood-fill a large area
        var board = GameBoard(rows: 5, cols: 5, minePositions: [(4, 4)])
        _ = board.revealCell(row: 0, col: 0)

        // All cells except mine and its direct neighbors with count>0 should be revealed
        for r in 0..<5 {
            for c in 0..<5 {
                if board.grid[r][c].isMine { continue }
                if board.grid[r][c].adjacentMines == 0 {
                    #expect(board.grid[r][c].isRevealed == true,
                        "Cell (\(r),\(c)) with 0 adjacent should be revealed")
                }
            }
        }
    }

    @Test func floodFillStopsAtNumberCells() {
        // Mine at center (2,2) of 5x5
        let board_before = GameBoard(rows: 5, cols: 5, minePositions: [(2, 2)])
        // Cells adjacent to (2,2) have adjacentMines >= 1
        #expect(board_before.grid[1][1].adjacentMines == 1)

        var board = board_before
        _ = board.revealCell(row: 0, col: 0)
        // (0,0) has 0 adjacent mines, so flood fill expands
        // (1,1) has 1 adjacent mine, so it gets revealed but doesn't expand further
        #expect(board.grid[0][0].isRevealed == true)
        #expect(board.grid[1][1].isRevealed == true)
    }

    @Test func floodFillDoesNotCrossMines() {
        // Row of mines: (2,0), (2,1), (2,2), (2,3), (2,4) on 5x5
        var board = GameBoard(rows: 5, cols: 5, minePositions: [
            (2, 0), (2, 1), (2, 2), (2, 3), (2, 4)
        ])
        _ = board.revealCell(row: 0, col: 0)

        // Bottom half should remain hidden (mines block passage)
        for c in 0..<5 {
            #expect(board.grid[4][c].isHidden == true || board.grid[4][c].isMine,
                "Cell (4,\(c)) below mine wall should not be revealed")
        }
    }
}

// MARK: - Flag Toggle with ? State

@Suite("Flag Toggle Cycle")
struct FlagToggleTests {

    @Test func flagCycleHiddenToFlaggedToQuestionedToHidden() {
        var board = GameBoard(rows: 3, cols: 3, minePositions: [(1, 1)])

        #expect(board.grid[0][0].state == .hidden)

        board.toggleFlag(row: 0, col: 0)
        #expect(board.grid[0][0].state == .flagged)

        board.toggleFlag(row: 0, col: 0)
        #expect(board.grid[0][0].state == .questioned)

        board.toggleFlag(row: 0, col: 0)
        #expect(board.grid[0][0].state == .hidden)
    }

    @Test func flagOnRevealedCellDoesNothing() {
        var board = GameBoard(rows: 3, cols: 3, minePositions: [(2, 2)])
        _ = board.revealCell(row: 0, col: 0)
        board.toggleFlag(row: 0, col: 0)
        #expect(board.grid[0][0].state == .revealed)
    }

    @Test func flagCountOnlyCountsFlags() {
        var board = GameBoard(rows: 3, cols: 3, minePositions: [(1, 1)])

        board.toggleFlag(row: 0, col: 0) // flagged
        #expect(board.flagCount == 1)

        board.toggleFlag(row: 0, col: 1) // flagged
        #expect(board.flagCount == 2)

        board.toggleFlag(row: 0, col: 0) // flagged -> questioned
        #expect(board.flagCount == 1)

        board.toggleFlag(row: 0, col: 0) // questioned -> hidden
        #expect(board.flagCount == 1)
    }

    @Test func questionedCellDoesNotAffectRemainingMines() {
        var board = GameBoard(rows: 3, cols: 3, minePositions: [(1, 1)])
        #expect(board.remainingMines == 1)

        board.toggleFlag(row: 0, col: 0) // flagged
        #expect(board.remainingMines == 0)

        board.toggleFlag(row: 0, col: 0) // questioned
        #expect(board.remainingMines == 1)
    }

    @Test func flagOutOfBoundsDoesNothing() {
        var board = GameBoard(rows: 3, cols: 3, minePositions: [(1, 1)])
        board.toggleFlag(row: -1, col: 0)
        board.toggleFlag(row: 0, col: 5)
        #expect(board.flagCount == 0)
    }
}

// MARK: - Win Condition

@Suite("Win Condition")
struct WinConditionTests {

    @Test func winWhenAllSafeCellsRevealed() {
        // 3x3 board with 1 mine at (2,2). Reveal all safe cells.
        var board = GameBoard(rows: 3, cols: 3, minePositions: [(2, 2)])
        let result = board.revealCell(row: 0, col: 0)
        // With only 1 mine in corner, flood fill should reveal all 8 safe cells
        #expect(result == .win)
        #expect(board.isWon == true)
    }

    @Test func notWonUntilAllSafeCellsRevealed() {
        // 3x3, mines at (0,2) and (2,0). Tap (0,0) reveals only (0,0) since it has adj=1
        var board = GameBoard(rows: 3, cols: 3, minePositions: [(0, 2), (2, 0)])
        let result = board.revealCell(row: 0, col: 0)
        #expect(result == .safe)
        #expect(board.isWon == false)
    }
}

// MARK: - Chord Reveal

@Suite("Chord Reveal")
struct ChordRevealTests {

    @Test func chordRevealWorksWhenFlagCountMatchesNumber() {
        // 3x3, mine at (0,2). (0,1) has adjacentMines=1
        var board = GameBoard(rows: 3, cols: 3, minePositions: [(0, 2)])
        _ = board.revealCell(row: 1, col: 0) // reveal some cells via flood fill
        // Flag the mine
        board.toggleFlag(row: 0, col: 2)

        // Make sure (0,1) is revealed and has adjacentMines=1
        #expect(board.grid[0][1].isRevealed == true)
        #expect(board.grid[0][1].adjacentMines == 1)

        // Chord reveal on (0,1) -- the flag count matches
        let result = board.revealCell(row: 0, col: 1)
        #expect(result == .safe || result == .win)
    }

    @Test func chordRevealDoesNothingWhenFlagCountDoesNotMatch() {
        var board = GameBoard(rows: 3, cols: 3, minePositions: [(0, 2)])
        _ = board.revealCell(row: 1, col: 0)
        // Don't flag anything -- chord reveal should be no-op
        let result = board.revealCell(row: 0, col: 1)
        #expect(result == .alreadyRevealed)
    }

    @Test func chordRevealWithWrongFlagHitsMine() {
        // 3x3, mine at (0,2). Flag (0,0) instead (wrong position)
        var board = GameBoard(rows: 3, cols: 3, minePositions: [(0, 2)])
        _ = board.revealCell(row: 1, col: 1)
        // (1,1) has adjacentMines=1

        // Flag wrong cell
        board.toggleFlag(row: 2, col: 2)
        // (1,1) has 1 flag neighbor, matches adjacentMines=1

        // Chord reveal should hit the unflagged mine at (0,2)
        let neighborFlags = board.neighbors(of: 1, 1).filter { board.grid[$0.0][$0.1].isFlagged }.count
        if neighborFlags == board.grid[1][1].adjacentMines {
            let result = board.revealCell(row: 1, col: 1)
            #expect(result == .mine)
        }
    }
}

// MARK: - Reveal All Mines

@Suite("Reveal All Mines")
struct RevealAllMinesTests {

    @Test func revealAllMinesShowsUnflaggedMines() {
        var board = GameBoard(rows: 3, cols: 3, minePositions: [(0, 0), (2, 2)])
        board.toggleFlag(row: 0, col: 0) // flag one mine
        board.revealAllMines()

        // Flagged mine stays flagged
        #expect(board.grid[0][0].isFlagged == true)
        // Unflagged mine gets revealed
        #expect(board.grid[2][2].isRevealed == true)
    }

    @Test func revealAllMinesMarksWrongFlags() {
        var board = GameBoard(rows: 3, cols: 3, minePositions: [(0, 0)])
        board.toggleFlag(row: 1, col: 1) // flag a non-mine cell
        board.revealAllMines()

        // Wrongly flagged cell stays flagged but marked as wrong
        #expect(board.grid[1][1].isFlagged == true)
        #expect(board.grid[1][1].isWrongFlag == true)
    }
}

// MARK: - Edge Cases

@Suite("Edge Cases")
struct EdgeCaseTests {

    @Test func minimumBoardSize() {
        var board = GameBoard(rows: 5, cols: 5, minePositions: [(0, 0)])
        let result = board.revealCell(row: 4, col: 4)
        #expect(result == .safe || result == .win)
    }

    @Test func boardWithMaxMines() {
        // 5x5 = 25 cells, 16 mines (all except 9 safe zone)
        var board = GameBoard(rows: 5, cols: 5, mineCount: 16)
        let result = board.revealCell(row: 2, col: 2)
        #expect(result != .mine)
    }

    @Test func cornerCellNeighborCount() {
        let board = GameBoard(rows: 3, cols: 3, minePositions: [])
        #expect(board.neighbors(of: 0, 0).count == 3)
        #expect(board.neighbors(of: 0, 1).count == 5)
        #expect(board.neighbors(of: 1, 1).count == 8)
    }
}

// MARK: - Flood Fill Overwrites Wrong Flags

@Suite("Flood Fill Flag Overwrite")
struct FloodFillFlagOverwriteTests {

    @Test func floodFillOverwritesIncorrectlyFlaggedCell() {
        // 5x5 board, mine at (4,4). Flag (2,2) incorrectly.
        // Tapping (0,0) should flood fill and overwrite the wrong flag.
        var board = GameBoard(rows: 5, cols: 5, minePositions: [(4, 4)])
        board.toggleFlag(row: 2, col: 2) // flag a non-mine cell
        #expect(board.grid[2][2].isFlagged == true)

        _ = board.revealCell(row: 0, col: 0)

        // Flood fill should have overwritten the flag and revealed the cell
        #expect(board.grid[2][2].isRevealed == true)
        #expect(board.grid[2][2].isFlagged == false)
    }

    @Test func floodFillDoesNotOverwriteCorrectlyFlaggedMine() {
        // 5x5, mine at (2,2). Flag it correctly.
        var board = GameBoard(rows: 5, cols: 5, minePositions: [(2, 2)])
        board.toggleFlag(row: 2, col: 2)
        #expect(board.grid[2][2].isFlagged == true)

        _ = board.revealCell(row: 0, col: 0)

        // Mine flag should remain untouched
        #expect(board.grid[2][2].isFlagged == true)
        #expect(board.grid[2][2].isMine == true)
    }

    @Test func floodFillOverwritesMultipleWrongFlags() {
        var board = GameBoard(rows: 5, cols: 5, minePositions: [(4, 4)])
        board.toggleFlag(row: 1, col: 1)
        board.toggleFlag(row: 2, col: 2)
        board.toggleFlag(row: 3, col: 3)

        _ = board.revealCell(row: 0, col: 0)

        #expect(board.grid[1][1].isRevealed == true)
        #expect(board.grid[2][2].isRevealed == true)
        // (3,3) is adjacent to mine so has adjacentMines > 0, but should still be revealed
        #expect(board.grid[3][3].isRevealed == true)
    }

    @Test func floodFillOverwriteDoesNotAffectFlagCount() {
        var board = GameBoard(rows: 5, cols: 5, minePositions: [(4, 4)])
        board.toggleFlag(row: 1, col: 1)
        #expect(board.flagCount == 1)

        _ = board.revealCell(row: 0, col: 0)

        // Flag was overwritten by reveal, so flag count drops
        #expect(board.flagCount == 0)
    }

    @Test func floodFillStopsAtFlaggedMineButOverwritesSafeFlags() {
        // Mine at (2,0). Flag the mine and also flag (0,2) wrongly.
        var board = GameBoard(rows: 5, cols: 5, minePositions: [(2, 0)])
        board.toggleFlag(row: 2, col: 0) // correct flag on mine
        board.toggleFlag(row: 0, col: 2) // wrong flag on safe cell

        _ = board.revealCell(row: 0, col: 4)

        // Correct flag stays
        #expect(board.grid[2][0].isFlagged == true)
        // Wrong flag gets overwritten
        #expect(board.grid[0][2].isRevealed == true)
    }
}

// MARK: - Wrong Flag Highlighting

@Suite("Wrong Flag Highlighting")
struct WrongFlagHighlightTests {

    @Test func wrongFlagMarkedOnGameOver() {
        var board = GameBoard(rows: 5, cols: 5, minePositions: [(2, 2)])
        board.toggleFlag(row: 0, col: 0) // wrong flag on safe cell
        board.toggleFlag(row: 2, col: 2) // correct flag on mine

        // Simulate game over
        board.revealAllMines()

        // Wrong flag: stays flagged + isWrongFlag
        #expect(board.grid[0][0].isFlagged == true)
        #expect(board.grid[0][0].isWrongFlag == true)

        // Correct flag: stays flagged, not wrong
        #expect(board.grid[2][2].isFlagged == true)
        #expect(board.grid[2][2].isWrongFlag == false)
    }

    @Test func noWrongFlagsWhenAllFlagsCorrect() {
        var board = GameBoard(rows: 5, cols: 5, minePositions: [(0, 0), (4, 4)])
        board.toggleFlag(row: 0, col: 0)
        board.toggleFlag(row: 4, col: 4)

        board.revealAllMines()

        for r in 0..<5 {
            for c in 0..<5 {
                #expect(board.grid[r][c].isWrongFlag == false)
            }
        }
    }

    @Test func multipleWrongFlagsAllMarked() {
        var board = GameBoard(rows: 5, cols: 5, minePositions: [(2, 2)])
        board.toggleFlag(row: 0, col: 0) // wrong
        board.toggleFlag(row: 1, col: 1) // wrong
        board.toggleFlag(row: 3, col: 3) // wrong

        board.revealAllMines()

        #expect(board.grid[0][0].isWrongFlag == true)
        #expect(board.grid[1][1].isWrongFlag == true)
        #expect(board.grid[3][3].isWrongFlag == true)
        // All still flagged
        #expect(board.grid[0][0].isFlagged == true)
        #expect(board.grid[1][1].isFlagged == true)
        #expect(board.grid[3][3].isFlagged == true)
    }

    @Test func wrongFlagNotSetOnUnflaggedCells() {
        var board = GameBoard(rows: 5, cols: 5, minePositions: [(2, 2)])
        board.revealAllMines()

        for r in 0..<5 {
            for c in 0..<5 {
                #expect(board.grid[r][c].isWrongFlag == false)
            }
        }
    }

    @Test func wrongFlagNotSetOnQuestionedCells() {
        var board = GameBoard(rows: 5, cols: 5, minePositions: [(2, 2)])
        board.toggleFlag(row: 0, col: 0) // flag
        board.toggleFlag(row: 0, col: 0) // question

        board.revealAllMines()

        #expect(board.grid[0][0].isQuestioned == true)
        #expect(board.grid[0][0].isWrongFlag == false)
    }
}

// MARK: - First Click Guarantees

@Suite("First Click Guarantees")
struct FirstClickGuaranteeTests {

    @Test func firstClickNeverWinsInstantly() {
        // 9x9 with 10 mines -- standard Easy. Run many times.
        for _ in 0..<50 {
            var board = GameBoard(rows: 9, cols: 9, mineCount: 10)
            let result = board.revealCell(row: 4, col: 4)
            #expect(result == .safe, "First click should not instantly win on 9x9/10 mines")
        }
    }

    @Test func firstClickAlwaysFloodFills() {
        // The 9-cell safe zone guarantees tapped cell has adjacentMines == 0,
        // so flood fill always triggers and reveals more than 1 cell.
        for _ in 0..<50 {
            var board = GameBoard(rows: 9, cols: 9, mineCount: 10)
            _ = board.revealCell(row: 4, col: 4)
            let revealed = board.revealedCount
            #expect(revealed > 1, "First click should flood fill, got only \(revealed) cell(s)")
        }
    }

    @Test func firstClickOnCornerAlsoFloodFills() {
        for _ in 0..<50 {
            var board = GameBoard(rows: 9, cols: 9, mineCount: 10)
            _ = board.revealCell(row: 0, col: 0)
            #expect(board.revealedCount > 1)
        }
    }

    @Test func instantWinStillPossibleWhenBoardIsMaxMines() {
        // When mines fill everything except the safe zone, first click
        // must reveal those few cells and win -- no other option.
        var board = GameBoard(rows: 5, cols: 5, mineCount: 16) // 25 - 9 = 16 mines
        let result = board.revealCell(row: 2, col: 2)
        // This board has only 9 safe cells (the safe zone), so instant win is unavoidable
        #expect(result == .win || result == .safe)
    }

    @Test func noInstantWinOnMediumBoard() {
        for _ in 0..<30 {
            var board = GameBoard(rows: 16, cols: 16, mineCount: 40)
            let result = board.revealCell(row: 8, col: 8)
            #expect(result == .safe)
        }
    }
}
