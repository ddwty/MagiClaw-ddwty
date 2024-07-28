//
//  MotionDataModel.swift
//  talkWithRpi
//
//  Created by Tianyu on 7/19/24.
//

import Foundation
import CoreMotion
import SwiftUI

struct MotionData: Identifiable {
    var id: UUID
    var timestamp: Date
    var attitude: Attitude
    var rotationRate: RotationRate
    var acceleration: CMAcceleration
    var rotationMatrix: CMRotationMatrix
    var quaternion: CMQuaternion
    
    // Euler angle
    struct Attitude {
        var pitch: Double
        var yaw: Double
        var roll: Double
        var pitchDegrees: Double {
            return (pitch * 180) / Double.pi
        }
        
        var yawDegrees: Double {
            return (yaw * 180) / Double.pi
        }
        
        var rollDegrees: Double {
            return (roll * 180) / Double.pi
        }
    }
    
    struct RotationRate {
        var xRotationRate: Double
        var yRotationRate: Double
        var zRotationRate: Double
    }
    
    init(id: UUID = UUID(), timestamp: Date, attitude: Attitude, rotationRate: RotationRate, acceleration: CMAcceleration, rotationMatrix: CMRotationMatrix, quaternion: CMQuaternion) {
        self.id = id
        self.timestamp = timestamp
        self.attitude = attitude
        self.rotationRate = rotationRate
        self.acceleration = acceleration
        self.rotationMatrix = rotationMatrix
        self.quaternion = quaternion
    }
}
class MotionManager: ObservableObject {
    static let shared = MotionManager()
        
    private let motionManager = CMMotionManager()
    private var timer: Timer?
    private var startTime: Date?
    private var dataCount: Int = 0
    private var initialAttitude: CMAttitude?
    
    @Published var motionData: MotionData
    @Published var motionDataArray: [MotionData] = [] // 用于可视化
    @Published var recordedMotionData: [MotionData] = [] //用于储存,还没开始做
    @Published var useHighAccuracy: Bool = false
    @Published var isRecording = false
    
    let queue = OperationQueue()
    
   private init() {
        self.motionData = MotionData(
            timestamp: Date(),
            attitude: MotionData.Attitude(pitch: 0.0, yaw: 0.0, roll: 0.0),
            rotationRate: MotionData.RotationRate(xRotationRate: 0.0, yRotationRate: 0.0, zRotationRate: 0.0),
            acceleration: CMAcceleration(), rotationMatrix: CMRotationMatrix(),
            quaternion: CMQuaternion()
        )
#if targetEnvironment(simulator)
        self.motionDataArray = generateTestMotionData()
        self.motionData = MotionData(
            timestamp: Date(),
            attitude: MotionData.Attitude(pitch: 1, yaw: 1, roll: 1),
            rotationRate: MotionData.RotationRate(xRotationRate: 0.0, yRotationRate: 0.0, zRotationRate: 0.0),
            acceleration: CMAcceleration(), rotationMatrix: CMRotationMatrix(),
            quaternion: CMQuaternion()
        )
#else
        self.motionData = MotionData(
            timestamp: Date(),
            attitude: MotionData.Attitude(pitch: 0.0, yaw: 0.0, roll: 0.0),
            rotationRate: MotionData.RotationRate(xRotationRate: 0.0, yRotationRate: 0.0, zRotationRate: 0.0),
            acceleration: CMAcceleration(), rotationMatrix: CMRotationMatrix(),
            quaternion: CMQuaternion()
        )
#endif
    }
    
    func startUpdates() {
        if motionManager.isDeviceMotionAvailable {
            motionManager.deviceMotionUpdateInterval = 1/30
            motionManager.startDeviceMotionUpdates(using: useHighAccuracy ? .xArbitraryCorrectedZVertical : .xArbitraryZVertical, to: queue) { [weak self] data, error in
                guard let self = self, let data = data else { return }
                if self.initialAttitude == nil {
                    self.initialAttitude = data.attitude
                }
                
                            let attitude = data.attitude
                            let rotationRate = data.rotationRate
                
                            DispatchQueue.main.async {
                                self.motionData = MotionData(
                                    timestamp: Date(),
                                    attitude: MotionData.Attitude(pitch: attitude.pitch, yaw: attitude.yaw, roll: attitude.roll),
                                    rotationRate: MotionData.RotationRate(xRotationRate: rotationRate.x, yRotationRate: rotationRate.y, zRotationRate: rotationRate.z),
                                    acceleration: data.userAcceleration, rotationMatrix: attitude.rotationMatrix,
                                    quaternion: attitude.quaternion
                                )
                                if self.motionDataArray.count > 100 {
                                    self.motionDataArray.removeFirst()
                                }
                                
                                self.motionDataArray.append(self.motionData)
                            }
                
                // 计算相对于初始姿态的变化
//                let relativeAttitude = data.attitude
//                relativeAttitude.multiply(byInverseOf: self.initialAttitude!)
//                
//                let rotationRate = data.rotationRate
//                
//                DispatchQueue.main.async {
//                    self.motionData = MotionData(
//                        timestamp: Date(),
//                        attitude: MotionData.Attitude(pitch: relativeAttitude.pitch, yaw: relativeAttitude.yaw, roll: relativeAttitude.roll),
//                        rotationRate: MotionData.RotationRate(xRotationRate: rotationRate.x, yRotationRate: rotationRate.y, zRotationRate: rotationRate.z),
//                        acceleration: data.userAcceleration, rotationMatrix: relativeAttitude.rotationMatrix,
//                        quaternion: relativeAttitude.quaternion
//                    )
//                    if self.motionDataArray.count > 50 {
//                        self.motionDataArray.removeFirst()
//                    }
//                    self.motionDataArray.append(self.motionData)
//                }
            }
        }
    }
    
    //    func startUpdates() {
    //        startDeviceMotionUpdates()
    //    }
    
    func startRecording() {
        recordedMotionData.removeAll()
        recordedMotionData.reserveCapacity(10000)
        isRecording = true
        
    }
    
    func stopRecording() {
        isRecording = false
    }
    
    func stopUpdates() {
        motionManager.stopDeviceMotionUpdates()
    }
    
    func resetReferenceFrame() {
        stopUpdates()
        initialAttitude = nil
        startUpdates()
    }
    
    
    func generateTestMotionData() -> [MotionData] {
        var motionDataArray: [MotionData] = []
        let currentTime = Date()
        
        for i in 0..<50 {
            let timestamp = currentTime.addingTimeInterval(TimeInterval(i))
            
            let angle = Double(i) * 0.1
            let attitude = MotionData.Attitude(
                pitch: sin(angle),
                yaw: cos(angle),
                roll: sin(angle) * cos(angle)
            )
            
            let rotationRate = MotionData.RotationRate(
                xRotationRate: sin(angle) * 0.5,
                yRotationRate: cos(angle) * 0.5,
                zRotationRate: sin(angle) * cos(angle) * 0.5
            )
            
            let motionData = MotionData(
                timestamp: timestamp,
                attitude: attitude,
                rotationRate: rotationRate,
                acceleration: CMAcceleration(),
                rotationMatrix: CMRotationMatrix(),
                quaternion: CMQuaternion()
            )
            
            motionDataArray.append(motionData)
        }
        
        return motionDataArray
    }
    
}
