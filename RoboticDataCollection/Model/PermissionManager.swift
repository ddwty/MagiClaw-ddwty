//
//  PermissionManager.swift
//  MagiClaw
//
//  Created by Tianyu on 9/16/24.
//

import AVFoundation
import UIKit
import Network

enum PermissionType {
    case camera
    case microphone
    case localNetwork
}

import AVFoundation
import UIKit
import Network

class PermissionManager {
    
    static let shared = PermissionManager()
    
    private init() {}
    
    /// 检查相机权限
    func checkCameraPermission(completion: @escaping (Bool) -> Void) {
        let cameraStatus = AVCaptureDevice.authorizationStatus(for: .video)
        switch cameraStatus {
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async {
                    completion(granted)
                }
            }
        case .denied, .restricted:
            completion(false)
        case .authorized:
            completion(true)
        @unknown default:
            completion(false)
        }
    }
    
    /// 检查麦克风权限
    func checkMicrophonePermission(completion: @escaping (Bool) -> Void) {
        let micStatus = AVAudioSession.sharedInstance().recordPermission
        switch micStatus {
        case .undetermined:
            AVAudioSession.sharedInstance().requestRecordPermission { granted in
                DispatchQueue.main.async {
                    completion(granted)
                }
            }
        case .denied:
            completion(false)
        case .granted:
            completion(true)
        @unknown default:
            completion(false)
        }
    }
    
    /// 检查本地网络权限
    func checkLocalNetworkPermission(completion: @escaping (Bool) -> Void) {
        let monitor = NWPathMonitor(requiredInterfaceType: .wifi)
        monitor.pathUpdateHandler = { path in
            if path.status == .satisfied {
                DispatchQueue.main.async {
                    completion(true)
                }
            } else {
                DispatchQueue.main.async {
                    completion(false)
                }
            }
            monitor.cancel()
        }
        let queue = DispatchQueue(label: "LocalNetworkMonitor")
        monitor.start(queue: queue)
    }
    
    /// 根据指定的权限数组检查权限
    func checkPermissions(_ permissions: [PermissionType], completion: @escaping ([PermissionType: Bool]) -> Void) {
        var results = [PermissionType: Bool]()
        
        let group = DispatchGroup()
        
        for permission in permissions {
            switch permission {
            case .camera:
                group.enter()
                checkCameraPermission { granted in
                    results[.camera] = granted
                    group.leave()
                }
            case .microphone:
                group.enter()
                checkMicrophonePermission { granted in
                    results[.microphone] = granted
                    group.leave()
                }
            case .localNetwork:
                group.enter()
                checkLocalNetworkPermission { granted in
                    results[.localNetwork] = granted
                    group.leave()
                }
            }
        }
        
        // 所有权限检查完毕后回调
        group.notify(queue: .main) {
            completion(results)
        }
    }
    
    /// 打开应用设置
    func openAppSettings() {
        if let appSettings = URL(string: UIApplication.openSettingsURLString) {
            if UIApplication.shared.canOpenURL(appSettings) {
                UIApplication.shared.open(appSettings)
            }
        }
    }
}
import SwiftUI

struct PermissionsModifier: ViewModifier {
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var deniedPermissions: [PermissionType] = []
    
    var permissions: [PermissionType]
    
    func body(content: Content) -> some View {
        content
            .onAppear {
                checkPermissions()
            }
            .alert(isPresented: $showAlert) {
                Alert(
                    title: Text("Permissions Required"),
                    message: Text(alertMessage),
                    primaryButton: .default(Text("Go to Settings")) {
                        PermissionManager.shared.openAppSettings()
                    },
                    secondaryButton: .cancel(Text("Cancel"))
                )
            }
    }
    
    private func checkPermissions() {
        PermissionManager.shared.checkPermissions(permissions) { results in
            deniedPermissions = results.filter { !$0.value }.map { $0.key }
            if !deniedPermissions.isEmpty {
                alertMessage = generateAlertMessage()
                showAlert = true
            }
        }
    }
    
    private func generateAlertMessage() -> String {
        let permissionNames = deniedPermissions.map { permissionName(for: $0) }
        let permissionList = permissionNames.joined(separator: ", ")
        return "To ensure the app functions properly, we need the following permissions:\n\n\(permissionList)\n\nPlease enable these permissions in the Settings."
    }
    
    private func permissionName(for permission: PermissionType) -> String {
        switch permission {
        case .camera:
            return "Camera"
        case .microphone:
            return "Microphone"
        case .localNetwork:
            return "Local Network"
        }
    }
}


extension View {
    func checkPermissions(_ permissions: [PermissionType]) -> some View {
        self.modifier(PermissionsModifier(permissions: permissions))
    }
}
