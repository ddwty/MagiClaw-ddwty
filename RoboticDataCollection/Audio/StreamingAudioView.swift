//
//  StreamingAudioView.swift
//  MagiClaw
//
//  Created by 吴天禹 on 2024/9/11.
//

import SwiftUI

struct StreamingAudioView: View {
        var audioWebsocketServer: WebSocketServerManager
        @State private var audioStreamManager: AudioStreamManager?
        @State private var isStreaming = false

        var body: some View {
            VStack {
                
            }
        }
    
//        @StateObject var websocketServerManager = WebSocketServerManager(port: 8080)
//        @State private var audioStreamManager: AudioStreamManager?
//        @State private var isStreaming = false
//
//        var body: some View {
//            VStack {
//                Button(action: {
//                    if isStreaming {
//                        audioStreamManager?.stopStreaming()
//                    } else {
//                        audioStreamManager = AudioStreamManager(websocketServerManager: websocketServerManager)
//                        audioStreamManager?.startStreaming()
//                    }
//                    isStreaming.toggle()
//                }) {
//                    Text(isStreaming ? "Stop Streaming Audio" : "Start Streaming Audio")
//                        .padding()
//                        .background(Color.blue)
//                        .foregroundColor(.white)
//                        .cornerRadius(10)
//                }
//            }
//            .onAppear {
//                // Start the WebSocket server
//                try? websocketServerManager.start()
//            }
//        }
}

