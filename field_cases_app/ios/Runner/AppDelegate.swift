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

    // ملفات .casepkg / .fcbackup تُفتح بالتطبيق من WhatsApp أو Files.
    if let incoming = engineBridge.pluginRegistry.registrar(forPlugin: "FieldCasesIncomingFiles") {
      IncomingFiles.shared.attach(registrar: incoming)
    }

    // استبعاد بيانات التطبيق من نسخ iCloud/iTunes: البيانات تبقى على الجهاز فقط.
    guard let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "FieldCasesBackupExclusion") else {
      return
    }
    let channel = FlutterMethodChannel(
      name: "field_cases/backup_exclusion",
      binaryMessenger: registrar.messenger()
    )
    channel.setMethodCallHandler { call, result in
      guard call.method == "exclude",
        let path = call.arguments as? String
      else {
        result(FlutterMethodNotImplemented)
        return
      }
      var url = URL(fileURLWithPath: path)
      var values = URLResourceValues()
      values.isExcludedFromBackup = true
      do {
        try url.setResourceValues(values)
        result(true)
      } catch {
        result(FlutterError(code: "exclude_failed", message: error.localizedDescription, details: nil))
      }
    }
  }
}

/// يستقبل الملفات المفتوحة بالتطبيق، ينسخها لمجلد مؤقت داخله، ويرسل مسارها لـ Dart.
final class IncomingFiles: NSObject, FlutterSceneLifeCycleDelegate {
  static let shared = IncomingFiles()

  private var channel: FlutterMethodChannel?
  private var pendingPath: String?
  private var dartReady = false

  func attach(registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(
      name: "field_cases/incoming_file",
      binaryMessenger: registrar.messenger()
    )
    channel.setMethodCallHandler { [weak self] call, result in
      guard let self else { return }
      if call.method == "getInitialFile" {
        self.dartReady = true
        result(self.pendingPath)
        self.pendingPath = nil
      } else {
        result(FlutterMethodNotImplemented)
      }
    }
    self.channel = channel
    registrar.addSceneDelegate(self)
  }

  // التطبيق مفتوح أو في الخلفية.
  func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) -> Bool {
    var handled = false
    for context in URLContexts where context.url.isFileURL {
      receive(context.url)
      handled = true
    }
    return handled
  }

  // التطبيق كان مغلقًا وفُتح بالملف.
  func scene(
    _ scene: UIScene,
    willConnectTo session: UISceneSession,
    options connectionOptions: UIScene.ConnectionOptions?
  ) -> Bool {
    guard let contexts = connectionOptions?.urlContexts else { return false }
    for context in contexts where context.url.isFileURL {
      receive(context.url)
    }
    return false
  }

  private func receive(_ url: URL) {
    guard let path = copy(url) else { return }
    if dartReady, let channel {
      channel.invokeMethod("onFile", arguments: path)
    } else {
      pendingPath = path
    }
  }

  private func copy(_ url: URL) -> String? {
    let scoped = url.startAccessingSecurityScopedResource()
    defer { if scoped { url.stopAccessingSecurityScopedResource() } }
    let dir = FileManager.default.temporaryDirectory.appendingPathComponent("incoming", isDirectory: true)
    let safeName = url.lastPathComponent.replacingOccurrences(
      of: "[^A-Za-z0-9._-]", with: "_", options: .regularExpression)
    let target = dir.appendingPathComponent("\(Int(Date().timeIntervalSince1970 * 1000))_\(safeName)")
    do {
      try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
      try FileManager.default.copyItem(at: url, to: target)
      // نسخة iOS في Documents/Inbox لم تعد لازمة.
      if url.path.contains("/Inbox/") {
        try? FileManager.default.removeItem(at: url)
      }
      return target.path
    } catch {
      return nil
    }
  }
}
