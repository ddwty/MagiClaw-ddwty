//
//  RaspberryPiStatusView.swift
//  MagiClaw
//
//  Created by 吴天禹 on 2024/8/21.
//
#if os(iOS)
import SwiftUI

struct RaspberryPiStatusView: View {
    @Environment(WebSocketManager.self) private var webSocketManager
    var body: some View {
        VStack(alignment: .leading) {
            Text("Raspberry Pi Status")
                .font(.headline)
            Divider()
            HStack {
                if self.webSocketManager.isLeftFingerConnected {
                    Circle()
                        .frame(width: 15)
                        .foregroundColor(.green)
                } else {
                    Circle()
                        .frame(width: 15)
                        .foregroundColor(.red)
                }
                Text("Left finger")
            }
            HStack {
                if self.webSocketManager.isRightFingerConnected {
                    Circle()
                        .frame(width: 15)
                        .foregroundColor(.green)
                } else {
                    Circle()
                        .frame(width: 15)
                        .foregroundColor(.red)
                }
                Text("Right finger")
            }
            HStack {
                if self.webSocketManager.isAngelConnected {
                    Circle()
                        .frame(width: 15)
                        .foregroundColor(.green)
                } else {
                    Circle()
                        .frame(width: 15)
                        .foregroundColor(.red)
                }
                Text("Angle encoder")
            }
            if !self.webSocketManager.isConnected {
                Divider()
                Button(action: {
                    webSocketManager.reConnectToServer()
                }) {
                    Label("Reconnect",systemImage: "arrow.clockwise.circle")
                 
                }
                .buttonStyle(.bordered)
                .tint(.blue)
                .controlSize(.regular)
//                .padding()
//                .background(
//                   RoundedRectangle(cornerRadius: 10)
//                    .foregroundColor(Color(UIColor.systemGray5))
//
//                )
                
            }
        }
    }
}

#Preview {
    RaspberryPiStatusView()
        .environment(WebSocketManager.shared)
}
#endif
