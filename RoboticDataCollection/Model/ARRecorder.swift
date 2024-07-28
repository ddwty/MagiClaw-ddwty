//
//  ARRecorder.swift
//  talkWithRpi
//
//  Created by Tianyu on 7/25/24.
//
import Foundation
import AVFoundation
import Photos
import ARKit
import SwiftData

class ARRecorder: NSObject, ObservableObject {
    static let shared = ARRecorder()
    
    private var assetWriter: AVAssetWriter?
    private var assetWriterInput: AVAssetWriterInput?
    private var pixelBufferAdaptor: AVAssetWriterInputPixelBufferAdaptor?
    private var isRecording = false
    private var frameNumber: Int64 = 0
    private var videoOutputURL: URL?
    private var timestamps: [Double] = []
    var frameDataArray: [ARData] = []
    
    private override init() {
        super.init()
    }
    

    
    // 每一帧都在调用
    func recordFrame(_ frame: ARFrame) {
        // recording之后才执行下面代码
        guard isRecording, let pixelBufferAdaptor = pixelBufferAdaptor, let assetWriterInput = assetWriterInput else { return }
        
        if assetWriterInput.isReadyForMoreMediaData {
            let depthBuffer = frame.sceneDepth?.depthMap
            let pixelBuffer = frame.capturedImage
            
            // TODO: - 和AR帧率保持一致
            let presentationTime = CMTime(value: frameNumber, timescale: 30)
            
            if pixelBufferAdaptor.append(pixelBuffer, withPresentationTime: presentationTime) {
                frameNumber += 1
                
                if let depthBuffer = depthBuffer {
                    // 处理深度信息
                }
                
                // 添加每帧的时间戳和相机变换矩阵到数组中
                let frameData = ARData(timestamp: frame.timestamp, transform: frame.camera.transform)
                self.frameDataArray.append(frameData)
                
            } else {
                print("Error appending pixel buffer")
            }
        }
    }
    
    func startRecording(completion: @escaping (Bool) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyyMMdd_HHmmss"
            let dateString = dateFormatter.string(from: Date())
            
            let tempDirectory = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
            self.videoOutputURL = tempDirectory.appendingPathComponent(dateString + "hahah").appendingPathExtension("mp4")
            
            do {
                guard let videoOutputURL = self.videoOutputURL else {
                    DispatchQueue.main.async {
                        completion(false)
                    }
                    return
                }
                self.assetWriter = try AVAssetWriter(outputURL: videoOutputURL, fileType: .mp4)
                
                let outputSettings: [String: Any] = [
                    AVVideoCodecKey: AVVideoCodecType.h264,
                    AVVideoWidthKey: 1920,
                    AVVideoHeightKey: 1080
                ]
                
                self.assetWriterInput = AVAssetWriterInput(mediaType: .video, outputSettings: outputSettings)
                self.assetWriterInput?.expectsMediaDataInRealTime = true
                
                self.pixelBufferAdaptor = AVAssetWriterInputPixelBufferAdaptor(assetWriterInput: self.assetWriterInput!, sourcePixelBufferAttributes: nil)
                
                if let assetWriter = self.assetWriter, let assetWriterInput = self.assetWriterInput {
                    if assetWriter.canAdd(assetWriterInput) {
                        assetWriter.add(assetWriterInput)
                    }
                    
                    assetWriter.startWriting()
                    assetWriter.startSession(atSourceTime: .zero)
                    self.frameDataArray.removeAll() // 清空数组以开始新的录制
                    
                    self.isRecording = true
                    self.frameNumber = 0
                    
                    DispatchQueue.main.async {
                        completion(true)
                    }
                }
            } catch {
                print("Error starting recording: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    completion(false)
                }
            }
        }
    }
    
    func stopRecording(completion: @escaping (URL?) -> Void) {
            guard isRecording else { return }
            
            isRecording = false
            assetWriterInput?.markAsFinished()
            
            assetWriter?.finishWriting { [weak self] in
                guard let self = self else { return }
                self.saveVideoToPhotoLibrary(videoURL: self.videoOutputURL)
                completion(self.assetWriter?.outputURL)
                
                // 保存记录到 SwiftData
//                if let url = self.assetWriter?.outputURL {
//                    let duration = self.calculateRecordingDuration()
//                    let recordingHistory = RecordingHistory(date: Date(), fileURL: url, duration: duration, frameDataArray: self.frameDataArray)
//                    modelContext.insert(recordingHistory)
//                    
//                    do {
//                        try modelContext.save()
//                    } catch {
//                        print("Failed to save recording history: \(error.localizedDescription)")
//                    }
//                }
            }
        }
    
    private func calculateRecordingDuration() -> TimeInterval {
            // 计算录制的持续时间
            return TimeInterval(frameNumber) / 30.0 // Assuming 30 FPS
        }
    
    private func saveVideoToPhotoLibrary(videoURL: URL?) {
        guard let videoURL = videoURL else { return }
        
        PHPhotoLibrary.requestAuthorization { status in
            guard status == .authorized else { return }
            
            PHPhotoLibrary.shared().performChanges({
                PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: videoURL)
            }) { success, error in
                if let error = error {
                    print("Error saving video: \(error.localizedDescription)")
                } else {
                    print("Video saved successfully to Photo Library")
                }
            }
        }
    }
    
    
}

