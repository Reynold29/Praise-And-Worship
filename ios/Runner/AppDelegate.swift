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
  }

  // Handle Supabase OAuth deep-link callback on iOS.
  // When Google sign-in redirects back via io.supabase.worshipcompanion://login-callback
  // this forwards the URL to the Flutter engine so supabase_flutter can process it.
  override func application(
    _ app: UIApplication,
    open url: URL,
    options: [UIApplication.OpenURLOptionsKey: Any] = [:]
  ) -> Bool {
    return super.application(app, open: url, options: options)
  }
}

@available(iOS 13.0, *)
@objc(SceneDelegate)
class SceneDelegate: FlutterSceneDelegate {
  override func scene(
    _ scene: UIScene,
    willConnectTo session: UISceneSession,
    options connectionOptions: UIScene.ConnectionOptions
  ) {
    super.scene(scene, willConnectTo: session, options: connectionOptions)
    for context in connectionOptions.urlContexts {
      _ = (UIApplication.shared.delegate as? AppDelegate)?.application(
        UIApplication.shared,
        open: context.url,
        options: [
          .sourceApplication: context.options.sourceApplication ?? "",
          .annotation: context.options.annotation as Any,
          .openInPlace: context.options.openInPlace
        ]
      )
    }
  }

  override func scene(
    _ scene: UIScene,
    openURLContexts URLContexts: Set<UIOpenURLContext>
  ) {
    super.scene(scene, openURLContexts: URLContexts)
    for context in URLContexts {
      _ = (UIApplication.shared.delegate as? AppDelegate)?.application(
        UIApplication.shared,
        open: context.url,
        options: [
          .sourceApplication: context.options.sourceApplication ?? "",
          .annotation: context.options.annotation as Any,
          .openInPlace: context.options.openInPlace
        ]
      )
    }
  }
}

