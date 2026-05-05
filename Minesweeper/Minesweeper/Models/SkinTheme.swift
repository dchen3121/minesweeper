import SwiftUI

enum ThemeIcon: Equatable, Sendable {
    case emoji(String)
    case sfSymbol(String)
}

struct SkinTheme: Equatable, Identifiable, Sendable {
    let id: String
    let name: String

    let hiddenCellColor: Color
    let hiddenCellBorderLight: Color
    let hiddenCellBorderDark: Color
    let revealedCellColor: Color
    let flaggedCellColor: Color

    let mineIcon: ThemeIcon
    let flagIcon: ThemeIcon

    let numberColors: [Color]

    let numberFontDesign: Font.Design
    let cellCornerRadius: CGFloat
    let backgroundColor: Color

    func numberColor(for count: Int) -> Color {
        guard count >= 1, count <= 8 else { return .primary }
        return numberColors[count - 1]
    }
}

extension SkinTheme {
    static let classic = SkinTheme(
        id: "classic",
        name: "Classic",
        hiddenCellColor: Color(red: 0.75, green: 0.75, blue: 0.75),
        hiddenCellBorderLight: Color(red: 0.9, green: 0.9, blue: 0.9),
        hiddenCellBorderDark: Color(red: 0.5, green: 0.5, blue: 0.5),
        revealedCellColor: Color(red: 0.85, green: 0.85, blue: 0.85),
        flaggedCellColor: Color(red: 0.75, green: 0.75, blue: 0.75),
        mineIcon: .emoji("💣"),
        flagIcon: .sfSymbol("flag.fill"),
        numberColors: [
            .blue,
            Color(red: 0.0, green: 0.5, blue: 0.0),
            .red,
            Color(red: 0.0, green: 0.0, blue: 0.5),
            Color(red: 0.5, green: 0.0, blue: 0.0),
            Color(red: 0.0, green: 0.5, blue: 0.5),
            .black,
            .gray,
        ],
        numberFontDesign: .monospaced,
        cellCornerRadius: 0,
        backgroundColor: Color(red: 0.78, green: 0.78, blue: 0.78)
    )

    static let dark = SkinTheme(
        id: "dark",
        name: "Dark",
        hiddenCellColor: Color(red: 0.22, green: 0.22, blue: 0.24),
        hiddenCellBorderLight: Color(red: 0.32, green: 0.32, blue: 0.34),
        hiddenCellBorderDark: Color(red: 0.12, green: 0.12, blue: 0.14),
        revealedCellColor: Color(red: 0.14, green: 0.14, blue: 0.16),
        flaggedCellColor: Color(red: 0.22, green: 0.22, blue: 0.24),
        mineIcon: .emoji("💣"),
        flagIcon: .sfSymbol("flag.fill"),
        numberColors: [
            Color(red: 0.40, green: 0.60, blue: 1.0),
            Color(red: 0.30, green: 0.80, blue: 0.40),
            Color(red: 1.0, green: 0.40, blue: 0.40),
            Color(red: 0.65, green: 0.45, blue: 0.95),
            Color(red: 0.95, green: 0.45, blue: 0.35),
            Color(red: 0.30, green: 0.80, blue: 0.80),
            Color(red: 0.70, green: 0.70, blue: 0.70),
            Color(red: 0.85, green: 0.85, blue: 0.85),
        ],
        numberFontDesign: .rounded,
        cellCornerRadius: 4,
        backgroundColor: Color(red: 0.10, green: 0.10, blue: 0.12)
    )

    static let allThemes: [SkinTheme] = [.classic, .dark]

    static func theme(for id: String) -> SkinTheme {
        allThemes.first { $0.id == id } ?? .classic
    }
}
