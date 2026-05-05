import SwiftUI

struct DifficultyPickerView: View {
    let currentDifficulty: Difficulty
    let onSelect: (Difficulty) -> Void

    @State private var customRows: Double = 10
    @State private var customCols: Double = 10
    @State private var customMines: Double = 15
    @State private var showCustom = false

    var body: some View {
        NavigationStack {
            List {
                Section("Presets") {
                    ForEach(Difficulty.presets, id: \.self) { difficulty in
                        presetRow(difficulty)
                    }
                }

                Section("Custom") {
                    if showCustom {
                        customControls
                    } else {
                        Button("Configure Custom Game") {
                            withAnimation { showCustom = true }
                        }
                    }
                }
            }
            .navigationTitle("Difficulty")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private func presetRow(_ difficulty: Difficulty) -> some View {
        Button {
            onSelect(difficulty)
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(difficulty.label)
                        .font(.headline)
                    Text("\(difficulty.rows) x \(difficulty.cols) \u{2022} \(difficulty.mines) mines")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                if currentDifficulty == difficulty {
                    Image(systemName: "checkmark")
                        .foregroundStyle(.blue)
                }
            }
        }
        .foregroundStyle(.primary)
    }

    private var maxMines: Int {
        let r = Int(customRows)
        let c = Int(customCols)
        return max(1, r * c - 9)
    }

    private var customControls: some View {
        Group {
            VStack(alignment: .leading) {
                Text("Rows: \(Int(customRows))")
                    .font(.subheadline)
                Slider(value: $customRows, in: 5...30, step: 1)
            }

            VStack(alignment: .leading) {
                Text("Columns: \(Int(customCols))")
                    .font(.subheadline)
                Slider(value: $customCols, in: 5...30, step: 1)
            }

            VStack(alignment: .leading) {
                Text("Mines: \(Int(customMines))")
                    .font(.subheadline)
                Slider(value: $customMines, in: 1...Double(maxMines), step: 1)
            }
            .onChange(of: customRows) { _, _ in clampMines() }
            .onChange(of: customCols) { _, _ in clampMines() }

            Button {
                let difficulty = Difficulty.validated(
                    rows: Int(customRows),
                    cols: Int(customCols),
                    mines: Int(customMines)
                )
                onSelect(difficulty)
            } label: {
                Text("Start Custom Game")
                    .frame(maxWidth: .infinity)
                    .font(.headline)
            }
            .buttonStyle(.borderedProminent)
            .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
        }
    }

    private func clampMines() {
        if customMines > Double(maxMines) {
            customMines = Double(maxMines)
        }
    }
}
