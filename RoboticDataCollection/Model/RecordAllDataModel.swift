//
//  RecordAllDataModel.swift
//  talkWithRpi
//
//  Created by Tianyu on 7/22/24.
// 这里控制所有数据的录制开始/结束/保存,在这里创建了文件夹，保存到文件app，并生成三份数据的csv

import Foundation
import SwiftUI
import SwiftData

@Observable class RecordAllDataModel {
    private var isRecording = false
    
    let arRecorder = ARRecorder.shared
    
    private let motionManager = MotionManager.shared
    //    private let cameraManager = CameraManager.shared
    private let webSocketManager = WebSocketManager.shared
   
    
    // 用于为文件夹命名场景
//    private var scenarioName = SelectedScenario.shared.selectedScenario
    
    var scenarioName = Scenario.unspecified
    var description = "" // 暂时还没保存
    private var timer: Timer?
    private var recordingStartTime: Date?
    private var parentFolderURL: URL?
    
    // 用于记录这个数据录制时长
    var recordingDuration: TimeInterval = 0
    
    var recordedMotionData: [MotionData] = []
    var recordedForceData: [ForceData] = []
    var recordedRightForceData: [ForceData] = []
    var recordedARData: [ARData] = []
    var recordedAngleData: [AngleData] = []
    
    func startRecordingData() {
        guard !isRecording else { return }
        
//        recordedMotionData.removeAll()
        recordedForceData.removeAll()
        recordedARData.removeAll()
        recordedAngleData.removeAll()
        //            cameraManager.startRecording()
        
        // MARK: - 创建父文件夹, 以时间开头命名
        let documentDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMdd_HHmmss"
        let dateString = dateFormatter.string(from: Date())
        parentFolderURL = documentDirectory.appendingPathComponent(dateString + "_\(scenarioName.rawValue)")
        
        do {
            try FileManager.default.createDirectory(at: parentFolderURL!, withIntermediateDirectories: true, attributes: nil)
        } catch {
            print("Error creating parent folder: \(error.localizedDescription)")
            return
        }
        
        // 开始录制
        webSocketManager.startRecordingData()
        
        arRecorder.startRecording(parentFolderURL: parentFolderURL!) { success in
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
        arRecorder.stopRecording { videoURL in
                DispatchQueue.main.async {
                    guard let videoURL = videoURL, let parentFolderURL = self.parentFolderURL else {
                        print("Failed to get video URL or parent folder URL")
                        return
                    }
                }
            }
//      recordedMotionData = motionManager.motionDataArray
        recordedForceData = webSocketManager.recordedForceData
        recordedRightForceData = webSocketManager.recordedRightFingerForceData
        recordedAngleData = webSocketManager.recordedAngleData
        recordedARData = arRecorder.frameDataArray
        
        print("Recorded left force data length: \(recordedForceData.count), Recorded right force data length: \(recordedRightForceData.count), Angle data length: \(recordedAngleData.count), ar data length: \(recordedARData.count)")
        //        print("Force data:\(recordedForceData)")
        
        // 将其他数据保存为CSV
        self.generateCSV(in: parentFolderURL!)
        self.isRecording = false
        stopTimer()
        
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
    
    
    private func generateCSV(in parentFolderURL: URL) {
        DispatchQueue.global(qos: .userInitiated).async {
            let arCSVURL = self.exportToCSV(data: self.recordedARData, fileName: "PoseData", folderURL: parentFolderURL)
            let forceCSVURL = self.exportToCSV(data: self.recordedForceData, fileName: "L_ForceData", folderURL: parentFolderURL)
            let rightForceCSVURL = self.exportToCSV(data: self.recordedRightForceData, fileName: "R_ForceData", folderURL: parentFolderURL)
            let angleCSVURL = self.exportToCSV(data: self.recordedAngleData, fileName: "AngleData", folderURL: parentFolderURL)
            
            DispatchQueue.main.async {
                print("CSV files saved: \(arCSVURL?.absoluteString ?? ""), \(forceCSVURL?.absoluteString ?? ""), \(angleCSVURL?.absoluteString ?? "")")
                // Update UI or notify the user if needed
            }
        }
    }

    private func exportToCSV<T: CSVConvertible>(data: [T], fileName: String, folderURL: URL) -> URL? {
        let csvOutputURL = folderURL.appendingPathComponent(fileName).appendingPathExtension("csv")
        
        var csvText = data.first?.csvHeader() ?? ""
        for item in data {
            csvText.append("\(item.csvRow())\n")
        }
        
        do {
            try csvText.write(to: csvOutputURL, atomically: true, encoding: .utf8)
            return csvOutputURL
        } catch {
            print("Error saving CSV: \(error.localizedDescription)")
            return nil
        }
    }
    
}


