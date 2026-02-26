import FirebaseCore
import SwiftUI

@main
struct OldIPhoneCameraExperienceApp: App {
    init() {
        FirebaseApp.configure()
    }

    var body: some Scene {
        WindowGroup {
            CameraScreen()
        }
    }
}
