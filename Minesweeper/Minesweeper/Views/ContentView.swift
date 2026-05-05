import SwiftUI

struct ContentView: View {
    @State private var viewModel = GameViewModel(difficulty: .easy)
    @AppStorage("selectedDifficultyKey") private var savedDifficultyKey = "easy"
    @AppStorage("customRows") private var customRows = 10
    @AppStorage("customCols") private var customCols = 10
    @AppStorage("customMines") private var customMines = 15

    var body: some View {
        NavigationStack {
            GameView(viewModel: viewModel)
                .navigationTitle("Minesweeper")
                .navigationBarTitleDisplayMode(.inline)
        }
        .onAppear {
            restoreDifficulty()
        }
        .onChange(of: viewModel.difficulty) { _, newValue in
            saveDifficulty(newValue)
        }
    }

    private func restoreDifficulty() {
        let difficulty: Difficulty
        switch savedDifficultyKey {
        case "easy": difficulty = .easy
        case "medium": difficulty = .medium
        case "hard": difficulty = .hard
        case "extreme": difficulty = .extreme
        case "custom": difficulty = .custom(rows: customRows, cols: customCols, mines: customMines)
        default: difficulty = .easy
        }
        if viewModel.difficulty != difficulty {
            viewModel.changeDifficulty(difficulty)
        }
    }

    private func saveDifficulty(_ difficulty: Difficulty) {
        savedDifficultyKey = difficulty.key
        if case .custom(let r, let c, let m) = difficulty {
            customRows = r
            customCols = c
            customMines = m
        }
    }
}
