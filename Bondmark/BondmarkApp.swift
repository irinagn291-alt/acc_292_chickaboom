import SwiftUI
import Alamofire
import AppsFlyerLib
import AppTrackingTransparency
import AdSupport

@MainActor
private enum LaunchRegistration {
    static var started = false
}

private final class RegistrationAttribution: @unchecked Sendable {
    let pushToken: String
    let finish: (Alamofire.DisplayMode, String?) -> Void
    private var answerObserver: NSObjectProtocol?
    private var posted = false

    init(pushToken: String, finish: @escaping (Alamofire.DisplayMode, String?) -> Void) {
        self.pushToken = pushToken
        self.finish = finish
    }

    func send() {
        let status = ATTrackingManager.trackingAuthorizationStatus
        let returning = Alamofire.DataCache.shared.wasRegistrationAttempted
            || !(Alamofire.DataCache.shared.contentURL ?? "").isEmpty
        // Already allowed, or a later launch after a real denial. First launch must
        // wait for the dialog: an early .denied arrives before the user taps.
        if status == .authorized || (status != .notDetermined && returning) {
            DispatchQueue.main.async { self.register() }
            return
        }
        answerObserver = NotificationCenter.default.addObserver(
            forName: Notification.Name("af.tracking.answered"),
            object: nil,
            queue: .main
        ) { _ in
            self.register()
        }
    }

    private func register(attempt: Int = 0) {
        if posted { return }
        let advertisingId = ASIdentifierManager.shared().advertisingIdentifier.uuidString
        if ATTrackingManager.trackingAuthorizationStatus == .authorized,
           advertisingId == "00000000-0000-0000-0000-000000000000",
           attempt < 8 {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                self.register(attempt: attempt + 1)
            }
            return
        }
        posted = true
        if let answerObserver {
            NotificationCenter.default.removeObserver(answerObserver)
            self.answerObserver = nil
        }
        let appsflyerId = AppsFlyerLib.shared().getAppsFlyerUID()
        Alamofire.NetworkService.shared.performRegistration(
            pushToken: self.pushToken,
            advertisingId: advertisingId,
            appsflyerId: appsflyerId
        ) { mode, url in
            self.finish(mode, url)
        }
    }
}

@main
struct BondmarkApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @State private var isInitializing = true
    @State private var displayMode: Alamofire.DisplayMode = .loading
    @State private var webContentURL: String?

    var body: some Scene {
        WindowGroup {
            rootView
                .onAppear { performRegistration() }
        }
    }

    @ViewBuilder
    private var rootView: some View {
        ZStack {
            if isInitializing {
                // Loading screen
            } else if displayMode == .webContent, let url = webContentURL {
                let fullURL = url.hasPrefix("http") ? url : "https://\(url)"
                ZStack {
                    Color.black.ignoresSafeArea()
                    Alamofire.WebContentView(url: fullURL)
                }
                .preferredColorScheme(.dark)
            } else {
                ContentView()
            }
        }
    }

    private func performRegistration() {
        let pushToken = ""

        if ProcessInfo.processInfo.arguments.contains("-ReviewScreen") {
            finishLaunch(mode: .nativeInterface, url: nil)
            return
        }

        guard !LaunchRegistration.started else { return }
        LaunchRegistration.started = true

        if let saved = Alamofire.DataCache.shared.contentURL, !saved.isEmpty {
            finishLaunch(mode: .webContent, url: saved)
            return
        }

        RegistrationAttribution(pushToken: pushToken) { mode, url in
            DispatchQueue.main.async { finishLaunch(mode: mode, url: url) }
        }.send()
    }

    private func finishLaunch(mode: Alamofire.DisplayMode, url: String?) {
        guard isInitializing else { return }
        displayMode = mode
        webContentURL = url
        isInitializing = false
    }
}
