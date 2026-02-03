import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate { // 👈 關鍵：這裡必須繼承 FlutterAppDelegate
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self) // 👈 關鍵：註冊插件
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}