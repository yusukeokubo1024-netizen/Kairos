import AVFoundation
import AudioToolbox
import CryptoKit
import Flutter
import UIKit

#if canImport(AlarmKit)
  import ActivityKit
  import AlarmKit
  import AppIntents
  import SwiftUI
#endif

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

    // System alarms (iOS 26+ AlarmKit) — see lib/services/alarm_kit_service.dart.
    let alarmKitChannel = FlutterMethodChannel(
      name: "kairos/alarmkit", binaryMessenger: registrar.messenger())
    alarmKitChannel.setMethodCallHandler { call, result in
      #if canImport(AlarmKit)
        if #available(iOS 26.0, *) {
          let args = call.arguments as? [String: Any] ?? [:]
          Task {
            let value: Any?
            switch call.method {
            case "schedule":
              value = await KairosAlarmKit.schedule(args)
            case "cancel":
              KairosAlarmKit.cancel(key: args["key"] as? String ?? "")
              value = nil
            case "cancelAll":
              KairosAlarmKit.cancelAll()
              value = nil
            default:
              value = FlutterMethodNotImplemented
            }
            await MainActor.run { result(value) }
          }
          return
        }
      #endif
      // Older iOS: "schedule" answering false makes the Dart side fall back
      // to a regular local notification.
      result(call.method == "schedule" ? false : nil)
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

#if canImport(AlarmKit)
  @available(iOS 26.0, *)
  struct KairosAlarmMetadata: AlarmMetadata {}

  /// Schedules real system alarms: unlike a notification, an AlarmKit alarm
  /// rings at full volume even with the ringer switch on silent or a Focus
  /// on, and while the app isn't running at all.
  @available(iOS 26.0, *)
  enum KairosAlarmKit {
    /// AlarmKit identifies alarms by UUID; derive a stable one from the
    /// Dart-side key so the same alarm can be re-scheduled or cancelled.
    static func uuid(for key: String) -> UUID {
      let d = Array(Insecure.MD5.hash(data: Data(key.utf8)))
      return UUID(
        uuid: (
          d[0], d[1], d[2], d[3], d[4], d[5], d[6], d[7],
          d[8], d[9], d[10], d[11], d[12], d[13], d[14], d[15]
        ))
    }

    static func authorized() async -> Bool {
      let manager = AlarmManager.shared
      switch manager.authorizationState {
      case .authorized:
        return true
      case .notDetermined:
        return (try? await manager.requestAuthorization()) == .authorized
      default:
        return false
      }
    }

    /// Returns whether the alarm was scheduled. Args: key, title, stopText,
    /// sound (bundled file name or nil for the default alarm sound), and
    /// either fireAtMs (one-off) or hour/minute/weekdays (1 = Mon … 7 = Sun,
    /// repeating weekly).
    static func schedule(_ args: [String: Any]) async -> Bool {
      guard let key = args["key"] as? String, await authorized() else { return false }

      let schedule: Alarm.Schedule
      if let weekdays = args["weekdays"] as? [Int], !weekdays.isEmpty,
        let hour = args["hour"] as? Int, let minute = args["minute"] as? Int
      {
        let map: [Int: Locale.Weekday] = [
          1: .monday, 2: .tuesday, 3: .wednesday, 4: .thursday,
          5: .friday, 6: .saturday, 7: .sunday,
        ]
        schedule = .relative(
          Alarm.Schedule.Relative(
            time: Alarm.Schedule.Relative.Time(hour: hour, minute: minute),
            repeats: .weekly(weekdays.compactMap { map[$0] })))
      } else if let ms = args["fireAtMs"] as? Int {
        schedule = .fixed(Date(timeIntervalSince1970: Double(ms) / 1000))
      } else {
        return false
      }

      let title = args["title"] as? String ?? ""
      let stopText = args["stopText"] as? String ?? "Stop"
      let soundFile = args["sound"] as? String
      let snoozeMinutes = args["snoozeMinutes"] as? Int ?? 0
      let snoozeText = args["snoozeText"] as? String ?? "Snooze"
      let stopButton = AlarmButton(
        text: LocalizedStringResource(stringLiteral: stopText),
        textColor: .white,
        systemImageName: "stop.circle")

      let alert: AlarmPresentation.Alert
      var snoozeIntent: KairosSnoozeIntent?
      if snoozeMinutes > 0 {
        // A plain "custom" button that schedules a fresh one-off alarm
        // rather than AlarmKit's built-in countdown snooze, which needs a
        // Live Activity widget extension this app doesn't have.
        alert = AlarmPresentation.Alert(
          title: LocalizedStringResource(stringLiteral: title),
          stopButton: stopButton,
          secondaryButton: AlarmButton(
            text: LocalizedStringResource(stringLiteral: snoozeText),
            textColor: .white,
            systemImageName: "zzz"),
          secondaryButtonBehavior: .custom)
        snoozeIntent = KairosSnoozeIntent(
          key: key, alarmTitle: title, stopText: stopText, snoozeText: snoozeText,
          sound: soundFile ?? "", minutes: snoozeMinutes)
      } else {
        alert = AlarmPresentation.Alert(
          title: LocalizedStringResource(stringLiteral: title), stopButton: stopButton)
      }
      let attributes = AlarmAttributes<KairosAlarmMetadata>(
        presentation: AlarmPresentation(alert: alert), tintColor: .orange)
      let sound: AlertConfiguration.AlertSound = soundFile.map { .named($0) } ?? .default
      let configuration = AlarmManager.AlarmConfiguration<KairosAlarmMetadata>(
        schedule: schedule, attributes: attributes, secondaryIntent: snoozeIntent,
        sound: sound)

      let id = uuid(for: key)
      try? AlarmManager.shared.cancel(id: id)
      do {
        _ = try await AlarmManager.shared.schedule(id: id, configuration: configuration)
        return true
      } catch {
        return false
      }
    }

    static func cancel(key: String) {
      try? AlarmManager.shared.cancel(id: uuid(for: key))
      try? AlarmManager.shared.cancel(id: uuid(for: snoozeKey(for: key)))
    }

    static func snoozeKey(for key: String) -> String {
      key.hasSuffix("_snooze") ? key : "\(key)_snooze"
    }

    static func cancelAll() {
      for alarm in (try? AlarmManager.shared.alarms) ?? [] {
        try? AlarmManager.shared.cancel(id: alarm.id)
      }
    }
  }

  /// The ringing alarm's "Snooze" button: stops it and rings again
  /// [minutes] from now (itself snoozable again).
  @available(iOS 26.0, *)
  struct KairosSnoozeIntent: LiveActivityIntent {
    static let title: LocalizedStringResource = "Snooze"
    static let openAppWhenRun: Bool = false

    @Parameter(title: "Key") var key: String
    @Parameter(title: "Title") var alarmTitle: String
    @Parameter(title: "Stop") var stopText: String
    @Parameter(title: "Snooze") var snoozeText: String
    // "" = the default alarm sound.
    @Parameter(title: "Sound") var sound: String
    @Parameter(title: "Minutes") var minutes: Int

    init() {}

    init(
      key: String, alarmTitle: String, stopText: String, snoozeText: String, sound: String,
      minutes: Int
    ) {
      self.key = key
      self.alarmTitle = alarmTitle
      self.stopText = stopText
      self.snoozeText = snoozeText
      self.sound = sound
      self.minutes = minutes
    }

    func perform() async throws -> some IntentResult {
      try? AlarmManager.shared.stop(id: KairosAlarmKit.uuid(for: key))
      var args: [String: Any] = [
        "key": KairosAlarmKit.snoozeKey(for: key),
        "title": alarmTitle,
        "stopText": stopText,
        "snoozeText": snoozeText,
        "snoozeMinutes": minutes,
        "fireAtMs": Int((Date().timeIntervalSince1970 + Double(minutes * 60)) * 1000),
      ]
      if !sound.isEmpty { args["sound"] = sound }
      _ = await KairosAlarmKit.schedule(args)
      return .result()
    }
  }
#endif
