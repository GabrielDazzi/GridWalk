import GridWalkDesign
import Testing

@Suite("Color contrast")
struct ContrastTests {
    static let palettes: [(String, Palette)] = [("dark", .dark), ("light", .light)]
    // WCAG AA for normal text
    static let minimum = 4.5

    @Test("dark tokens match the spec")
    func darkTokens() {
        #expect(Palette.dark.background == RGB(0x0E0F12))
        #expect(Palette.dark.card == RGB(0x1A1C21))
        #expect(Palette.dark.accent == RGB(0xFF3B30))
        #expect(Palette.dark.text == RGB(0xF2F2F2))
        #expect(Palette.dark.secondaryText == RGB(0x8A8F98))
        #expect(Palette.dark.qualifying.fill == RGB(0xFFB020))
        #expect(Palette.dark.sprint.fill == RGB(0x32D2F5))
        #expect(Palette.dark.race.fill == Palette.dark.accent)
    }

    @Test("text is readable on background and cards", arguments: palettes)
    func textOnSurfaces(name: String, palette: Palette) {
        for surface in [palette.background, palette.card] {
            #expect(palette.text.contrast(with: surface) >= Self.minimum, "\(name) text")
            #expect(palette.secondaryText.contrast(with: surface) >= Self.minimum, "\(name) secondary")
            #expect(palette.accent.contrast(with: surface) >= Self.minimum, "\(name) accent")
        }
    }

    @Test("button labels are readable", arguments: palettes)
    func buttons(name: String, palette: Palette) {
        // primary: label on accent fill; secondary: accent label on a card
        #expect(palette.onAccent.contrast(with: palette.accent) >= Self.minimum, "\(name) primary")
        #expect(palette.accent.contrast(with: palette.card) >= Self.minimum, "\(name) secondary")
    }

    @Test("session tag labels are readable on their fill", arguments: palettes)
    func tagLabels(name: String, palette: Palette) {
        for tag in palette.tags {
            #expect(tag.label.contrast(with: tag.fill) >= Self.minimum, "\(name) tag \(tag)")
        }
    }

    @Test("contrast math matches known values")
    func knownValues() {
        #expect(abs(RGB(0x000000).contrast(with: RGB(0xFFFFFF)) - 21) < 0.01)
        #expect(RGB(0x777777).contrast(with: RGB(0x777777)) == 1)
    }
}
