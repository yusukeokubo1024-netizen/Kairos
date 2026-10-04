import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Without this, iOS silently drops local notifications (e.g. the
    // Clock tab's Timer/Alarm) that fire while the app is in the
    // foreground — no banner, no sound. FlutterAppDelegate forwards the
    // delegate callbacks to flutter_local_notifications, which presents
    // them per DarwinInitializationSettings' defaultPresent* flags.
    UNUserNotificationCenter.current().delegate = self
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
  }
}
