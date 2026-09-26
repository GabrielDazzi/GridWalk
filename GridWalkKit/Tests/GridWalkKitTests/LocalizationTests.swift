import Foundation
import Testing

@testable import GridWalkKit

@Suite("Localization")
struct LocalizationTests {
    static let catalogs = [
        "GridWalkKit/Sources/GridWalkKit/Resources/Localizable.xcstrings",
        "Grid Walk/Localizable.xcstrings",
        "Grid Walk Widget/Localizable.xcstrings",
    ]

    private static var repoRoot: URL {
        URL(filePath: #filePath)
            .deletingLastPathComponent()  // GridWalkKitTests
            .deletingLastPathComponent()  // Tests
            .deletingLastPathComponent()  // GridWalkKit
            .deletingLastPathComponent()
    }

    @Test("every string has a Portuguese translation", arguments: catalogs)
    func portugueseCoverage(catalog: String) throws {
        let data = try Data(contentsOf: Self.repoRoot.appending(path: catalog))
        let root = try #require(try JSONSerialization.jsonObject(with: data) as? [String: Any])
        let strings = try #require(root["strings"] as? [String: [String: Any]])
        #expect(!strings.isEmpty)

        for (key, entry) in strings {
            if entry["shouldTranslate"] as? Bool == false { continue }
            let localizations = entry["localizations"] as? [String: Any]
            let portuguese = localizations?["pt"] as? [String: Any]
            let unit = portuguese?["stringUnit"] as? [String: Any]
            let hasVariations = portuguese?["variations"] != nil
            #expect(
                hasVariations || (unit?["state"] as? String == "translated" && unit?["value"] != nil),
                "missing pt for \"\(key)\" in \(catalog)"
            )
        }
    }

    @Test("kit bundle resolves Portuguese")
    func portugueseLookup() throws {
        let path = try #require(Bundle.gridWalkKit.path(forResource: "pt", ofType: "lproj"))
        let portuguese = try #require(Bundle(path: path))
        #expect(portuguese.localizedString(forKey: "Qualifying", value: nil, table: nil) == "Classificação")
        #expect(portuguese.localizedString(forKey: "FP1", value: nil, table: nil) == "TL1")
        // tags stay distinct in Portuguese too
        let tags = AlertCategory.allCases.map {
            portuguese.localizedString(forKey: $0.tagLetters, value: nil, table: nil)
        }
        #expect(Set(tags).count == tags.count)
    }
}
