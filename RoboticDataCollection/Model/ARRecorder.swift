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

class ARRecorder: NSObject, ObservableObject {
    static let shared = ARRecorder()
    
    private var assetWriter: AVAssetWriter?
    private var assetWriterInput: AVAssetWriterInput?
    private var pixelBufferAdaptor: AVAssetWriterInputPixelBufferAdaptor?
    private var isRecording = false
    private var frameNumber: Int64 = 0
    private var videoOutputURL: URL?
    private var depthDataURL: URL?
    var frameDataArray: [ARData] = []
    @Published var arframeFrequency = 30
    private var firstTimestamp = 0.0
    private var isFirstFrame = true
    
    private override init() {
        super.init()
        self.frameDataArray.reserveCapacity(10000)
    }
    
    func recordFrame(_ frame: ARFrame) {
        guard isRecording, let pixelBufferAdaptor = pixelBufferAdaptor, let assetWriterInput = assetWriterInput else {
            return
        }

        if self.isFirstFrame {
            self.firstTimestamp = frame.timestamp
            self.isFirstFrame = false
        }

        if assetWriterInput.isReadyForMoreMediaData {
            let depthBuffer = frame.sceneDepth?.depthMap
            let pixelBuffer = frame.capturedImage

            let presentationTime = CMTime(value: frameNumber, timescale: CMTimeScale(arframeFrequency))

            if pixelBufferAdaptor.append(pixelBuffer, withPresentationTime: presentationTime) {
                frameNumber += 1

                if let depthBuffer = depthBuffer {
                    saveDepthBuffer(depthBuffer, at: frame.timestamp - firstTimestamp)
                }

                let frameData = ARData(timestamp: frame.timestamp - firstTimestamp, transform: frame.camera.transform)
                self.frameDataArray.append(frameData)
            } else {
                print("Error appending pixel buffer")
            }
        }
    }
    
    private func saveDepthBuffer(_ depthBuffer: CVPixelBuffer, at timestamp: Double) {
        CVPixelBufferLockBaseAddress(depthBuffer, .readOnly)
        defer { CVPixelBufferUnlockBaseAddress(depthBuffer, .readOnly) }

        let width = CVPixelBufferGetWidth(depthBuffer)
        let height = CVPixelBufferGetHeight(depthBuffer)
        let baseAddress = CVPixelBufferGetBaseAddress(depthBuffer)

        let buffer = UnsafeBufferPointer(start: baseAddress!.assumingMemoryBound(to: Float32.self), count: width * height)
        let data = Data(buffer: buffer)
        
        let fileName = String(format: "depth_%.3f.raw", timestamp)
        let fileURL = depthDataURL?.appendingPathComponent(fileName)
        
        do {
            try data.write(to: fileURL!)
            print("Saved depth buffer to \(fileURL!)")
        } catch {
            print("Error saving depth buffer: \(error)")
        }
    }
    
    func startRecording(completion: @escaping (Bool) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyyMMdd_HHmmss"
            let dateString = dateFormatter.string(from: Date())
            
            let tempDirectory = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
            self.videoOutputURL = tempDirectory.appendingPathComponent(dateString + "RGB").appendingPathExtension("mp4")
            self.depthDataURL = tempDirectory.appendingPathComponent(dateString + "_Depth")
            
            do {
                try FileManager.default.createDirectory(at: self.depthDataURL!, withIntermediateDirectories: true, attributes: nil)
                
                guard let videoOutputURL = self.videoOutputURL else {
                    DispatchQueue.main.async {
                        completion(false)
                    }
                    return
                }
                
                self.assetWriter = try AVAssetWriter(outputURL: videoOutputURL, fileType: .mp4)
                
                let outputSettings: [String: Any] = [
                    AVVideoCodecKey: AVVideoCodecType.h264,
                    AVVideoWidthKey: 1280,
                    AVVideoHeightKey: 720
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
                    self.frameDataArray.removeAll(keepingCapacity: true)
                    
                    self.isRecording = true
                    self.isFirstFrame = true
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
            
            if let depthDataURL = self.depthDataURL, FileManager.default.fileExists(atPath: depthDataURL.path) {
                self.saveFilesToDocumentDirectory(sourceURL: depthDataURL)
            } else {
                print("Depth data folder does not exist")
            }

            self.saveFilesToDocumentDirectory(sourceURL: self.videoOutputURL)
            completion(self.assetWriter?.outputURL)
        }
    }
    
    private func saveFilesToDocumentDirectory(sourceURL: URL?) {
        guard let sourceURL = sourceURL else { return }
        
        let fileManager = FileManager.default
        let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        let destinationURL = documentsDirectory.appendingPathComponent(sourceURL.lastPathComponent)

        do {
            if fileManager.fileExists(atPath: destinationURL.path) {
                try fileManager.removeItem(at: destinationURL)
            }
            try fileManager.moveItem(at: sourceURL, to: destinationURL)
            print("Saved files to \(destinationURL)")
        } catch {
            print("Error saving files: \(error.localizedDescription)")
        }
    }
}

