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
import CoreImage
import SwiftUI
import Accelerate

class ARRecorder: NSObject, ObservableObject {
    static let shared = ARRecorder()
    
    private var assetWriter: AVAssetWriter?
    private var assetWriterInput: AVAssetWriterInput?
    private var pixelBufferAdaptor: AVAssetWriterInputPixelBufferAdaptor?
    private var isRecording = false
    private var frameNumber: Int64 = 0
    var videoOutputURL: URL?
    var depthDataURL: URL?
    var frameDataArray: [ARData] = []
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
            let depthBuffer: CVPixelBuffer?
            if SettingModel.shared.smoothDepth {
                 depthBuffer = frame.smoothedSceneDepth?.depthMap
            } else {
                 depthBuffer = frame.sceneDepth?.depthMap
            }
            let pixelBuffer = frame.capturedImage
            
            let presentationTime = CMTime(value: frameNumber, timescale: CMTimeScale(SettingModel.shared.frameRate))
            
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
        DispatchQueue.global(qos: .userInitiated).async {
            CVPixelBufferLockBaseAddress(depthBuffer, .readOnly)
            defer { CVPixelBufferUnlockBaseAddress(depthBuffer, .readOnly) }
            //
            let width = CVPixelBufferGetWidth(depthBuffer)
            let height = CVPixelBufferGetHeight(depthBuffer)
            guard let baseAddress = CVPixelBufferGetBaseAddress(depthBuffer) else {
                print("Error: Unable to get base address of depth buffer")
                return
            }
            
            let float32Pointer = baseAddress.assumingMemoryBound(to: Float32.self)
            
            let bufferSize = width * height
            
            // 创建一个临时的 Float 缓冲区
            var floatBuffer = [Float](repeating: 0, count: bufferSize)
            
            // 使用 vDSP 进行缩放
            vDSP_vsmul(float32Pointer, 1, [Float(10000)], &floatBuffer, 1, vDSP_Length(bufferSize))
            
            // 创建 UInt16 缓冲区
            var uint16Buffer = [UInt16](repeating: 0, count: bufferSize)
            
            // 使用 vDSP 函数进行裁剪和转换
            var lower: Float = 0
            var upper: Float = 65535
            vDSP_vclip(floatBuffer, 1, &lower, &upper, &floatBuffer, 1, vDSP_Length(bufferSize))
            
            // 直接将 Float 转换为 UInt16
            vDSP_vfixu16(floatBuffer, 1, &uint16Buffer, 1, vDSP_Length(bufferSize))
            
            let data = Data(bytes: &uint16Buffer, count: bufferSize * MemoryLayout<UInt16>.size)
            
//        //  转为UInt16
//            var UInt16Buffer = [UInt16](repeating: 0, count: width * height)
//            
//            for y in 0..<height {
//                for x in 0..<width {
//                    let depthValue = float32Pointer[y * width + x]
//                    let processedValue = UInt16(max(0, min(65535, depthValue * 10000))) // 防止溢出
//                    UInt16Buffer[y * width + x] = processedValue
//                }
//            }
//            
//           
//            let data = UInt16Buffer.withUnsafeBufferPointer { buffer in
//                Data(buffer: buffer)
//            }
            
           
            
            let fileName = String(format: "depth_%.3f.bin", timestamp)
            
//            let fileURL = self.depthDataURL?.appendingPathComponent(fileName)
            // 使用可选绑定来安全地创建文件URL
           guard let fileURL = self.depthDataURL?.appendingPathComponent(fileName) else {
               print("Error: Unable to create file URL for depth buffer")
               return
           }
            
            do {
                try data.write(to: fileURL)
//                print("Saved depth buffer to \(fileURL)")
            } catch {
                print("Error saving depth buffer: \(error)")
            }
            
            // Auxiliary function to make String from depth map array
            //                    func getStringFrom2DimArray(array: [[Float32]], height: Int, width: Int) -> String
            //                    {
            //                        var arrayStr: String = ""
            //                        for y in 0...height - 1
            //                        {
            //                            var lineStr = ""
            //                            for x in 0...width - 1
            //                            {
            //                                lineStr += String(array[y][x])
            //                                if x != width - 1
            //                                {
            //                                    lineStr += ","
            //                                }
            //                            }
            //                            lineStr += "\n"
            //                            arrayStr += lineStr
            //                        }
            //                        return arrayStr
            //                    }
            //
            //                    let depthWidth2 = CVPixelBufferGetWidth(depthBuffer)
            //                    let depthHeight2 = CVPixelBufferGetHeight(depthBuffer)
            //                    CVPixelBufferLockBaseAddress(depthBuffer, CVPixelBufferLockFlags(rawValue: 0))
            //                    let floatBuffer = unsafeBitCast(CVPixelBufferGetBaseAddress(depthBuffer), to: UnsafeMutablePointer<Float32>.self)
            //                    var depthArray = [[Float32]]()
            //                    for y in 0...depthHeight2 - 1
            //                    {
            //                        var distancesLine = [Float32]()
            //                        for x in 0...depthWidth2 - 1
            //                        {
            //                            let distanceAtXYPoint = floatBuffer[y * depthWidth2 + x]
            //                            distancesLine.append(distanceAtXYPoint)
            //                            print("Depth in (\(x), \(y)): \(distanceAtXYPoint)")
            //                        }
            //                        depthArray.append(distancesLine)
            //                    }
            //                    let fileName = String(format: "depth_%.3f.txt", timestamp)
            //            let fileURL = self.depthDataURL?.appendingPathComponent(fileName)
            //                    //                let textDepthUrl = documentsDirectory.appendingPathComponent("depth_text_\(dateString).txt")
            //
            //                    let depthString: String = getStringFrom2DimArray(array: depthArray, height: depthHeight2, width: depthWidth2)
            //                    do {
            //                        try depthString.write(to: fileURL!, atomically: false, encoding: .utf8)
            //                        print("Saved depth buffer to \(fileURL!)")
            //                    } catch {
            //                        print("Error saving depth buffer: \(error)")
            //                    }
            
            //        let bytebuffer = CVPixelBufferGetBaseAddress(depthBuffer)
            //        let width = CVPixelBufferGetWidth(depthBuffer)
            //        let height = CVPixelBufferGetHeight(depthBuffer)
            //        let bytesPerRow = CVPixelBufferGetBytesPerRow(depthBuffer)
            //        let bytesPerPixel = 2
            //        let bytesPerComponent = 2
            
            
            
            //            let width = CVPixelBufferGetWidth(depthBuffer)
            //            let height = CVPixelBufferGetHeight(depthBuffer)
            //
            //
            //            guard let baseAddress = CVPixelBufferGetBaseAddress(depthBuffer) else {
            //                print("Error: Unable to get base address of depth buffer")
            //                return
            //            }
            //
            //
            //            var processedBuffer = [UInt16](repeating: 0, count: width * height)
            //
            //
            ////            let floatBuffer = baseAddress.assumingMemoryBound(to: Float32.self)
            ////            for y in 0..<height {
            ////                for x in 0..<width {
            ////                    let depthValue = floatBuffer[y * width + x]
            ////                    let processedValue = UInt16((depthValue * 1))
            ////                    processedBuffer[y * width + x] = processedValue
            ////                }
            ////            }
            //
            //            var processedPixelBuffer: CVPixelBuffer?
            //            let attributes: [String: Any] = [
            //                kCVPixelBufferCGImageCompatibilityKey as String: true,
            //                kCVPixelBufferCGBitmapContextCompatibilityKey as String: true,
            //                kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_OneComponent16Half
            //            ]
            //
            //            CVPixelBufferCreateWithBytes(nil, width, height, kCVPixelFormatType_OneComponent16Half, &processedBuffer, width * MemoryLayout<UInt16>.size, nil, nil, attributes as CFDictionary, &processedPixelBuffer)
            //
            //            guard let validProcessedPixelBuffer = processedPixelBuffer else {
            //                print("Error: Unable to create processed pixel buffer")
            //                return
            //            }
            //
            //            let ciImage = CIImage(cvPixelBuffer: validProcessedPixelBuffer)
            //            let context = CIContext()
            //            let fileName = String(format: "depth_%.3f.png", timestamp)
            //            let fileURL = self.depthDataURL?.appendingPathComponent(fileName)
            //
            //            do {
            //                //            let cgImage = context.createCGImage(ciImage, from: ciImage.extent)
            //                //            let uiImage = UIImage(cgImage: cgImage!)
            //                try context.writePNGRepresentation(of: ciImage, to: fileURL!, format: CIFormat.L16, colorSpace: CGColorSpaceCreateDeviceGray(), options: [:])
            //                //            let fileURL = depthDataURL?.appendingPathComponent(fileName)
            //                //            try uiImage.pngData()?.write(to: fileURL!)
            //                //            print("Saved depth buffer to \(fileURL!)")
            //            } catch {
            //                print("Error saving depth buffer: \(error)")
            //            }
            
        }
    }
    
    func startRecording(parentFolderURL: URL, completion: @escaping (Bool) ->
                        
                        Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            // 这里日期先没用到
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyyMMdd_HHmmss"
            let dateString = dateFormatter.string(from: Date())
            
            // 使用传入的父文件夹路径
            self.videoOutputURL = parentFolderURL.appendingPathComponent("RGB").appendingPathExtension("mp4")
            self.depthDataURL = parentFolderURL.appendingPathComponent("Depth")
            
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
                    AVVideoWidthKey: 640,
                    AVVideoHeightKey: 480
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
            // 清理资源
            self.assetWriter = nil
            self.assetWriterInput = nil
            self.pixelBufferAdaptor = nil

            
//            if let depthDataURL = self.depthDataURL, FileManager.default.fileExists(atPath: depthDataURL.path) {
//                self.saveFilesToDocumentDirectory(sourceURL: depthDataURL)
//            } else {
//                print("Depth data folder does not exist")
//            }
//
//            self.saveFilesToDocumentDirectory(sourceURL: self.videoOutputURL)
            completion(self.videoOutputURL)
        }
    }
    
}

