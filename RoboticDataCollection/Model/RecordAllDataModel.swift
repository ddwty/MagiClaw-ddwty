//
//  RecordAllDataModel.swift
//  talkWithRpi
//
//  Created by Tianyu on 7/22/24.
// 这里控制所有数据的录制开始/结束/保存,在这里创建了文件夹，保存到文件app，并生成三份数据的csv
#if os(iOS)
import Foundation
import SwiftUI
import SwiftData
import Zip

@Observable class RecordAllDataModel {
    private var isRecording = false
    public var isWaitingSaveing = false
    
    let arRecorder = ARRecorder.shared
    let audioRecorder = AudioRecorder.shared
    
    //    private let motionManager = MotionManager.shared
    //    private let cameraManager = CameraManager.shared
    private let webSocketManager = WebSocketManager.shared
    private let clawAngleManager = ClawAngleManager.shared
    private let settingModel = SettingModel.shared
    
    // TODO: - 保存进度
    private var savingProgress = SavingProgress.shared
    
    // 用于为文件夹命名场景
    //    private var scenarioName = SelectedScenario.shared.selectedScenario
    
    //    var scenarioName = Scenario.unspecified
    var scenarioName = "Unspecified"
    var description = ""
    
    private var timer: Timer?
    private var recordingStartTime: Date?
    private var parentFolderURL: URL?
    
    // 用于记录这个数据录制时长
    var recordingDuration: TimeInterval = 0
    
    //    var recordedMotionData: [MotionData] = []
    var recordedForceData: [ForceData] = []
    var recordedRightForceData: [ForceData] = []
    var recordedARData: [ARData] = []
//    var recordedAngleData: [AngleData] = []
    var recordedAngleData: [ClawAngleData] = []
    
    
    
    func startRecordingData() {
        guard !isRecording else { return }
       
        
        //        recordedMotionData.removeAll()
        recordedForceData.removeAll()
        recordedARData.removeAll()
        recordedAngleData.removeAll()
        recordedRightForceData.removeAll()
        //            cameraManager.startRecording()
        
        // MARK: - 创建父文件夹, 以时间开头命名
        let documentDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMdd_HHmmss"
        let dateString = dateFormatter.string(from: Date())
        parentFolderURL = documentDirectory.appendingPathComponent(dateString)
        
        do {
            try FileManager.default.createDirectory(at: parentFolderURL!, withIntermediateDirectories: true, attributes: nil)
        } catch {
            print("Error creating parent folder: \(error.localizedDescription)")
            return
        }
        
        // 开始录制
        TimestampModel.shared.startRecording()
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
        
        clawAngleManager.startRecordingData()
        audioRecorder.startRecording(parentFolderURL: parentFolderURL!)
        webSocketManager.isRecording = true
        
    }
    
    func stopRecordingData() {
        guard isRecording else { return }
        self.isWaitingSaveing = true
        TimestampModel.shared.stopRecording()
        webSocketManager.stopRecordingForceData()
        //        motionManager.stopRecording()
        arRecorder.stopRecording { videoURL in
            DispatchQueue.main.async {
                guard let videoURL = videoURL, let parentFolderURL = self.parentFolderURL else {
                    print("Failed to get video URL or parent folder URL")
                    return
                }
            }
        }
        clawAngleManager.stopRecordingForceData()
        audioRecorder.stopRecording()
        //        DispatchQueue.global(qos: .userInitiated).async {
        
        //      recordedMotionData = motionManager.motionDataArray
        recordedForceData = webSocketManager.recordedForceData
        recordedRightForceData = webSocketManager.recordedRightFingerForceData
//        recordedAngleData = webSocketManager.recordedAngleData
        recordedAngleData = clawAngleManager.recordedAngleData
        recordedARData = arRecorder.frameDataArray
        
        
        
        //        print("Recorded left force data length: \(recordedForceData.count), Recorded right force data length: \(recordedRightForceData.count), Angle data length: \(recordedAngleData.count), ar data length: \(recordedARData.count)")
        //        print("Force data:\(recordedForceData)")
        
        // 将其他数据保存为CSV
        self.generateCSV(in: parentFolderURL!)
        
        let currentDate = Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd_HH:mm:ss"
        formatter.timeZone = TimeZone(identifier: "UTC")
        let dateString = formatter.string(from: currentDate)
        let metaData = MetaData(
            fileUUID: UUID().uuidString,
            userID: nil,
            createTime: dateString,
            description: self.description,
            scenario: self.scenarioName,
            leftForceDataSize: recordedForceData.count,
            rightForceDataSize: recordedRightForceData.count,
            angleDataSize: recordedAngleData.count,
            ARDataSize: recordedARData.count,
            position: SettingModel.shared.devicePosition,
            deviceModel: UIDevice.current.model,
            systemName: UIDevice.current.systemName,
            systemVersion: UIDevice.current.systemVersion,
            appVersion: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown")
        saveMetaDatatoJson(from: metaData, to: parentFolderURL!)
        
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
            
            // 检查是否所有文件都成功生成
            guard arCSVURL != nil, forceCSVURL != nil, rightForceCSVURL != nil, angleCSVURL != nil else {
                print("Failed to save one or more CSV files.")
                return
            }
            
            print("CSV files saved: \(arCSVURL!.absoluteString), \(forceCSVURL!.absoluteString), \(rightForceCSVURL!.absoluteString), \(angleCSVURL!.absoluteString)")
            
            // 生成CSV文件后，压缩文件夹
            if self.settingModel.saveZipFile {
                self.zipFolder(at: parentFolderURL)
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
    
    // MARK: - 压缩文件夹
    private func zipFolder(at folderURL: URL) {
        let zipURL = folderURL.appendingPathExtension("magiclaw")
        
        do {
            //            try Zip.zipFiles(paths: [folderURL], zipFilePath: zipURL, password: nil, progress: nil)
            try Zip.zipFiles(paths: [folderURL], zipFilePath: zipURL, password: nil, progress: {(progress) -> () in
                print(progress)
            })
            print("Folder successfully zipped at \(zipURL.absoluteString)")
            
            // 删除原来的文件夹
            try FileManager.default.removeItem(at: folderURL)
            print("Original folder successfully deleted at \(folderURL.absoluteString)")
        } catch {
            print("Error zipping folder: \(error.localizedDescription)")
        }
    }
    
    private func saveMetaDatatoJson(from metadata: MetaData, to parentFolderURL: URL) {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                let data = try encoder.encode(metadata)
                let url = parentFolderURL.appendingPathComponent("metadata.json")
                try data.write(to: url)
                print("Metadata Json file saved.")
            } catch {
                print("Error saving metadata to json.")
            }
        }
    }
    
    
}


#endif
