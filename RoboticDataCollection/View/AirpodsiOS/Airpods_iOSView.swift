//
//  Airpods_iOSView.swift
//  MagiClaw
//
//  Created by Tianyu on 5/4/25.
//

import Foundation

import SwiftUI
import SceneKit
import CoreMotion
import SwiftUI

#if os(iOS)


struct AirpodsView: View {
    @StateObject private var motionManager = HeadphoneMotionManager()
    @EnvironmentObject var websocketServer: WebSocketServerManager
    @State private var serverConnectionStatus = ServerConnectionStatus.shared
    @Environment(\.dismiss) var dismiss
    
    @State private var showConnectionAlert = false
    @State private var streaming = false
    @State private var attitudeServer: WebSocketServerManager?
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                exitButton()
                    .padding(.trailing, 30)
                headerView
                    .padding(.horizontal)
                // 3D Cube View
                SceneCubeView(motionData: motionManager.motionData, calibrationQuaternion: motionManager.calibrationQuaternion)
                    .frame(maxWidth: .infinity)
                    .frame(height: 200)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color.gray)
                            .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 5)
                    )
                
                VStack {
                    
                    HStack {
                        Text("IP address: ")
                            .foregroundStyle(Color.secondary)
                        IPView()
                        Text("Port: 8082")
                            .foregroundStyle(Color.secondary)
                    }
                    
                    Toggle(isOn: $streaming) {
                        HStack {
                            Image(systemName: streaming ? "antenna.radiowaves.left.and.right" : "antenna.radiowaves.left.and.right.slash")
                                .foregroundColor(streaming ? .green : .red)
                            Text(streaming ? "Streaming" : "Start streaming")
                            
                        }
                    }
                    .padding()
                    
                    .onChange(of: streaming) { _, newValue in
                        if newValue {
                            
                            startAttitudeServer()
                        } else {
                            stopAttitudeServer()
                        }
                    }
                    
                    if serverConnectionStatus.sendAirpodsClientID.count > 0 {
                        Text("Connected clients: \(serverConnectionStatus.sendAirpodsClientID.count)")
                            .foregroundColor(.secondary)
                    } else {
                        Text("No client connected")
                        
                            .foregroundColor(.secondary)
                    }
                    // Motion Data Display
                    if let data = motionManager.motionData {
                        motionDataView(data: data)
                    } else {
                        noDataView
                    }
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.white.opacity(0.9))
                        .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
                )
                
            }
            .padding()
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
            .onAppear {
                // 视图出现时，如果streaming为true，启动服务器
                if streaming {
                    startAttitudeServer()
                }
            }
            .onDisappear {
                // 视图消失时，关闭服务器
                stopAttitudeServer()
            }
        }
    }
    
    func exitButton() -> some View {
            HStack {
                Spacer()
                Button(action: {
                    dismiss()
                }) {
                    Text("")
                }
                .shadow(color: Color.black.opacity(0.15), radius: 10)
                .buttonStyle(ExitButtonStyle())
                
            }
    }
    private func startAttitudeServer() {
        // 创建新的WebSocket服务器，使用8082端口
        attitudeServer = WebSocketServerManager(port: 8082)
        
        // 开始监听AirPods数据更新并发送
        startListeningForAttitudeUpdates()
    }
    
    private func stopAttitudeServer() {
        // 停止服务器
        attitudeServer?.stop()
        attitudeServer = nil
    }
    
    private func startListeningForAttitudeUpdates() {
        // 移除 weak self，直接使用 self
        motionManager.onMotionDataUpdate = { data in
            // 检查状态
            guard self.streaming, self.attitudeServer != nil else { return }
            
            // 获取pitch, roll, yaw值
            let pitch = Float(data.attitude.pitch)
            let roll = Float(data.attitude.roll)
            let yaw = Float(data.attitude.yaw)
            
            // 创建二进制数据
            var attitudeData = Data()
            
            // 添加pitch数据
            var pitchValue = pitch
            let pitchData = Data(bytes: &pitchValue, count: MemoryLayout<Float>.size)
            attitudeData.append(pitchData)
            
            // 添加roll数据
            var rollValue = roll
            let rollData = Data(bytes: &rollValue, count: MemoryLayout<Float>.size)
            attitudeData.append(rollData)
            
            // 添加yaw数据
            var yawValue = yaw
            let yawData = Data(bytes: &yawValue, count: MemoryLayout<Float>.size)
            attitudeData.append(yawData)
            
            // 发送数据到所有连接的客户端
            self.attitudeServer?.connectionsByID.values.forEach { connection in
                connection.send(data: attitudeData)
            }
        }
    }
    
    private var headerView: some View {
        HStack {
            Text("AirPods Motion")
                .font(.title3)
            
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
                    .foregroundColor(Color.gray)
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
}

#Preview {
    AirpodsView()
}
#endif
