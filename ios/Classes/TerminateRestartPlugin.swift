import Flutter
import UIKit

public class TerminateRestartPlugin: NSObject, FlutterPlugin {
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "com.ahmedsleem.terminate_restart/restart", binaryMessenger: registrar.messenger())
        let instance = TerminateRestartPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "restart":
            handleRestartApp(call, result: result)
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
        
        print(" [TerminateRestart] Starting restart with clearData: \(clearData), terminate: \(terminate)")
        
        // Return success early to allow Flutter to clean up
        result(true)
        
        // Perform restart with data clearing if needed
        if clearData {
            print(" [TerminateRestart] Starting data clearing...")
            clearAppData(preserveKeychain: preserveKeychain,
                        preserveUserDefaults: preserveUserDefaults) { [weak self] success, error in
                if let error = error {
                    print(" [TerminateRestart] Data clearing failed: \(error)")
                    return
                }
                print(" [TerminateRestart] Data clearing completed successfully")
                DispatchQueue.main.async {
                    self?.performRestart(terminate: terminate)
                }
            }
        } else {
            performRestart(terminate: terminate)
        }
    }
    
    private func performRestart(terminate: Bool) {
        // Ensure we're on the main thread
        if !Thread.isMainThread {
            DispatchQueue.main.async { [weak self] in
                self?.performRestart(terminate: terminate)
            }
            return
        }
        
        if terminate {
            // Create a new instance of the app
            if let bundleId = Bundle.main.bundleIdentifier {
                let url = URL(string: "\(bundleId)://")!
                
                // Save state indicating we're performing a restart
                UserDefaults.standard.set(true, forKey: "TerminateRestart_IsRestarting")
                UserDefaults.standard.synchronize()
                
                print(" [TerminateRestart] Opening app URL: \(url)")
                
                if UIApplication.shared.canOpenURL(url) {
                    UIApplication.shared.open(url, options: [:]) { success in
                        if !success {
                            print(" [TerminateRestart] Failed to open app URL")
                        }
                    }
                    
                    print(" [TerminateRestart] Terminating app...")
                    // Force suspend the app
                    UIControl().sendAction(#selector(URLSessionTask.suspend), to: UIApplication.shared, for: nil)
                    
                    // Exit after a delay to ensure URL opening completes
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        exit(0)
                    }
                } else {
                    print(" [TerminateRestart] Error: Cannot open app URL")
                }
            } else {
                print(" [TerminateRestart] Error: No bundle ID found")
            }
        } else {
            print(" [TerminateRestart] Performing UI-only restart...")
            
            guard let window = UIApplication.shared.keyWindow ?? UIApplication.shared.windows.first else {
                print(" [TerminateRestart] Error: No window found")
                return
            }
            
            guard let rootViewController = window.rootViewController else {
                print(" [TerminateRestart] Error: No root controller found")
                return
            }
            
            guard let flutterViewController = rootViewController as? FlutterViewController else {
                print(" [TerminateRestart] Error: Root controller is not FlutterViewController")
                return
            }
            
            print(" [TerminateRestart] Creating new Flutter view controller")
            
            // Disable user interaction during transition
            window.isUserInteractionEnabled = false
            
            // Get the Flutter engine
            guard let flutterEngine = flutterViewController.engine as? FlutterEngine else {
                print(" [TerminateRestart] Error: No Flutter engine found")
                return
            }
            
            // Create a new engine
            let newEngine = FlutterEngine(name: "restart_engine")
            guard newEngine.run() else {
                print(" [TerminateRestart] Error: Failed to run new engine")
                return
            }
            
            // Create a new Flutter view controller with the new engine
            let newFlutterViewController = FlutterViewController(engine: newEngine, nibName: nil, bundle: nil)
            
            // Register plugins using FlutterPluginRegistrant
            if let registrantClass = NSClassFromString("GeneratedPluginRegistrant") as? NSObject.Type {
                let registrant = registrantClass.init()
                if registrant.responds(to: Selector(("registerWithRegistry:"))) {
                    registrant.perform(Selector(("registerWithRegistry:")), with: newEngine)
                }
            }
            
            // Set up method channels on the new engine
            let channel = FlutterMethodChannel(name: "com.ahmedsleem.terminate_restart/restart", binaryMessenger: newEngine.binaryMessenger)
            let internalChannel = FlutterMethodChannel(name: "com.ahmedsleem.terminate_restart/internal", binaryMessenger: newEngine.binaryMessenger)
            
            // Register our plugin with the new engine
            if let registrar = newEngine.registrar(forPlugin: "TerminateRestartPlugin") {
                let instance = TerminateRestartPlugin()
                registrar.addMethodCallDelegate(instance, channel: channel)
            }
            
            // Perform the view controller replacement with animation
            UIView.transition(with: window,
                            duration: 0.3,
                            options: .transitionCrossDissolve,
                            animations: {
                // Remove old view controller
                flutterViewController.willMove(toParent: nil)
                flutterViewController.view.removeFromSuperview()
                flutterViewController.removeFromParent()
                
                // Set new view controller
                window.rootViewController = newFlutterViewController
            }) { _ in
                // Re-enable user interaction
                window.isUserInteractionEnabled = true
                
                // Clean up old engine
                flutterEngine.destroyContext()
                
                // Reset navigation on new engine
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    internalChannel.invokeMethod("resetToRoot", arguments: nil)
                    print(" [TerminateRestart] UI restart completed")
                }
            }
        }
    }
    
    private func clearAppData(preserveKeychain: Bool, preserveUserDefaults: Bool, completion: @escaping (Bool, Error?) -> Void) {
        // Use a serial queue for data clearing
        let clearQueue = DispatchQueue(label: "com.ahmedsleem.terminate_restart.clear")
        
        clearQueue.async {
            var clearError: Error?
            
            print(" [TerminateRestart] Clearing UserDefaults...")
            // Clear UserDefaults if not preserved
            if !preserveUserDefaults {
                if let bundleId = Bundle.main.bundleIdentifier {
                    UserDefaults.standard.removePersistentDomain(forName: bundleId)
                    UserDefaults.standard.synchronize()
                }
            }
            
            print(" [TerminateRestart] Clearing Keychain...")
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
                    let spec: [String: Any] = [
                        kSecClass as String: itemClass,
                        kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock
                    ]
                    let status = SecItemDelete(spec as CFDictionary)
                    if status != errSecSuccess && status != errSecItemNotFound {
                        print(" [TerminateRestart] Error clearing keychain item: \(status)")
                    }
                }
            }
            
            print(" [TerminateRestart] Clearing files...")
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
                            print(" [TerminateRestart] Error clearing document file \(fileUrl.lastPathComponent): \(error)")
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
                            print(" [TerminateRestart] Error clearing cache file \(fileUrl.lastPathComponent): \(error)")
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
                        print(" [TerminateRestart] Error clearing temp file \(file): \(error)")
                    }
                }
            } catch {
                print(" [TerminateRestart] Error accessing directories: \(error)")
                clearError = error
            }
            
            print(" [TerminateRestart] Clearing cookies and cache...")
            // Clear cookies and cache
            if let cookies = HTTPCookieStorage.shared.cookies {
                for cookie in cookies {
                    HTTPCookieStorage.shared.deleteCookie(cookie)
                }
            }
            URLCache.shared.removeAllCachedResponses()
            
            print(" [TerminateRestart] All data clearing operations completed")
            // Call completion on main queue
            DispatchQueue.main.async {
                completion(clearError == nil, clearError)
            }
        }
    }
}
