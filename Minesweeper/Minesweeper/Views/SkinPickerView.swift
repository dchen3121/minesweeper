import SwiftUI

struct SkinPickerView: View {
    @Binding var selectedSkinId: String
    @Environment(\.dismiss) private var dismiss

    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 16) {
                    ForEach(SkinTheme.allThemes) { theme in
                        SkinPreviewCard(
                            theme: theme,
                            isSelected: selectedSkinId == theme.id,
                            onSelect: {
                                selectedSkinId = theme.id
                            }
                        )
                    }
                }
                .padding()
            }
            .navigationTitle("Themes")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

private struct SkinPreviewCard: View {
    let theme: SkinTheme
    let isSelected: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            VStack(spacing: 8) {
                previewGrid
                    .frame(height: 100)
                    .clipShape(RoundedRectangle(cornerRadius: 8))

                Text(theme.name)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.primary)
            }
            .padding(8)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemBackground))
                    .shadow(color: .black.opacity(0.1), radius: 4, y: 2)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(
                        isSelected ? Color.accentColor : Color.clear,
                        lineWidth: 2.5
                    )
            )
        }
        .buttonStyle(.plain)
    }

    private var previewGrid: some View {
        let previewCells: [(CellState, Bool, Int, Bool)] = [
            (.hidden, false, 0, false),
            (.hidden, false, 0, false),
            (.revealed, false, 1, false),
            (.flagged, false, 0, false),
            (.revealed, false, 2, false),
            (.revealed, false, 0, false),
            (.revealed, false, 3, false),
            (.hidden, false, 0, false),
            (.revealed, true, 0, true),
        ]

        return VStack(spacing: 2) {
            ForEach(0..<3, id: \.self) { row in
                HStack(spacing: 2) {
                    ForEach(0..<3, id: \.self) { col in
                        let idx = row * 3 + col
                        let (state, isMine, adjacent, triggered) = previewCells[idx]
                        let cell = Cell(
                            row: row,
                            col: col,
                            isMine: isMine,
                            state: state,
                            adjacentMines: adjacent,
                            isTriggered: triggered
                        )
                        CellView(
                            cell: cell,
                            size: 28,
                            skin: theme,
                            onTap: {},
                            onLongPress: {}
                        )
                    }
                }
            }
        }
        .padding(4)
        .background(theme.backgroundColor)
        .allowsHitTesting(false)
    }
}
