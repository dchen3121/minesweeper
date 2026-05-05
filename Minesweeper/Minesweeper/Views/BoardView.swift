import SwiftUI

struct BoardView: View {
    @Bindable var viewModel: GameViewModel
    let skin: SkinTheme

    @State private var currentZoom: CGFloat = 1.0
    @State private var lastZoom: CGFloat = 1.0

    private var cellSize: CGFloat {
        let grid = viewModel.board.grid
        let rows = grid.count
        let cols = grid.first?.count ?? 0
        let maxDimension = max(cols, rows)
        switch maxDimension {
        case 0...9: return 36
        case 10...16: return 30
        case 17...24: return 26
        default: return 22
        }
    }

    private var needsScrolling: Bool {
        let grid = viewModel.board.grid
        let rows = grid.count
        let cols = grid.first?.count ?? 0
        return cols > 12 || rows > 16
    }

    var body: some View {
        let grid = viewModel.board.grid
        let totalZoom = max(0.5, min(currentZoom * lastZoom, 3.0))
        let size = cellSize * totalZoom
        let spacing: CGFloat = 1.5 * totalZoom

        ScrollView([.horizontal, .vertical], showsIndicators: false) {
            VStack(spacing: spacing) {
                ForEach(grid.indices, id: \.self) { row in
                    HStack(spacing: spacing) {
                        ForEach(grid[row].indices, id: \.self) { col in
                            let cell = grid[row][col]
                            CellView(
                                cell: cell,
                                size: size,
                                skin: skin,
                                onTap: { viewModel.tapCell(row: row, col: col) },
                                onLongPress: { viewModel.flagCell(row: row, col: col) }
                            )
                        }
                    }
                }
            }
            .padding(4)
        }
        .scrollDisabled(totalZoom <= 1.0 && !needsScrolling)
        .simultaneousGesture(
            MagnifyGesture()
                .onChanged { value in
                    currentZoom = value.magnification
                }
                .onEnded { value in
                    lastZoom *= value.magnification
                    lastZoom = max(0.5, min(lastZoom, 3.0))
                    currentZoom = 1.0
                }
        )
        .background(skin.backgroundColor)
        .clipShape(RoundedRectangle(cornerRadius: 4))
        .animation(.easeInOut(duration: 0.15), value: totalZoom)
        .id(viewModel.difficulty)
    }
}
