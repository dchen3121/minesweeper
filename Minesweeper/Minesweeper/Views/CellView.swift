import SwiftUI

struct CellView: View {
    let cell: Cell
    let size: CGFloat
    let skin: SkinTheme
    let onTap: () -> Void
    let onLongPress: () -> Void

    @GestureState private var isDetectingPress = false
    @State private var longPressFired = false

    private let holdThreshold: TimeInterval = 0.3

    var body: some View {
        ZStack {
            cellBackground
            cellContent
        }
        .frame(width: size, height: size)
        .contentShape(Rectangle())
        .gesture(
            DragGesture(minimumDistance: 0)
                .updating($isDetectingPress) { _, state, _ in
                    state = true
                }
                .onChanged { _ in }
                .onEnded { value in
                    let held = value.time.timeIntervalSince(value.startLocation == value.location ? value.time : value.time) >= 0 // always true
                    if longPressFired {
                        longPressFired = false
                    } else {
                        onTap()
                    }
                }
        )
        .onChange(of: isDetectingPress) { _, pressing in
            if pressing {
                longPressFired = false
                DispatchQueue.main.asyncAfter(deadline: .now() + holdThreshold) {
                    if isDetectingPress {
                        longPressFired = true
                        onLongPress()
                    }
                }
            }
        }
        .animation(.easeInOut(duration: 0.15), value: cell.state)
    }

    @ViewBuilder
    private var cellBackground: some View {
        if cell.isRevealed {
            revealedBackground
        } else {
            hiddenBackground
        }
    }

    private var coveredCellColor: Color {
        if cell.isFlagged && cell.isWrongFlag {
            return Color.red.opacity(0.45)
        }
        if cell.isFlagged { return skin.flaggedCellColor }
        if cell.isQuestioned { return skin.flaggedCellColor }
        return skin.hiddenCellColor
    }

    private var hiddenBackground: some View {
        ZStack {
            RoundedRectangle(cornerRadius: skin.cellCornerRadius)
                .fill(coveredCellColor)
            if skin.cellCornerRadius == 0 {
                ClassicBevelOverlay()
            } else {
                RoundedRectangle(cornerRadius: skin.cellCornerRadius)
                    .strokeBorder(
                        LinearGradient(
                            colors: [skin.hiddenCellBorderLight, skin.hiddenCellBorderDark],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1.5
                    )
            }
        }
    }

    private var revealedBackground: some View {
        RoundedRectangle(cornerRadius: skin.cellCornerRadius)
            .fill(triggeredMineBackground)
            .overlay(
                RoundedRectangle(cornerRadius: skin.cellCornerRadius)
                    .strokeBorder(Color.primary.opacity(0.1), lineWidth: 0.5)
            )
    }

    private var triggeredMineBackground: Color {
        if cell.isMine && cell.isTriggered {
            return Color.red.opacity(0.6)
        }
        return skin.revealedCellColor
    }

    @ViewBuilder
    private var cellContent: some View {
        if cell.isFlagged {
            flagContent
        } else if cell.isQuestioned {
            questionContent
        } else if cell.isRevealed {
            if cell.isMine {
                mineContent
            } else if cell.adjacentMines > 0 {
                numberContent
            }
        }
    }

    private var questionContent: some View {
        Text("?")
            .font(.system(size: size * 0.55, weight: .bold, design: skin.numberFontDesign))
            .foregroundStyle(.primary)
    }

    private var flagContent: some View {
        iconView(skin.flagIcon, color: .red)
    }

    private var mineContent: some View {
        iconView(skin.mineIcon, color: .primary)
    }

    @ViewBuilder
    private func iconView(_ icon: ThemeIcon, color: Color) -> some View {
        switch icon {
        case .emoji(let text):
            Text(text)
                .font(.system(size: size * 0.5))
        case .sfSymbol(let name):
            Image(systemName: name)
                .font(.system(size: size * 0.4, weight: .bold))
                .foregroundStyle(color)
        }
    }

    private var numberContent: some View {
        Text("\(cell.adjacentMines)")
            .font(.system(size: size * 0.55, weight: .bold, design: skin.numberFontDesign))
            .foregroundStyle(skin.numberColor(for: cell.adjacentMines))
    }
}

private struct ClassicBevelOverlay: View {
    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            let t: CGFloat = 2.5
            Path { path in
                path.move(to: .zero)
                path.addLine(to: CGPoint(x: w, y: 0))
                path.addLine(to: CGPoint(x: w - t, y: t))
                path.addLine(to: CGPoint(x: t, y: t))
                path.addLine(to: CGPoint(x: t, y: h - t))
                path.addLine(to: CGPoint(x: 0, y: h))
                path.closeSubpath()
            }
            .fill(Color.white.opacity(0.5))

            Path { path in
                path.move(to: CGPoint(x: w, y: 0))
                path.addLine(to: CGPoint(x: w, y: h))
                path.addLine(to: CGPoint(x: 0, y: h))
                path.addLine(to: CGPoint(x: t, y: h - t))
                path.addLine(to: CGPoint(x: w - t, y: h - t))
                path.addLine(to: CGPoint(x: w - t, y: t))
                path.closeSubpath()
            }
            .fill(Color.black.opacity(0.3))
        }
    }
}
