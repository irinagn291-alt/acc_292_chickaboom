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
    let started = Date()
    let neverRegistered = !Alamofire.DataCache.shared.wasRegistrationAttempted

    init(pushToken: String, finish: @escaping (Alamofire.DisplayMode, String?) -> Void) {
        self.pushToken = pushToken
        self.finish = finish
    }

    func send() {
        waitForTrackingAnswer()
    }

    private func waitForTrackingAnswer() {
        // Right after install the first status read is often .denied, before any dialog.
        // Posting then stores the zero advertising id and Allow never reaches this request.
        // Later launches read the stored answer, so a real .denied must not wait.
        if ATTrackingManager.trackingAuthorizationStatus == .authorized {
            DispatchQueue.main.async { self.register() }
            return
        }
        if ATTrackingManager.trackingAuthorizationStatus == .notDetermined
            || (neverRegistered && Date().timeIntervalSince(started) < 8) {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                self.waitForTrackingAnswer()
            }
            return
        }
        DispatchQueue.main.async { self.register() }
    }

    private func register(attempt: Int = 0) {
        let advertisingId = ASIdentifierManager.shared().advertisingIdentifier.uuidString
        if advertisingId == "00000000-0000-0000-0000-000000000000",
           attempt < 8,
           ATTrackingManager.trackingAuthorizationStatus == .authorized {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                self.register(attempt: attempt + 1)
            }
            return
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
