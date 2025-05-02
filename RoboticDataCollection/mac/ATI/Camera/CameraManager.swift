//
//  CameraManager.swift
//  MagiClaw
//
//  Created by Tianyu on 4/21/25.
//
#if os(macOS)
import Foundation
import AVFoundation
import AppKit
import CoreImage


class CameraManager: NSObject, ObservableObject {
    @Published var availableCameras: [AVCaptureDevice] = []
    @Published var selectedCamera: AVCaptureDevice?
    @Published var previewImage: NSImage?
    @Published var isCapturing = false
    @Published var detectedMarkers: [SKWorldTransform] = []
    
    private var captureSession: AVCaptureSession?
    private var videoOutput: AVCaptureVideoDataOutput?
    private let sessionQueue = DispatchQueue(label: "com.magiclaw.sessionQueue")
    private let processingQueue = DispatchQueue(label: "com.magiclaw.processingQueue", qos: .userInitiated)
    
    // 相机内参矩阵 - 调整为更合理的默认值
    private let cameraIntrinsics: matrix_float3x3 = {
        // 默认内参，实际使用时应该替换为实际相机的标定参数
        var intrinsics = matrix_float3x3()
        // 假设相机分辨率为 640x480
        let fx: Float = 600.0 // 焦距 x
        let fy: Float = 600.0 // 焦距 y
        let cx: Float = 320.0 // 主点 x
        let cy: Float = 240.0 // 主点 y
        
        intrinsics.columns.0 = simd_float3(fx, 0, 0)
        intrinsics.columns.1 = simd_float3(0, fy, 0)
        intrinsics.columns.2 = simd_float3(cx, cy, 1)
        return intrinsics
    }()
    
    override init() {
        super.init()
        refreshCameraList()
    }
    
    func refreshCameraList() {
        availableCameras = AVCaptureDevice.devices(for: .video)
    }
    
    func startCapture(with device: AVCaptureDevice) {
        stopCapture()
        
        selectedCamera = device
        isCapturing = true
        
        sessionQueue.async {
            self.setupCaptureSession(with: device)
        }
    }
    
    func stopCapture() {
        guard let captureSession = captureSession, captureSession.isRunning else { return }
        
        sessionQueue.async {
            captureSession.stopRunning()
            DispatchQueue.main.async {
                self.isCapturing = false
                self.previewImage = nil
                self.detectedMarkers = []
            }
        }
    }
    
    private func setupCaptureSession(with device: AVCaptureDevice) {
        let session = AVCaptureSession()
        session.sessionPreset = .medium
        
        do {
            let input = try AVCaptureDeviceInput(device: device)
            if session.canAddInput(input) {
                session.addInput(input)
            }
            
            let videoOutput = AVCaptureVideoDataOutput()
            videoOutput.setSampleBufferDelegate(self, queue: processingQueue)
            videoOutput.alwaysDiscardsLateVideoFrames = true
            
            if session.canAddOutput(videoOutput) {
                session.addOutput(videoOutput)
            }
            
            self.captureSession = session
            self.videoOutput = videoOutput
            
            session.startRunning()
            
            DispatchQueue.main.async {
                self.isCapturing = true
            }
        } catch {
            print("Error setting up capture session: \(error.localizedDescription)")
            DispatchQueue.main.async {
                self.isCapturing = false
            }
        }
    }
    
    // 处理图像并检测ArUco标记
    private func processImage(_ image: CIImage) -> NSImage? {
        let context = CIContext()
        guard let cgImage = context.createCGImage(image, from: image.extent) else { return nil }
        
        let nsImage = NSImage(cgImage: cgImage, size: NSSize(width: cgImage.width, height: cgImage.height))
        return nsImage
    }
    
    // 检测ArUco标记
    private func detectArUcoMarkers(in pixelBuffer: CVPixelBuffer) {
        // 打印像素缓冲区信息
        let width = CVPixelBufferGetWidth(pixelBuffer)
        let height = CVPixelBufferGetHeight(pixelBuffer)
        print("22222, width: \(width), height: \(height)")
        
        // 使用ArucoCV类检测标记
        let markerSize = Float64(0.024) // 标记尺寸（米）
        let transforms = ArucoCV.estimatePose(pixelBuffer, withIntrinsics: cameraIntrinsics, andMarkerSize: markerSize)
        
        // 打印检测结果
        if let markers = transforms as? [SKWorldTransform] {
            if markers.isEmpty {
//                print("未检测到 ArUco 标记")
            } else {
                print("检测到 \(markers.count) 个 ArUco 标记")
                for marker in markers {
                    print("标记 ID: \(marker.arucoId), 位置: (\(marker.transform.columns.3.x), \(marker.transform.columns.3.y), \(marker.transform.columns.3.z))")
                }
            }
        }
        
        DispatchQueue.main.async {
            self.detectedMarkers = transforms as? [SKWorldTransform] ?? []
        }
    }
}

extension CameraManager: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        
        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
        
        // 处理图像并更新UI
        DispatchQueue.main.async {
            self.previewImage = self.processImage(ciImage)
        }
        
        // 检测ArUco标记
        detectArUcoMarkers(in: pixelBuffer)
    }
}
#endif 
