//
//  RemoteControlCard.swift
//  MagiClaw
//
//  Created by Tianyu on 9/15/24.
//

import SwiftUI

struct RemoteControlCard: View {
    @ObservedObject var audioWebsocketServer: WebSocketServerManager
    @ObservedObject var remoteControlManager = RemoteControlManager.shared
    @State private var serverConnectionStatus = ServerConnectionStatus.shared
    
    
    @State private var audioStreamManager: AudioStreamManager?
    @State private var isStreamingAudio = false
//    @State private var isLocked = false
    @State private var showFullPanel = true
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                VStack(alignment: .leading) {
                    Text("Real-time Data Transmission")
                        .font(.title3)
                        .fontWeight(.bold)
                    HStack {
                        Text("IP address: ")
                            .foregroundStyle(Color.secondary)
                        IPView()
                    }
                }
                Spacer()
                Image(systemName: showFullPanel ? "arrow.up.right.and.arrow.down.left.square" : "arrow.down.backward.and.arrow.up.forward.square")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 30, height: 30)
                    .foregroundStyle(Color.primary.opacity(0.3))
                    .onTapGesture {
                        withAnimation(.easeInOut) {
                            self.showFullPanel.toggle()
                        }
                    }
            }
            Divider()
            
            if showFullPanel {
                VStack {
                    Toggle(isOn: $remoteControlManager.enableSendingData) {
                        VStack(alignment: .leading) {
                            Text(remoteControlManager.enableSendingData ? "Sending...(Pose & RGB)" : "Send data (Pose & RGB)")
                            
                            HStack {
                                Image(systemName: "circle.fill")
                                    .foregroundColor(serverConnectionStatus.isSendingDataServerReady ? .green : .red)
                                    .imageScale(.small)
                                    .font(.caption)
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
                    //                .background(Color(UIColor.systemBackground))
                    .background(
                        RoundedRectangle(cornerSize: CGSize(width: 15, height: 15), style: .continuous)
                            .stroke(remoteControlManager.enableSendingData ? Color.green : Color.white, lineWidth: 1)
                    )
                    .tint(Color.green)
                    .onChange(of: remoteControlManager.enableSendingData) {
                        toggleLock()
                    }
                    
                    Toggle(isOn: $isStreamingAudio) {
                        VStack(alignment: .leading) {
                            Text(isStreamingAudio ? "Streaming..." : "Stream audio")
                            HStack {
                                Image(systemName: "circle.fill")
                                    .foregroundColor(serverConnectionStatus.isStreamingAudioServerReady ? .green : .red)
                                    .imageScale(.small)
                                    .font(.caption)
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
                    //                .padding()
                    //                .background(Color(UIColor.systemBackground))
                    //                .clipShape(RoundedRectangle(cornerRadius: 15, style: .continuous))
                    .padding()
                    .background(
                        RoundedRectangle(cornerSize: CGSize(width: 15, height: 15), style: .continuous)
                            .stroke(isStreamingAudio ? Color.green : Color.white, lineWidth: 1)
                    )
                    .tint(Color.green)
                    .onChange(of: isStreamingAudio) {
                        toggleLock()
                        if isStreamingAudio {
                            audioStreamManager = AudioStreamManager(websocketServerManager: audioWebsocketServer)
                            audioStreamManager?.startStreaming()
                        } else {
                            audioStreamManager?.stopStreaming()
                        }
                    }
                }
            }
        }
        .padding()
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 15, style: .continuous))
        .shadow(color: Color.black.opacity(0.15), radius: 10, x: 0, y: 0)
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
    RemoteControlCard(audioWebsocketServer: WebSocketServerManager(port: 8081))
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