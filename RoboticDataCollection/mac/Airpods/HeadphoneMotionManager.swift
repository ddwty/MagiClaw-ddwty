//
//  HeadphoneMotionManager.swift
//  MagiClaw
//
//  Created by Tianyu on 4/16/25.
//

import Foundation

import CoreMotion
import Foundation

class HeadphoneMotionManager: ObservableObject {
    private let motionManager = CMHeadphoneMotionManager()
    @Published var motionData: CMDeviceMotion?
    @Published var isConnected = false
    @Published var errorMessage: String?
    @Published var calibrationQuaternion: CMQuaternion?
    
    // 添加回调闭包属性
    var onMotionDataUpdate: ((CMDeviceMotion) -> Void)?
    
    init() {
        checkAvailability()
    }
    
    func checkAvailability() {
        if motionManager.isDeviceMotionAvailable {
            startUpdates()
        } else {
            errorMessage = "Headphone motion is not available"
        }
    }
    
    func startUpdates() {
        motionManager.startDeviceMotionUpdates(to: .main) { [weak self] (data, error) in
            guard let self = self else { return }
            
            if let error = error {
                self.errorMessage = error.localizedDescription
                self.isConnected = false
                return
            }
            
            if let data = data {
                self.motionData = data
                self.isConnected = true
                self.errorMessage = nil
                
                // 调用回调函数通知数据更新
                self.onMotionDataUpdate?(data)
            }
        }
    }
    
    func stopUpdates() {
        motionManager.stopDeviceMotionUpdates()
        isConnected = false
    }
    
    func calibrate() {
        if let currentData = motionData {
            calibrationQuaternion = currentData.attitude.quaternion
        }
    }
    
    deinit {
        stopUpdates()
    }
}
