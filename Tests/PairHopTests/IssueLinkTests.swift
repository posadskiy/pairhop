import Foundation
import Testing
@testable import PairHop

@Suite struct IssueLinkTests {
    @Test func bugReportPrefillsVersionAndSystem() throws {
        let url = IssueLink.bugReport()
        let items = try #require(URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems)
        let values = Dictionary(uniqueKeysWithValues: items.map { ($0.name, $0.value ?? "") })
        #expect(url.host == "github.com")
        #expect(url.path == "/posadskiy/pairhop/issues/new")
        #expect(values["template"] == "bug_report.yml")
        #expect(values["macos-version"]?.isEmpty == false)
        #expect(values["pairhop-version"]?.isEmpty == false)
    }
}
