////
////  CameraViewController.swift
////  talkWithRpi
////
////  Created by Tianyu on 7/21/24.
////
//import SwiftUI
//import AVFoundation
//import Photos
//
//
//class CameraManager: NSObject, ObservableObject {
//    static let shared = CameraManager()
//    var captureSession: AVCaptureSession?
//    private var movieOutput: AVCaptureMovieFileOutput?
//    private var videoOutputURL: URL?
//    private var recordingStartTime: Date?
//    
//    @Published var isRecording = false
//    @Published var recordingDuration: TimeInterval = 0
//    
//    private var timer: Timer?
//    
//    private override init() {
//        super.init()
//        prepareSession()
//    }
//    
//    func prepareSession() {
//        captureSession = AVCaptureSession()
//        guard let captureSession = captureSession else { return }
//        
//        guard let videoDevice = AVCaptureDevice.default(for: .video),
//              let videoInput = try? AVCaptureDeviceInput(device: videoDevice) else {
//            print("Error: Cannot access the back camera")
//            return
//        }
//        
//        configureCamera(for: videoDevice) // 配置相机
//        
//        movieOutput = AVCaptureMovieFileOutput()
//        
//        if captureSession.canAddInput(videoInput) {
//            captureSession.addInput(videoInput)
//        }
//        
//        if let movieOutput = movieOutput, captureSession.canAddOutput(movieOutput) {
//            captureSession.addOutput(movieOutput)
//        }
//        
//        DispatchQueue.global(qos: .userInitiated).async {
//            captureSession.startRunning()
//        }
//    }
//    
//    
//    func setFrameRate(_ frameRate: Int) {
//        guard let captureSession = captureSession else { return }
//        guard let videoDevice = AVCaptureDevice.default(for: .video) else { return }
//        
//        do {
//            try videoDevice.lockForConfiguration()
//            videoDevice.activeVideoMinFrameDuration = CMTimeMake(value: 1, timescale: Int32(frameRate))
//            videoDevice.activeVideoMaxFrameDuration = CMTimeMake(value: 1, timescale: Int32(frameRate))
//            videoDevice.unlockForConfiguration()
//        } catch {
//            print("Error setting frame rate: \(error)")
//        }
//    }
//    
//    func setResolution(_ resolution: AVCaptureSession.Preset) {
//        guard let captureSession = captureSession else { return }
//        
//        if captureSession.canSetSessionPreset(resolution) {
//            captureSession.beginConfiguration()
//            captureSession.sessionPreset = resolution
//            captureSession.commitConfiguration()
//        }
//    }
//    func startRecording() {
//        guard !isRecording else { return }
//        
//        
//        if captureSession == nil || !(captureSession?.isRunning ?? false) {
//            prepareSession()
//        }
//        
//        let dateFormatter = DateFormatter()
//        dateFormatter.dateFormat = "yyyyMMdd_HHmmss"
//        let dateString = dateFormatter.string(from: Date())
//        
//        let tempDirectory = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
//        videoOutputURL = tempDirectory.appendingPathComponent(dateString).appendingPathExtension("mp4")
//        
//        if let videoOutputURL = videoOutputURL {
//            movieOutput?.startRecording(to: videoOutputURL, recordingDelegate: self)
//        }
//        
//        recordingStartTime = Date()
//        isRecording = true
//        startTimer()
//    }
//    
//    func stopRecording() {
//        guard isRecording else { return }
//        
//        movieOutput?.stopRecording()
//        //        captureSession?.stopRunning()
//        
//        isRecording = false
//        stopTimer()
//    }
//    
//    private func startTimer() {
//        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
//            guard let self = self, let startTime = self.recordingStartTime else { return }
//            self.recordingDuration = Date().timeIntervalSince(startTime)
//        }
//    }
//    
//    private func stopTimer() {
//        timer?.invalidate()
//        timer = nil
//    }
//    
//    private func configureCamera(for device: AVCaptureDevice) {
//        do {
//            try device.lockForConfiguration()
//            
//            // Ensure exposure and white balance modes are set to auto
//            if device.isExposureModeSupported(.continuousAutoExposure) {
//                device.exposureMode = .continuousAutoExposure
//            }
//            
//            if device.isWhiteBalanceModeSupported(.continuousAutoWhiteBalance) {
//                device.whiteBalanceMode = .continuousAutoWhiteBalance
//            }
//            
//            device.unlockForConfiguration()
//        } catch {
//            print("Error configuring camera: \(error)")
//        }
//    }
//    
//    private func saveVideoToPhotoLibrary(videoURL: URL) {
//        PHPhotoLibrary.requestAuthorization { status in
//            guard status == .authorized else { return }
//            
//            PHPhotoLibrary.shared().performChanges({
//                PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: videoURL)
//            }) { success, error in
//                if let error = error {
//                    print("Error saving video: \(error.localizedDescription)")
//                } else {
//                    print("Video saved successfully")
//                }
//            }
//        }
//    }
//}
//
//extension CameraManager: AVCaptureFileOutputRecordingDelegate {
//    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
//        if let error = error {
//            print("Error recording movie: \(error.localizedDescription)")
//        } else {
//            if let videoOutputURL = videoOutputURL {
//                saveVideoToPhotoLibrary(videoURL: videoOutputURL)
//            }
//        }
//    }
//}
