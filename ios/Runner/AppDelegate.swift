import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)

    // Odak seansı sürerken ekranın kendiliğinden kilitlenmesini engeller
    // (bkz. lib/core/services/secure_screen_service.dart).
    let kanal = FlutterMethodChannel(
      name: "com.lisenet/secure_screen",
      binaryMessenger: engineBridge.applicationRegistrar.messenger()
    )
    kanal.setMethodCallHandler { call, result in
      switch call.method {
      case "setKeepScreenOn":
        let acik = (call.arguments as? [String: Any])?["on"] as? Bool ?? false
        UIApplication.shared.isIdleTimerDisabled = acik
        result(nil)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }
}
