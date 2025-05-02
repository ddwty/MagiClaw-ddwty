//
//  RemoteControlCard.swift
//  MagiClaw
//
//  Created by Tianyu on 9/15/24.
//
#if os(iOS)
import SwiftUI

struct RemoteControlCard: View {
    @ObservedObject var audioWebsocketServer: WebSocketServerManager
    @Bindable var remoteControlManager: RemoteControlManager
    @State private var serverConnectionStatus = ServerConnectionStatus.shared
    
    
    @State private var audioStreamManager: AudioStreamManager?
    @State private var isStreamingAudio = false
    
    //    @State private var isLocked = false
    @Binding var showFullPanel: Bool
    var body: some View {
        VStack(alignment: .leading) {
            // Top bar with toggle button aligned to the right
           
            // Details panel that appears when showFullPanel is true
//            if showFullPanel {
                VStack(alignment: .leading, spacing: 16) {
                    // Real-time Data Transmission Section
                    HStack {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Real-time Data Transmission")
                                .font(.title3)
                                .fontWeight(.bold)
                            HStack {
                                Text("IP address: 192.168.3.1")
                                    .foregroundStyle(Color.secondary)
//                                IPView()
                            }
                        }
                        Spacer()
                        Image(systemName: showFullPanel ? "arrow.up.right.and.arrow.down.left.square" : "arrow.down.backward.and.arrow.up.forward.square")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 30, height: 30)
                            .foregroundStyle(Color.primary.opacity(0.3))
                            .onTapGesture {
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    self.showFullPanel = false
                                }
                            }
                        
                    }
                    
                    Divider()
                    Toggle(isOn: $remoteControlManager.enableDetectAruco) {
                        Text("Detect ArUco Marker")
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 15)
                            .stroke(remoteControlManager.enableSendingData ? Color.green : Color.gray, lineWidth: 1)
                    )
                    .tint(Color.green)
                    Divider()
                    
                    // Toggle for Sending Data
                    Toggle(isOn: $remoteControlManager.enableSendingData) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(remoteControlManager.enableSendingData ? "Sending... (Pose, Depth, Opening range, RGB)" : "Send data (Pose, Depth, Opening range, RGB)")
                            
                            HStack {
                                Image(systemName: "circle.fill")
                                    .foregroundColor( .green )
                                    .imageScale(.small)
                                Text("Port: 8080")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            if serverConnectionStatus.sendDataClientID.count > 0 {
                                Text("Connected clients: \(serverConnectionStatus.sendDataClientID.count)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            } else {
                                Text("No client connected")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 15)
                            .stroke(remoteControlManager.enableSendingData ? Color.green : Color.gray, lineWidth: 1)
                    )
                    .tint(Color.green)
                    .onChange(of: remoteControlManager.enableSendingData) { _ in
                        toggleLock()
                    }
                    
                    // Toggle for Streaming Audio
                    Toggle(isOn: $isStreamingAudio) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(isStreamingAudio ? "Streaming..." : "Stream audio")
                            HStack {
                                Image(systemName: "circle.fill")
                                    .foregroundColor( .green)
                                    .imageScale(.small)
                                Text("Port: 8081")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            if serverConnectionStatus.audioStreamClientID.count > 0 {
                                Text("Connected clients: \(serverConnectionStatus.audioStreamClientID.count)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            } else {
                                Text("No client connected")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 15)
                            .stroke(isStreamingAudio ? Color.green : Color.gray, lineWidth: 1)
                    )
                    .tint(Color.green)
                    .onChange(of: isStreamingAudio) { value in
                        toggleLock()
                        if value {
                            audioStreamManager = AudioStreamManager(websocketServerManager: audioWebsocketServer)
                            audioStreamManager?.startStreaming()
                        } else {
                            audioStreamManager?.stopStreaming()
                        }
                    }
                }
                //                        .padding()
                //                        .background(Color(UIColor.systemBackground).opacity(0.8))
                //                        .clipShape(RoundedRectangle(cornerRadius: 15))
                //                        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                //                        .transition(.asymmetric(
                //                            insertion: .move(edge: .bottom).combined(with: .opacity),
                //                            removal: .move(edge: .bottom).combined(with: .opacity)
                //                        ))
//            }
        }
        .padding()
        .background(.regularMaterial)
//        .frame(maxWidth: showFullPanel ? 400 : 0)
        
        .clipShape(RoundedRectangle(cornerRadius: 15, style: .continuous))
        .shadow(color: Color.black.opacity(0.15), radius: 5, x: 0, y: 2)
        .onAppear {
            // 当视图出现时，重置为默认方向
            AppDelegate.orientationLock = .all
        }
        .onDisappear {
            AppDelegate.orientationLock = .all
            remoteControlManager.enableSendingData = false
            isStreamingAudio = false
        }
    }
}

#Preview {
    RemoteControlCard(audioWebsocketServer: WebSocketServerManager(port: 8081), remoteControlManager: RemoteControlManager.shared, showFullPanel: .constant(false))
}


extension RemoteControlCard {
    private func toggleLock() {
        //        self.isLocked = remoteControlManager.enableSendingData || isStreamingAudio
        let isLocked = remoteControlManager.enableSendingData || isStreamingAudio
        let currentOrientation = UIDevice.current.orientation
        
        if !isLocked {
            // 解除锁定
            AppDelegate.orientationLock = .all
        } else {
            // 锁定当前方向
            switch currentOrientation {
            case .portrait, .portraitUpsideDown:
                AppDelegate.orientationLock = .portrait
            case .landscapeLeft, .landscapeRight:
                AppDelegate.orientationLock = .landscape
            default:
                AppDelegate.orientationLock = .all
            }
        }
        
        // 触发屏幕旋转
        //        UIViewController.attemptRotationToDeviceOrientation()
        // 更新支持的界面方向
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            windowScene.keyWindow?.rootViewController?.setNeedsUpdateOfSupportedInterfaceOrientations()
        }
    }
}
#endif
