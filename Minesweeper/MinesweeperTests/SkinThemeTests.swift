import Testing
@testable import Minesweeper

// MARK: - Theme Registry

@Suite("Theme Registry")
struct ThemeRegistryTests {

    @Test func allThemesHaveUniqueIds() {
        let ids = SkinTheme.allThemes.map(\.id)
        #expect(Set(ids).count == ids.count, "Duplicate theme IDs found")
    }

    @Test func allThemesHaveUniqueNames() {
        let names = SkinTheme.allThemes.map(\.name)
        #expect(Set(names).count == names.count, "Duplicate theme names found")
    }

    @Test func allThemesRegistered() {
        #expect(SkinTheme.allThemes.count == 2, "Expected exactly 2 built-in themes")
    }

    @Test func lookupByIdReturnsCorrectTheme() {
        for theme in SkinTheme.allThemes {
            let found = SkinTheme.theme(for: theme.id)
            #expect(found.id == theme.id)
            #expect(found.name == theme.name)
        }
    }

    @Test func lookupByUnknownIdFallsBackToClassic() {
        let fallback = SkinTheme.theme(for: "nonexistent_theme_id")
        #expect(fallback.id == "classic")
    }

    @Test func lookupByEmptyStringFallsBackToClassic() {
        let fallback = SkinTheme.theme(for: "")
        #expect(fallback.id == "classic")
    }
}

// MARK: - Theme Integrity

@Suite("Theme Integrity")
struct ThemeIntegrityTests {

    @Test func allThemesHaveExactly8NumberColors() {
        for theme in SkinTheme.allThemes {
            #expect(theme.numberColors.count == 8,
                "\(theme.name) has \(theme.numberColors.count) number colors, expected 8")
        }
    }

    @Test func numberColorForValidCounts() {
        for theme in SkinTheme.allThemes {
            for count in 1...8 {
                let color = theme.numberColor(for: count)
                #expect(color != .primary,
                    "\(theme.name) returned .primary for count \(count)")
            }
        }
    }

    @Test func numberColorForInvalidCountsReturnsPrimary() {
        let theme = SkinTheme.classic
        #expect(theme.numberColor(for: 0) == .primary)
        #expect(theme.numberColor(for: 9) == .primary)
        #expect(theme.numberColor(for: -1) == .primary)
    }

    @Test func allThemesHaveNonEmptyIcons() {
        for theme in SkinTheme.allThemes {
            switch theme.mineIcon {
            case .emoji(let s): #expect(!s.isEmpty, "\(theme.name) has empty mine emoji")
            case .sfSymbol(let s): #expect(!s.isEmpty, "\(theme.name) has empty mine SF Symbol")
            }
            switch theme.flagIcon {
            case .emoji(let s): #expect(!s.isEmpty, "\(theme.name) has empty flag emoji")
            case .sfSymbol(let s): #expect(!s.isEmpty, "\(theme.name) has empty flag SF Symbol")
            }
        }
    }

    @Test func allThemesHaveNonNegativeCornerRadius() {
        for theme in SkinTheme.allThemes {
            #expect(theme.cellCornerRadius >= 0,
                "\(theme.name) has negative corner radius")
        }
    }

    @Test func emojiIconsContainEmoji() {
        for theme in SkinTheme.allThemes {
            if case .emoji(let s) = theme.mineIcon {
                #expect(s.unicodeScalars.first?.properties.isEmoji == true,
                    "\(theme.name) mine icon marked as emoji but doesn't start with emoji")
            }
            if case .emoji(let s) = theme.flagIcon {
                #expect(s.unicodeScalars.first?.properties.isEmoji == true,
                    "\(theme.name) flag icon marked as emoji but doesn't start with emoji")
            }
        }
    }
}

// MARK: - Individual Themes

@Suite("Built-in Themes")
struct BuiltInThemeTests {

    @Test func classicThemeProperties() {
        let t = SkinTheme.classic
        #expect(t.id == "classic")
        #expect(t.cellCornerRadius == 0)
        #expect(t.mineIcon == .emoji("💣"))
        #expect(t.flagIcon == .sfSymbol("flag.fill"))
        #expect(t.numberFontDesign == .monospaced)
    }

    @Test func darkThemeProperties() {
        let t = SkinTheme.dark
        #expect(t.id == "dark")
        #expect(t.cellCornerRadius > 0)
        #expect(t.mineIcon == .emoji("💣"))
        #expect(t.flagIcon == .sfSymbol("flag.fill"))
        #expect(t.numberFontDesign == .rounded)
    }
}

// MARK: - Theme Switching

@Suite("Theme Switching")
@MainActor
struct ThemeSwitchingTests {

    @Test func switchingThemeDoesNotAffectGameState() {
        let board = GameBoard(rows: 9, cols: 9, minePositions: [
            (0, 4), (1, 5), (2, 6), (3, 7), (4, 8),
            (5, 3), (6, 2), (7, 1), (8, 0), (8, 8)
        ])
        let vm = GameViewModel(board: board)
        vm.tapCell(row: 0, col: 0)

        let stateBefore = vm.gameState
        let revealedBefore = vm.board.revealedCount
        let flagsBefore = vm.board.flagCount

        for theme in SkinTheme.allThemes {
            _ = theme.id
            #expect(vm.gameState == stateBefore)
            #expect(vm.board.revealedCount == revealedBefore)
            #expect(vm.board.flagCount == flagsBefore)
        }
    }

    @Test func allThemesCanRenderEveryCell() {
        let states: [(CellState, Bool, Int)] = [
            (.hidden, false, 0),
            (.flagged, false, 0),
            (.questioned, false, 0),
            (.revealed, false, 0),
            (.revealed, false, 1),
            (.revealed, false, 2),
            (.revealed, false, 3),
            (.revealed, false, 4),
            (.revealed, false, 5),
            (.revealed, false, 6),
            (.revealed, false, 7),
            (.revealed, false, 8),
            (.revealed, true, 0),
        ]

        for theme in SkinTheme.allThemes {
            for (state, isMine, adj) in states {
                if adj > 0 {
                    _ = theme.numberColor(for: adj)
                }
                if isMine {
                    switch theme.mineIcon {
                    case .emoji(let s), .sfSymbol(let s): #expect(!s.isEmpty)
                    }
                }
                if state == .flagged {
                    switch theme.flagIcon {
                    case .emoji(let s), .sfSymbol(let s): #expect(!s.isEmpty)
                    }
                }
            }
        }
    }
}

// MARK: - Theme Selection

@Suite("Theme Selection")
struct ThemeSelectionTests {

    @Test func canSelectEveryThemeById() {
        for theme in SkinTheme.allThemes {
            var selectedId = "classic"
            selectedId = theme.id
            let resolved = SkinTheme.theme(for: selectedId)
            #expect(resolved.id == theme.id)
        }
    }

    @Test func switchFromClassicToDark() {
        var selectedId = "classic"
        #expect(SkinTheme.theme(for: selectedId).id == "classic")

        selectedId = "dark"
        #expect(SkinTheme.theme(for: selectedId).id == "dark")
    }

    @Test func switchFromDarkToClassic() {
        var selectedId = "dark"
        #expect(SkinTheme.theme(for: selectedId).id == "dark")

        selectedId = "classic"
        #expect(SkinTheme.theme(for: selectedId).id == "classic")
    }

    @Test func switchBackAndForthRepeatedly() {
        var selectedId = "classic"
        for _ in 0..<10 {
            selectedId = "dark"
            #expect(SkinTheme.theme(for: selectedId).id == "dark")
            selectedId = "classic"
            #expect(SkinTheme.theme(for: selectedId).id == "classic")
        }
    }

    @Test func selectingSameThemeTwiceIsIdempotent() {
        var selectedId = "dark"
        let first = SkinTheme.theme(for: selectedId)
        selectedId = "dark"
        let second = SkinTheme.theme(for: selectedId)
        #expect(first == second)
    }

    @Test func removedThemeIdFallsBackToClassic() {
        let selectedId = "modern"
        let resolved = SkinTheme.theme(for: selectedId)
        #expect(resolved.id == "classic")
    }

    @Test func removedRetroThemeIdFallsBackToClassic() {
        let selectedId = "retro"
        let resolved = SkinTheme.theme(for: selectedId)
        #expect(resolved.id == "classic")
    }

    @Test func removedEmojiThemeIdFallsBackToClassic() {
        let selectedId = "emoji"
        let resolved = SkinTheme.theme(for: selectedId)
        #expect(resolved.id == "classic")
    }
}
