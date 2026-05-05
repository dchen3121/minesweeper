import SwiftData
import SwiftUI

struct GameView: View {
    @Bindable var viewModel: GameViewModel
    @AppStorage("selectedSkinId") private var selectedSkinId = "classic"
    @Environment(\.modelContext) private var modelContext

    @State private var showDifficulty = false
    @State private var showStats = false
    @State private var showSkins = false
    @State private var hasRecordedResult = false

    private var skin: SkinTheme { SkinTheme.theme(for: selectedSkinId) }

    var body: some View {
        VStack(spacing: 12) {
            HeaderView(
                remainingMines: viewModel.remainingMines,
                elapsedSeconds: viewModel.elapsedSeconds,
                smileyFace: viewModel.smileyFace,
                onReset: {
                    hasRecordedResult = false
                    viewModel.reset()
                }
            )

            BoardView(viewModel: viewModel, skin: skin)

            difficultyLabel
        }
        .padding()
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    showDifficulty = true
                } label: {
                    Image(systemName: "slider.horizontal.3")
                }
            }
            ToolbarItemGroup(placement: .topBarTrailing) {
                Button {
                    showSkins = true
                } label: {
                    Image(systemName: "paintpalette")
                }
                Button {
                    showStats = true
                } label: {
                    Image(systemName: "chart.bar")
                }
            }
        }
        .sheet(isPresented: $showDifficulty) {
            DifficultyPickerView(
                currentDifficulty: viewModel.difficulty,
                onSelect: { difficulty in
                    viewModel.changeDifficulty(difficulty)
                    hasRecordedResult = false
                    showDifficulty = false
                }
            )
            .presentationDetents([.medium, .large])
        }
        .sheet(isPresented: $showStats) {
            StatsView()
                .presentationDetents([.large])
        }
        .sheet(isPresented: $showSkins) {
            SkinPickerView(selectedSkinId: $selectedSkinId)
                .presentationDetents([.height(280)])
        }
        .onChange(of: viewModel.gameState) { oldState, newState in
            if (newState == .won || newState == .lost) && !hasRecordedResult {
                hasRecordedResult = true
                let record = GameRecord(
                    difficulty: viewModel.difficulty.key,
                    rows: viewModel.difficulty.rows,
                    cols: viewModel.difficulty.cols,
                    mineCount: viewModel.difficulty.mines,
                    duration: TimeInterval(viewModel.elapsedSeconds),
                    won: newState == .won
                )
                modelContext.insert(record)
                try? modelContext.save()
            }
        }
    }

    private var difficultyLabel: some View {
        Text(viewModel.difficulty.label)
            .font(.caption)
            .foregroundStyle(.secondary)
            .padding(.horizontal, 12)
            .padding(.vertical, 4)
            .background(.ultraThinMaterial)
            .clipShape(Capsule())
    }
}
