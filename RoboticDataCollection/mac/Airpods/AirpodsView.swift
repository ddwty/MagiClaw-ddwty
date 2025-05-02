//
//  SceneView.swift
//  MagiClaw
//
//  Created by Tianyu on 4/16/25.
//

import SwiftUI
import SceneKit
import CoreMotion
import SwiftUI

#if os(macOS)

public typealias UIViewRepresentable = NSViewRepresentable
public typealias UIViewControllerRepresentable = NSViewControllerRepresentable


struct AirpodsView: View {
    @StateObject private var motionManager = HeadphoneMotionManager()
    @State private var showConnectionAlert = false
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                gradient: Gradient(colors: [Color(hex: "1a2a6c"), Color(hex: "b21f1f"), Color(hex: "fdbb2d")]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .opacity(0.2)
            .ignoresSafeArea()
            
            VStack(spacing: 20) {
                headerView
                
                HStack(spacing: 30) {
                    // 3D Cube View
                    SceneCubeView(motionData: motionManager.motionData, calibrationQuaternion: motionManager.calibrationQuaternion)
                        .frame(width: 400, height: 400)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(Color(hex: "2A2D34").opacity(0.7))
                                .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 5)
                        )
                    
                    // Motion Data Display
                    if let data = motionManager.motionData {
                        motionDataView(data: data)
                    } else {
                        noDataView
                    }
                }
                .padding(.horizontal)
                
                connectionStatusView
            }
            .padding()
        }
        .alert(isPresented: $showConnectionAlert) {
            Alert(
                title: Text("Connection Error"),
                message: Text(motionManager.errorMessage ?? "Unknown error"),
                dismissButton: .default(Text("OK"))
            )
        }
        .onChange(of: motionManager.errorMessage) { _, newValue in
            showConnectionAlert = newValue != nil
        }
    }
    
    private var headerView: some View {
        HStack {
            Text("AirPods Motion Tracking")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundColor(Color(hex: "2A2D34"))
            
            Spacer()
            
            Button(action: {
                motionManager.calibrate()
            }) {
                HStack {
                    Image(systemName: "arrow.counterclockwise")
                    Text("Calibrate")
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(Color.blue.opacity(0.8))
                )
                .foregroundColor(.white)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.9))
                .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
        )
    }
    
    private func motionDataView(data: CMDeviceMotion) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Group {
                    dataSection(title: "Quaternion", content: [
                        "x: \(String(format: "%.4f", data.attitude.quaternion.x))",
                        "y: \(String(format: "%.4f", data.attitude.quaternion.y))",
                        "z: \(String(format: "%.4f", data.attitude.quaternion.z))",
                        "w: \(String(format: "%.4f", data.attitude.quaternion.w))"
                    ])
                    
                    dataSection(title: "Attitude", content: [
                        "pitch: \(String(format: "%.4f", data.attitude.pitch))",
                        "roll: \(String(format: "%.4f", data.attitude.roll))",
                        "yaw: \(String(format: "%.4f", data.attitude.yaw))"
                    ])
                    
                    dataSection(title: "Gravitational Acceleration", content: [
                        "x: \(String(format: "%.4f", data.gravity.x))",
                        "y: \(String(format: "%.4f", data.gravity.y))",
                        "z: \(String(format: "%.4f", data.gravity.z))"
                    ])
                    
                    dataSection(title: "Rotation Rate", content: [
                        "x: \(String(format: "%.4f", data.rotationRate.x))",
                        "y: \(String(format: "%.4f", data.rotationRate.y))",
                        "z: \(String(format: "%.4f", data.rotationRate.z))"
                    ])
                    
                    dataSection(title: "Acceleration", content: [
                        "x: \(String(format: "%.4f", data.userAcceleration.x))",
                        "y: \(String(format: "%.4f", data.userAcceleration.y))",
                        "z: \(String(format: "%.4f", data.userAcceleration.z))"
                    ])
                    
                    dataSection(title: "Magnetic Field", content: [
                        "field: \(String(format: "%.4f", data.magneticField.field.x)), \(String(format: "%.4f", data.magneticField.field.y)), \(String(format: "%.4f", data.magneticField.field.z))",
                        "accuracy: \(data.magneticField.accuracy.rawValue)"
                    ])
                    
                    dataSection(title: "Heading", content: [
                        "\(String(format: "%.2f", data.heading))°"
                    ])
                }
            }
            .padding()
        }
        .frame(width: 400, height: 400)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white.opacity(0.9))
                .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 5)
        )
    }
    
    private func dataSection(title: String, content: [String]) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.headline)
                .foregroundColor(Color(hex: "2A2D34"))
            
            ForEach(content, id: \.self) { line in
                Text(line)
                    .font(.system(.body, design: .monospaced))
                    .foregroundColor(Color(hex: "2A2D34").opacity(0.8))
            }
        }
        .padding(.vertical, 4)
    }
    
    private var noDataView: some View {
        VStack {
            Image(systemName: "headphones.slash")
                .font(.system(size: 50))
                .foregroundColor(.gray)
            
            Text("No AirPods Connected")
                .font(.headline)
                .foregroundColor(.gray)
                .padding(.top)
            
            Text("Connect your AirPods Pro to see motion data")
                .font(.subheadline)
                .foregroundColor(.gray.opacity(0.8))
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .frame(width: 400, height: 400)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white.opacity(0.9))
                .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 5)
        )
    }
    
    private var connectionStatusView: some View {
        HStack {
            Circle()
                .fill(motionManager.isConnected ? Color.green : Color.red)
                .frame(width: 10, height: 10)
            
            Text(motionManager.isConnected ? "AirPods Pro Connected" : "AirPods Pro Disconnected")
                .font(.caption)
                .foregroundColor(Color(hex: "2A2D34"))
            
            Spacer()
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.white.opacity(0.7))
        )
    }
}


#Preview {
    AirpodsView()
}
#endif
