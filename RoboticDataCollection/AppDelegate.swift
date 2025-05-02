//
//  AppDelegate.swift
//  MagiClaw
//
//  Created by Tianyu on 8/31/24.
//


import SwiftUI
#if os(iOS)

class AppDelegate: NSObject, UIApplicationDelegate {
    static var orientationLock: UIInterfaceOrientationMask = .all
    
    func application(_ application: UIApplication, supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
        return AppDelegate.orientationLock
    }
    
    static var forceOrientationLock = UIInterfaceOrientationMask.portrait {
            didSet {
                if #available(iOS 16.0, *) {
                    UIApplication.shared.connectedScenes.forEach { scene in
                        if let windowScene = scene as? UIWindowScene {
                            windowScene.requestGeometryUpdate(.iOS(interfaceOrientations: forceOrientationLock))
                        }
                    }
                    UIViewController.attemptRotationToDeviceOrientation()
                } else {
                    if forceOrientationLock == .landscape {
                        UIDevice.current.setValue(UIInterfaceOrientation.landscapeRight.rawValue, forKey: "orientation")
                    } else {
                        UIDevice.current.setValue(UIInterfaceOrientation.portrait.rawValue, forKey: "orientation")
                    }
                }
            }
        }
        
        func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
            return true
        }
}
#endif
