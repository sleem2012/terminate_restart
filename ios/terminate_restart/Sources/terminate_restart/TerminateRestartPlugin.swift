import Flutter
import UIKit

public class TerminateRestartPlugin: NSObject, FlutterPlugin {
    private var internalChannel: FlutterMethodChannel?
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "com.ahmedsleem.terminate_restart/restart", binaryMessenger: registrar.messenger())
        let instance = TerminateRestartPlugin()
        instance.internalChannel = FlutterMethodChannel(name: "com.ahmedsleem.terminate_restart/internal", binaryMessenger: registrar.messenger())
        registrar.addMethodCallDelegate(instance, channel: channel)
    }
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "restart":
            handleRestartApp(call, result: result)
        case "gc":
            result(nil)
        default:
            result(FlutterMethodNotImplemented)
        }
    }
    
    private func handleRestartApp(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let clearData = args["clearData"] as? Bool,
              let preserveKeychain = args["preserveKeychain"] as? Bool,
              let preserveUserDefaults = args["preserveUserDefaults"] as? Bool,
              let terminate = args["terminate"] as? Bool else {
            result(FlutterError(code: "INVALID_ARGS", message: "Invalid arguments provided", details: nil))
            return
        }
        
        print("[TerminateRestart] Starting restart with clearData: \(clearData), terminate: \(terminate)")
        
        if clearData {
            print("[TerminateRestart] Starting data clearing...")
            clearAppData(preserveKeychain: preserveKeychain,
                        preserveUserDefaults: preserveUserDefaults) { [weak self] success, error in
                if let error = error {
                    print("[TerminateRestart] Data clearing failed: \(error)")
                    result(FlutterError(code: "DATA_CLEAR_ERROR", message: error.localizedDescription, details: nil))
                    return
                }
                print("[TerminateRestart] Data clearing completed successfully")
                DispatchQueue.main.async {
                    self?.performRestart(terminate: terminate, result: result)
                }
            }
        } else {
            performRestart(terminate: terminate, result: result)
        }
    }
    
    private func performRestart(terminate: Bool, result: @escaping FlutterResult) {
        // Ensure we're on the main thread
        if !Thread.isMainThread {
            DispatchQueue.main.async { [weak self] in
                self?.performRestart(terminate: terminate, result: result)
            }
            return
        }
        
        if terminate {
            performTerminateRestart(result: result)
        } else {
            performUIRestart(result: result)
        }
    }
    
    private func performTerminateRestart(result: @escaping FlutterResult) {
        guard let bundleId = Bundle.main.bundleIdentifier else {
            print("[TerminateRestart] Error: No bundle ID found")
            result(FlutterError(code: "NO_BUNDLE_ID", message: "No bundle identifier found", details: nil))
            return
        }
        
        guard let url = URL(string: "\(bundleId)://") else {
            print("[TerminateRestart] Error: Could not create URL")
            result(FlutterError(code: "URL_ERROR", message: "Could not create app URL", details: nil))
            return
        }
        
        // Save state indicating we're performing a restart
        UserDefaults.standard.set(true, forKey: "TerminateRestart_IsRestarting")
        UserDefaults.standard.synchronize()
        
        print("[TerminateRestart] Opening app URL: \(url)")
        
        guard UIApplication.shared.canOpenURL(url) else {
            print("[TerminateRestart] Error: Cannot open app URL. Make sure CFBundleURLTypes is configured in Info.plist")
            result(FlutterError(code: "URL_SCHEME_ERROR",
                                message: "Cannot open app URL. Configure CFBundleURLTypes with your bundle identifier in Info.plist",
                                details: nil))
            return
        }
        
        // Return success before restarting
        result(true)
        
        UIApplication.shared.open(url, options: [:]) { success in
            if !success {
                print("[TerminateRestart] Failed to open app URL")
            }
        }
        
        print("[TerminateRestart] Terminating app...")
        // Force suspend the app
        UIControl().sendAction(#selector(URLSessionTask.suspend), to: UIApplication.shared, for: nil)
        
        // Exit after a delay to ensure URL opening completes
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            exit(0)
        }
    }
    
    private func performUIRestart(result: @escaping FlutterResult) {
        print("[TerminateRestart] Performing UI-only restart...")
        
        guard let window = Self.findKeyWindow() else {
            print("[TerminateRestart] Error: No window found")
            result(FlutterError(code: "NO_WINDOW", message: "No window found", details: nil))
            return
        }
        
        guard let rootViewController = window.rootViewController else {
            print("[TerminateRestart] Error: No root controller found")
            result(FlutterError(code: "NO_ROOT_VC", message: "No root view controller found", details: nil))
            return
        }
        
        guard let flutterViewController = rootViewController as? FlutterViewController else {
            print("[TerminateRestart] Error: Root controller is not FlutterViewController")
            result(FlutterError(code: "NOT_FLUTTER_VC", message: "Root view controller is not a FlutterViewController", details: nil))
            return
        }
        
        // Get the existing engine (safe — we reuse it, no new engine creation)
        let engine = flutterViewController.engine
        
        // Return success before performing the restart
        result(true)
        
        // Disable user interaction during transition
        window.isUserInteractionEnabled = false
        
        print("[TerminateRestart] Recreating FlutterViewController with same engine...")
        
        // Create a new FlutterViewController with the SAME engine.
        // This gives a proper visual restart without creating a new engine
        // (which was the source of the old crash).
        let newFlutterViewController = FlutterViewController(engine: engine, nibName: nil, bundle: nil)
        
        // Replace the root view controller with animation
        UIView.transition(with: window,
                         duration: 0.3,
                         options: .transitionCrossDissolve,
                         animations: {
            window.rootViewController = newFlutterViewController
        }) { _ in
            // Re-enable user interaction
            window.isUserInteractionEnabled = true
            
            // Notify Dart side to rebuild the widget tree from scratch
            self.internalChannel?.invokeMethod("resetToRoot", arguments: nil)
            
            print("[TerminateRestart] UI restart completed")
        }
    }
    
    /// Find the key window using a method compatible with all iOS versions
    private static func findKeyWindow() -> UIWindow? {
        if #available(iOS 15.0, *) {
            // iOS 15+: use connectedScenes
            return UIApplication.shared.connectedScenes
                .compactMap { $0 as? UIWindowScene }
                .flatMap { $0.windows }
                .first { $0.isKeyWindow }
        } else if #available(iOS 13.0, *) {
            // iOS 13-14: use connectedScenes with windows
            return UIApplication.shared.connectedScenes
                .compactMap { $0 as? UIWindowScene }
                .flatMap { $0.windows }
                .first { $0.isKeyWindow }
        } else {
            // iOS 12 and below
            return UIApplication.shared.keyWindow
        }
    }
    
    private func clearAppData(preserveKeychain: Bool, preserveUserDefaults: Bool, completion: @escaping (Bool, Error?) -> Void) {
        // Use a serial queue for data clearing
        let clearQueue = DispatchQueue(label: "com.ahmedsleem.terminate_restart.clear")
        
        clearQueue.async {
            var clearError: Error?
            
            print("[TerminateRestart] Clearing UserDefaults...")
            // Clear UserDefaults if not preserved
            if !preserveUserDefaults {
                if let bundleId = Bundle.main.bundleIdentifier {
                    UserDefaults.standard.removePersistentDomain(forName: bundleId)
                    UserDefaults.standard.synchronize()
                }
            }
            
            print("[TerminateRestart] Clearing Keychain...")
            // Clear Keychain if not preserved
            if !preserveKeychain {
                let secItemClasses: [CFString] = [
                    kSecClassGenericPassword,
                    kSecClassInternetPassword,
                    kSecClassCertificate,
                    kSecClassKey,
                    kSecClassIdentity
                ]
                
                for itemClass in secItemClasses {
                    let spec: [String: Any] = [kSecClass as String: itemClass]
                    let status = SecItemDelete(spec as CFDictionary)
                    if status != errSecSuccess && status != errSecItemNotFound {
                        print("[TerminateRestart] Error clearing keychain item: \(status)")
                    }
                }
            }
            
            print("[TerminateRestart] Clearing files...")
            // Clear files synchronously
            do {
                let fileManager = FileManager.default
                
                // Clear app's document directory
                if let documentPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first {
                    let contents = try fileManager.contentsOfDirectory(at: documentPath, includingPropertiesForKeys: nil, options: [])
                    for fileUrl in contents {
                        do {
                            try fileManager.removeItem(at: fileUrl)
                        } catch {
                            print("[TerminateRestart] Error clearing document file \(fileUrl.lastPathComponent): \(error)")
                        }
                    }
                }
                
                // Clear app's cache directory
                if let cachePath = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first {
                    let contents = try fileManager.contentsOfDirectory(at: cachePath, includingPropertiesForKeys: nil, options: [])
                    for fileUrl in contents {
                        do {
                            try fileManager.removeItem(at: fileUrl)
                        } catch {
                            print("[TerminateRestart] Error clearing cache file \(fileUrl.lastPathComponent): \(error)")
                        }
                    }
                }
                
                // Clear app's temporary directory
                let tempPath = NSTemporaryDirectory()
                let contents = try fileManager.contentsOfDirectory(atPath: tempPath)
                for file in contents {
                    let filePath = (tempPath as NSString).appendingPathComponent(file)
                    do {
                        try fileManager.removeItem(atPath: filePath)
                    } catch {
                        print("[TerminateRestart] Error clearing temp file \(file): \(error)")
                    }
                }
            } catch {
                print("[TerminateRestart] Error accessing directories: \(error)")
                clearError = error
            }
            
            print("[TerminateRestart] Clearing cookies and cache...")
            // Clear cookies and cache
            if let cookies = HTTPCookieStorage.shared.cookies {
                for cookie in cookies {
                    HTTPCookieStorage.shared.deleteCookie(cookie)
                }
            }
            URLCache.shared.removeAllCachedResponses()
            
            print("[TerminateRestart] All data clearing operations completed")
            // Call completion on main queue
            DispatchQueue.main.async {
                completion(clearError == nil, clearError)
            }
        }
    }
}
