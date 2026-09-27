import Foundation
import Testing

@testable import GridWalkKit

@Suite("App release versions")
struct AppReleaseTests {
    @Test("v prefix and missing patch still compare")
    func ordering() throws {
        let one = try #require(SemanticVersion("v1.0"))
        let onePatch = try #require(SemanticVersion("1.0.0"))
        let newer = try #require(SemanticVersion("1.2.0"))
        let beta = try #require(SemanticVersion("1.2.0-beta.1"))
        let betaTwo = try #require(SemanticVersion("1.2.0-beta.2"))
        #expect(one == onePatch)
        #expect(onePatch < newer)
        #expect(beta < newer)
        #expect(beta < betaTwo)
        let nine = try #require(SemanticVersion("1.9.0"))
        let ten = try #require(SemanticVersion("1.10.0"))
        #expect(nine < ten)
        #expect(SemanticVersion("nope") == nil)
        #expect(SemanticVersion("1.2.3.4") == nil)
    }

    @Test("latest disk image is offered when it is newer")
    func newerRelease() throws {
        let data = try fixture("github-release")
        let found = try ReleaseLookup.newerRelease(current: "1.0.0", json: data)
        let offer = try #require(found)
        #expect(offer.tag == "v1.2.0")
        #expect(offer.diskImageURL.host == "github.com")
        #expect(offer.byteCount == 4096)
        #expect(try ReleaseLookup.newerRelease(current: "1.2.0", json: data) == nil)
        #expect(try ReleaseLookup.newerRelease(current: "v1.2.0", json: data) == nil)
        #expect(try ReleaseLookup.newerRelease(current: "2.0.0", json: data) == nil)
    }

    @Test("a prerelease or an off-site disk image is not installed")
    func rejected() throws {
        let prerelease = Data(
            #"{"tag_name":"v9.0.0","draft":false,"prerelease":true,"assets":[]}"#.utf8)
        #expect(try ReleaseLookup.newerRelease(current: "1.0.0", json: prerelease) == nil)

        let remote = Data(
            #"{"tag_name":"v9.0.0","draft":false,"prerelease":false,"assets":[{"name":"Grid Walk.dmg","browser_download_url":"https://example.com/Grid.Walk.dmg"}]}"#
                .utf8)
        #expect(throws: LookupError.untrustedDownload) {
            try ReleaseLookup.newerRelease(current: "1.0.0", json: remote)
        }
        let zipOnly = Data(
            #"{"tag_name":"v9.0.0","draft":false,"prerelease":false,"assets":[{"name":"GridWalk.zip","browser_download_url":"https://github.com/GabrielDazzi/GridWalk/releases/download/v9.0.0/GridWalk.zip"}]}"#
                .utf8)
        #expect(try ReleaseLookup.newerRelease(current: "1.0.0", json: zipOnly) == nil)

        let draft = Data(
            #"{"tag_name":"v9.0.0","draft":true,"prerelease":false,"assets":[{"name":"Grid Walk.dmg","browser_download_url":"https://github.com/GabrielDazzi/GridWalk/a.dmg"}]}"#
                .utf8)
        #expect(try ReleaseLookup.newerRelease(current: "1.0.0", json: draft) == nil)

        #expect(throws: DecodingError.self) {
            try ReleaseLookup.newerRelease(current: "1.0.0", json: Data("{}".utf8))
        }

        let http = try #require(URL(string: "http://github.com/GabrielDazzi/GridWalk/releases/download/v9/a.dmg"))
        let api = try #require(URL(string: "https://api.github.com/repos/GabrielDazzi/GridWalk/releases/latest"))
        let otherRepo = try #require(URL(string: "https://api.github.com/repos/other/app/releases/latest"))
        let lookalike = try #require(URL(string: "https://github.com.evil.example/a.dmg"))
        let ours = try #require(
            URL(string: "https://github.com/GabrielDazzi/GridWalk/releases/download/v9.0.0/GridWalk.dmg"))
        let someoneElse = try #require(
            URL(string: "https://github.com/someone/else/releases/download/v1/app.dmg"))
        let slipped = try #require(
            URL(string: "https://github.com/GabrielDazzi/GridWalk/releases/download/v9/../../else/app.dmg"))
        let cdn = try #require(URL(string: "https://release-assets.githubusercontent.com/a.dmg"))
        #expect(ReleaseLookup.allowsDownload(from: http) == false)
        #expect(ReleaseLookup.allowsDownload(from: lookalike) == false)
        #expect(ReleaseLookup.allowsDownload(from: api) == true)
        #expect(ReleaseLookup.allowsDownload(from: otherRepo) == false)
        #expect(ReleaseLookup.allowsDownload(from: ours) == true)
        #expect(ReleaseLookup.allowsDownload(from: someoneElse) == false)
        #expect(ReleaseLookup.allowsDownload(from: slipped) == false)
        #expect(ReleaseLookup.allowsDownload(from: cdn) == false)
        #expect(ReleaseLookup.allowsDownloadRedirect(from: cdn) == true)
        #expect(ReleaseLookup.allowsDownloadRedirect(from: ours) == true)
    }
}
