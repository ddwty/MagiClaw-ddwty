////
////  CameraPreviewView.swift
////  talkWithRpi
////
////  Created by Tianyu on 7/22/24.
////
//
//import SwiftUI
//import AVFoundation
//
//struct CameraPreviewView: UIViewRepresentable {
//    class VideoPreviewView: UIView {
//        override class var layerClass: AnyClass {
//            AVCaptureVideoPreviewLayer.self
//        }
//
//        var videoPreviewLayer: AVCaptureVideoPreviewLayer {
//            return layer as! AVCaptureVideoPreviewLayer
//        }
//    }
//
//    var session: AVCaptureSession
//
//    func makeUIView(context: Context) -> VideoPreviewView {
//        let view = VideoPreviewView()
//        view.videoPreviewLayer.session = session
//        view.videoPreviewLayer.videoGravity = .resizeAspectFill
//        return view
//    }
//
//    func updateUIView(_ uiView: VideoPreviewView, context: Context) {
//        // 更新方向
//        DispatchQueue.main.async {
//            if let connection = uiView.videoPreviewLayer.connection {
//                if connection.isVideoOrientationSupported {
//                    connection.videoOrientation = .landscapeRight // 设置为横屏模式
//                }
//            }
//        }
//    }
//}
//
