import Foundation

/// The GitHub bug form, with the version, macOS and chip already filled in.
/// Nothing about the user's devices or Macs goes in the link; that stays in the
/// diagnostics file they choose to attach.
enum IssueLink {
    static func bugReport(bundle: Bundle = .main, os: ProcessInfo = .processInfo) -> URL {
        let version = bundle.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "unknown"
        let build = bundle.object(forInfoDictionaryKey: "CFBundleVersion") as? String
        var components = URLComponents(string: "https://github.com/posadskiy/pairhop/issues/new")!
        components.queryItems = [
            URLQueryItem(name: "template", value: "bug_report.yml"),
            URLQueryItem(name: "pairhop-version", value: build.map { "\(version) (\($0))" } ?? version),
            URLQueryItem(name: "macos-version", value: os.operatingSystemVersionString),
        ]
        return components.url!
    }
}
