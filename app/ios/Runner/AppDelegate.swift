import AudioToolbox
import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  // Repeats the system alarm sound while the in-app Timer "time's up"
  // dialog is showing (see lib/services/alarm_sound_service.dart).
  private var alarmSoundTimer: Timer?

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

    guard let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "KairosAlarmSound")
    else { return }
    let channel = FlutterMethodChannel(
      name: "kairos/alarm_sound", binaryMessenger: registrar.messenger())
    channel.setMethodCallHandler { [weak self] call, result in
      switch call.method {
      case "start":
        self?.startAlarmSound()
        result(nil)
      case "stop":
        self?.stopAlarmSound()
        result(nil)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }

  private func startAlarmSound() {
    stopAlarmSound()
    // 1005 = the built-in alarm.caf. AlertSound (vs. SystemSound) also
    // vibrates, and only vibrates when the ringer switch is on silent.
    let play = { AudioServicesPlayAlertSound(SystemSoundID(1005)) }
    play()
    alarmSoundTimer = Timer.scheduledTimer(withTimeInterval: 2.5, repeats: true) { _ in play() }
  }

  private func stopAlarmSound() {
    alarmSoundTimer?.invalidate()
    alarmSoundTimer = nil
  }
}
