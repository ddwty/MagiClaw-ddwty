////
////  CameraView.swift
////  talkWithRpi
////
////  Created by Tianyu on 7/21/24.
////
//
//import SwiftUI
//import AVFoundation
//import Photos
//
//struct CameraView: View {
////    @StateObject private var cameraManager = CameraManager.shared
//    let scale = 0.15
//    let width, height: Double
//    @EnvironmentObject var cameraManager: CameraManager
//        var body: some View {
//            VStack {
//                if let session = cameraManager.captureSession {
//                    CameraPreviewView(session: session)
//                        .frame(width: UIScreen.main.bounds.width * 0.1 * 4 / 3, height: UIScreen.main.bounds.width * 0.1)
////                        .frame(width: width * 4 / 3 * scale, height: height * scale)
//                                    .cornerRadius(8)
////                                    .padding()
//                }
//            }
////            .border(.green)
//            .onAppear {
//                PHPhotoLibrary.requestAuthorization { status in
//                    if status != .authorized {
//                        print("Permission to access photo library not granted.")
//                    }
//                }
//               
//            }
//        }
//}
//
//
//
//
//#Preview(traits: .landscapeRight) {
//    CameraView(width: 200, height: 100)
//        .environmentObject(RecordAllDataModel())
//        .environmentObject(MotionManager.shared)
//        .environmentObject(CameraManager.shared)
//}
