//
//  CameraControlView.swift
//  MagiClaw
//
//  Created by Tianyu on 4/20/25.
//

import SwiftUI
#if os(macOS)
/// 相机控制视图组件
struct CameraControlView: View {
    @ObservedObject var cameraManager: CameraManager
    
    var body: some View {
        VStack(spacing: 15) {
            HStack {
                Text("USB Camera")
                    .font(.headline)
                
                Spacer()
                
                Button("Refresh") {
                    cameraManager.refreshCameraList()
                }
                .buttonStyle(.bordered)
                
                Menu {
                    ForEach(cameraManager.availableCameras, id: \.uniqueID) { camera in
                        Button(camera.localizedName) {
                            cameraManager.startCapture(with: camera)
                        }
                    }
                    
                    if cameraManager.availableCameras.isEmpty {
                        Text("No cameras found")
                    }
                } label: {
                    HStack {
                        Text(cameraManager.selectedCamera?.localizedName ?? "Select Camera")
                        Image(systemName: "chevron.down")
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(5)
                }
            }
            .padding(.horizontal)
            
            // 相机预览和ArUco检测结果
            CameraImageView(cameraManager: cameraManager)
        }
    }
}

#Preview {
    CameraControlView(cameraManager: CameraManager())
        .frame(width: 800)
} 
#endif
