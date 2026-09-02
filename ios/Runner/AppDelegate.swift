import Flutter
import UIKit
import FirebaseCore
import FirebaseMessaging

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // تهيئة Firebase (Push) — يتطلب GoogleService-Info.plist في Runner/
    if FileManager.default.fileExists(atPath: Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist") ?? "") {
      FirebaseApp.configure()
    }
    GeneratedPluginRegistrant.register(with: self)
    // تسجيل الإشعارات البعيدة
    UNUserNotificationCenter.current().delegate = self
    application.registerForRemoteNotifications()
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  // ربط توكن APNs بـ Firebase
  override func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
    Messaging.messaging().apnsToken = deviceToken
    super.application(application, didRegisterForRemoteNotificationsWithDeviceToken: deviceToken)
  }
}
