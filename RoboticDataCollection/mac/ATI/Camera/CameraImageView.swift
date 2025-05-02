//
//  CameraImageView.swift
//  MagiClaw
//
//  Created by Tianyu on 4/20/25.
//

import SwiftUI
#if os(macOS)
struct CameraImageView: View {
    @ObservedObject var cameraManager: CameraManager
    var height: CGFloat = 300
    var backgroundColor: Color = Color.gray.opacity(0.2)
    var textColor: Color = .gray
    
    var body: some View {
        HStack(alignment: .top, spacing: 20) {
            // 相机预览
            Group {
                if let previewImage = cameraManager.previewImage {
                    Image(nsImage: previewImage)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(height: height)
                } else {
                    Rectangle()
                        .fill(backgroundColor)
                        .frame( height: height)
                        .overlay(
                            Text(cameraManager.isCapturing ? "Initializing camera..." : "No camera selected")
                                .foregroundColor(textColor)
                        )
                        .cornerRadius(10)
                }
            }
            .frame(width: height * 4/3)
            
            // ArUco 检测结果
            ArUcoDetectionView(transforms: cameraManager.detectedMarkers)
                .frame(height: height)
        }
        .padding(.horizontal)
    }
}

#Preview {
    CameraImageView(cameraManager: CameraManager())
        .frame(width: 800)
} 
#endif
