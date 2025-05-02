//
//  CameraModule.swift
//  MagiClaw
//
//  Created by Tianyu on 4/20/25.
//

import SwiftUI
#if os(macOS)
/// 完整的相机模块，包含控制和预览
struct USBCameraView: View {
    @StateObject private var cameraManager = CameraManager()
    @Binding var isVisible: Bool
    
    var body: some View {
        VStack(spacing: 15) {
            HStack {
                Text("Camera & ArUco Detection")
                    .font(.title2)
                    .fontWeight(.bold)
                    .padding(.top, 5)
                
                Spacer()
                
                Button(isVisible ? "Hide Camera" : "Show Camera") {
                    isVisible.toggle()
                    if !isVisible {
                        cameraManager.stopCapture()
                    }
                }
                .padding(.horizontal)
                .buttonStyle(.borderedProminent)
            }
            .padding(.horizontal)
            
            if isVisible {
                CameraControlView(cameraManager: cameraManager)
                    .frame(minHeight: 400)
            }
        }
        .onDisappear {
            cameraManager.stopCapture()
        }
    }
}
#endif
