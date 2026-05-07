import SwiftUI
import GoogleMobileAds

@main
struct NekoGoroApp: App {
    init() {
        MobileAds.shared.start(completionHandler: nil)
    }
    var body: some Scene {
        WindowGroup { ContentView() }
    }
}
