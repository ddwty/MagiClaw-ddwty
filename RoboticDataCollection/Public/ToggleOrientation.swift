//
//  ToggleOrientation.swift
//  MagiClaw
//
//  Created by Tianyu on 9/14/24.
//

import SwiftUI

/// 此处有警告BUG IN CLIENT OF UIKIT: Setting UIDevice.orientation is not supported. Please use UIWindowScene.requestGeometryUpdate(_:)
func toggleOrientation(isPortrait: inout Bool) {
    if isPortrait {
        // 切换到横屏
        AppDelegate.orientationLock = .landscape
        UIDevice.current.setValue(UIInterfaceOrientation.landscapeRight.rawValue, forKey: "orientation")
    } else {
        // 切换到竖屏
        AppDelegate.orientationLock = .portrait
        UIDevice.current.setValue(UIInterfaceOrientation.portrait.rawValue, forKey: "orientation")
    }
    
    // 更新支持的方向
    if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
        windowScene.keyWindow?.rootViewController?.setNeedsUpdateOfSupportedInterfaceOrientations()
    }
    isPortrait.toggle()
}



func resetOrientation() {
    UIDevice.current.setValue(UIInterfaceOrientation.unknown.rawValue ,forKey: "orientation")
    if let windowScene =
        UIApplication.shared.connectedScenes.first as? UIWindowScene {
        windowScene.keyWindow?.rootViewController?.setNeedsUpdateOfSupportedInterfaceOrientations()
        
    }
}

/// 以下消除了警告，但是旋转屏幕方向后，无法保持锁定
//    private func toggleOrientation() {
//        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
//            if #available(iOS 16.0, *) {
//                let desiredOrientations: UIInterfaceOrientationMask = isPortrait ? .landscapeRight : .portrait
//                let geometryPreferences = UIWindowScene.GeometryPreferences.iOS(interfaceOrientations: desiredOrientations)
//
//                windowScene.requestGeometryUpdate(geometryPreferences) { _ in
//
//                        isPortrait.toggle()
//                    }
//                }
//            } else {
//                // Fallback for iOS versions earlier than 16.0
//                // Unfortunately, programmatically changing orientation is not supported in earlier iOS versions
//                // You might want to display an alert or handle this gracefully
//                print("Changing orientation programmatically is not supported on iOS versions earlier than 16.0")
//            }
//        }

//    private func resetOrientation() {
//        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
//            let geometryPreferences = UIWindowScene.GeometryPreferences.iOS(interfaceOrientations: .all)
//            windowScene.requestGeometryUpdate(geometryPreferences) { _ in
//
//            }
//        }
//    }
