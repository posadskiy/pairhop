import Sparkle

/// Sparkle reads the appcast attached to the latest GitHub release on its own schedule.
/// The Info.plist turns on automatic checks and silent install. This only starts that
/// and answers Check for Updates.
@MainActor
final class Updates {
    static let shared = Updates()

    private var controller: SPUStandardUpdaterController?

    func start() {
        guard controller == nil else { return }
        controller = SPUStandardUpdaterController(
            startingUpdater: true,
            updaterDelegate: nil,
            userDriverDelegate: nil
        )
    }

    func check() {
        controller?.checkForUpdates(nil)
    }
}
