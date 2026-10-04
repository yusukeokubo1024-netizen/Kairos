import AVFoundation
import AudioToolbox
import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  // Loops the chosen alarm sound while the in-app Timer "time's up" dialog
  // or a sound-picker preview is playing (see
  // lib/services/alarm_sound_service.dart).
  private var alarmSoundTimer: Timer?
  private var alarmPlayer: AVAudioPlayer?

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
        let args = call.arguments as? [String: Any]
        self?.startAlarmSound(file: args?["file"] as? String)
        result(nil)
      case "stop":
        self?.stopAlarmSound()
        result(nil)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }

  private func startAlarmSound(file: String?) {
    stopAlarmSound()
    // One of the bundled alarm_*.caf sounds the user picked, looped.
    if let file = file,
      let url = Bundle.main.url(forResource: file, withExtension: nil),
      let player = try? AVAudioPlayer(contentsOf: url)
    {
      // .playback rings even with the ringer switch on silent, like the
      // built-in Clock app's alarms.
      try? AVAudioSession.sharedInstance().setCategory(.playback)
      try? AVAudioSession.sharedInstance().setActive(true)
      player.numberOfLoops = -1
      player.play()
      alarmPlayer = player
      return
    }
    // "Default": 1005 = the built-in alarm.caf. AlertSound (vs.
    // SystemSound) also vibrates, and only vibrates when the ringer switch
    // is on silent.
    let play = { AudioServicesPlayAlertSound(SystemSoundID(1005)) }
    play()
    alarmSoundTimer = Timer.scheduledTimer(withTimeInterval: 2.5, repeats: true) { _ in play() }
  }

  private func stopAlarmSound() {
    alarmSoundTimer?.invalidate()
    alarmSoundTimer = nil
    if alarmPlayer != nil {
      alarmPlayer?.stop()
      alarmPlayer = nil
      try? AVAudioSession.sharedInstance().setActive(
        false, options: .notifyOthersOnDeactivation)
    }
  }
}
