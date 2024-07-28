//
//  RecordAllDataModel.swift
//  talkWithRpi
//
//  Created by Tianyu on 7/22/24.
// 这里控制所有数据的录制开始/结束/保存

import Foundation
import SwiftUI
import SwiftData

class RecordAllDataModel: ObservableObject {
    private var isRecording = false
    let arRecorder = ARRecorder.shared
    
    private let motionManager = MotionManager.shared
    //    private let cameraManager = CameraManager.shared
    private let webSocketManager = WebSocketManager.shared
//    private let arRecorder = ARRecorder.shared
    
    
    private var timer: Timer?
    private var recordingStartTime: Date?
    
    // TODO: - 这个好像没用吧
    @Published var recordingDuration: TimeInterval = 0
    
    var recordedMotionData: [MotionData] = []
    var recordedForceData: [ForceData?] = []
    var recordedARData: [ARData] = []
//    var recordedARTransformData: [] = []
    
    func startRecordingData() {
        guard !isRecording else { return }
        
        recordedMotionData.removeAll()
        recordedForceData.removeAll()
        recordedARData.removeAll()
        
        //            cameraManager.startRecording()
        
        webSocketManager.startRecordingForceData()
        
        arRecorder.startRecording { success in
            DispatchQueue.main.async {
                if success {
                    self.recordingStartTime = Date()
                    self.isRecording = true
                    self.startTimer()
                } else {
                    print("Failed to start AR recording")
                }
            }
        }
        webSocketManager.isRecording = true
        
    }
    
    func stopRecordingData() {
        guard isRecording else { return }
        
        //            motionManager.stopUpdates()
        //            cameraManager.stopRecording()
        webSocketManager.stopRecordingForceData()
        motionManager.stopRecording()
        arRecorder.stopRecording() { url in
                    DispatchQueue.main.async {
                        if let url = url {
                            print("Video saved to: \(url.absoluteString)")
                        } else {
                            print("Failed to save video")
                        }
                    }
        }
        
        recordedMotionData = motionManager.motionDataArray
        recordedForceData = webSocketManager.recordedForceData
        recordedARData = arRecorder.frameDataArray
        print("Recorded force data length: \(recordedForceData.count), ar data length: \(recordedARData.count)")
        print("Force data:\(recordedForceData)")
        print("ARData: \(recordedARData)")
        
        
        self.isRecording = false
        
        stopTimer()
        
// Create ARStorgeData
//        let createTime = Date()
//        let timeDuration = recordingDuration
//        let arStorageData = ARStorgeData(createTime: createTime, timeDuration: timeDuration, data: recordedARData)
//        
//        // Here you can save arStorageData to your desired storage or further process it
//        
//        // Save to persistent storage
//            saveARStorageData(arStorageData)

    }
}

// TODO: - 放到control button视图中
extension RecordAllDataModel {
    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 0.01, repeats: true) { [weak self] _ in
            guard let self = self, let startTime = self.recordingStartTime else { return }
            self.recordingDuration = Date().timeIntervalSince(startTime)
        }
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    // mm:ss:ms
    func formattedDuration() -> String {
        let minutes = Int(recordingDuration) / 60
        let seconds = Int(recordingDuration) % 60
        let milliseconds = Int((recordingDuration - TimeInterval(minutes * 60 + seconds)) * 1000)
        return String(format: "%02d:%02d:%2d", minutes, seconds, milliseconds)
    }
    
    
//    private func saveARStorageData(_ arStorageData: ARStorgeData) {
//        // Implement the logic to save arStorageData
//        // For example, using Core Data, Realm, or writing to a file
//    }
    
}


