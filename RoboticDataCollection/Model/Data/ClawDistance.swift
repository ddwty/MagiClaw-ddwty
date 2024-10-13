//
//  Distance.swift
//  MagiClaw
//
//  Created by Tianyu on 10/2/24.
//

import Foundation
import math_h

struct ClawAngleData: Codable {
    let timeStamp: Double
    let angle: Float
    
    
    init(timeStamp: Double = 0.0, angle: Float = 0.0) {
        self.timeStamp = timeStamp
        self.angle = angle
    }
    
    static func calculateTheta(distance: Float) -> Float {
        let r: Float = 0.08
        let b: Float = 0.013311
        let d: Float = 0.0105
        var theta: Float = 0.0
        let minTheta: Float = 0.0
        let maxTheta: Float = 1.2
        
        let minDistance: Float = 0.047
        let maxDistance: Float = 0.195
        if distance == -1 {
            return -1
        }
        
//        if distance <= minDistance {
//            return 0.0
//        }
//        
//        if distance >= maxDistance {
//            return 1.0
//        }
    
        let temp = (0.5 * distance - b - d) / r
        
//        theta = asin(temp)
        if -1 <= temp && temp <= 1 {
            theta = asin(temp)
            let normalizedValue = (theta - minTheta) / (maxTheta - minTheta)
            return normalizedValue
        } else {
            return -1
        }
//        print("theta \(theta * 180 / Float.pi)")
    }
}

@Observable
class ClawAngleManager {
    static let shared = ClawAngleManager()
    var ClawAngleDataforShow: Float?
    var recordedAngleData: [ClawAngleData] = []
    var isRecording = false
    
    private init() {
        self.recordedAngleData.reserveCapacity(100000)
    }
    
    func startRecordingData() {
        self.recordedAngleData.removeAll()
        isRecording = true
    }
    
    func stopRecordingForceData() {
        isRecording = false
    }
    
    func recordAngleData(angle: Float) {
        guard isRecording, let elapsedTime = TimestampModel.shared.getElapsedTime() else { return }
        
        let angleData = ClawAngleData(timeStamp: elapsedTime, angle: angle)
        recordedAngleData.append(angleData)
    }
}

//class ClawAngleManager {
//    static let shared = ClawAngleManager()
//    var recordedAngleData: [ClawAngle] = []
//}
