import SwiftUI
import GoogleMobileAds
import AppTrackingTransparency

@main
struct NekoGoroApp: App {
    init() {
        MobileAds.shared.start(completionHandler: nil)
    }
    var body: some Scene {
        WindowGroup {
            ContentView()
                .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
                    requestATT()
                }
        }
    }

    private func requestATT() {
        if #available(iOS 14.5, *) {
            ATTrackingManager.requestTrackingAuthorization { _ in }
        }
    }
}
