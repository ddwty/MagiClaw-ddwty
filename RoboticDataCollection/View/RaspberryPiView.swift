//
//  RaspberryPiView.swift
//  talkWithRpi
//
//  Created by Tianyu on 7/15/24.
// 使用访问GeS的树莓派

import SwiftUI
import Combine
import Starscream

struct RaspberryPiView: View {
//    @ObservedObject var webSocketManager = WebSocketManager.shared
    @EnvironmentObject var webSocketManager: WebSocketManager
    @State private var message: String = ""
        var body: some View {
            VStack {
                if webSocketManager.isConnected {
                    Label("Connected", systemImage: "checkmark.circle")
                        .font(.title)
                        .foregroundColor(.green)
                        .symbolEffect(.bounce, value: webSocketManager.isConnected)
                } else {
                    Label("Disconnected", systemImage: "wifi.router")
                        .foregroundColor(.red)
                        .font(.title)
                        .symbolEffect(.variableColor.iterative.reversing)
                }
//                Label(webSocketManager.isConnected ? "Connected" : "Disconnected", systemImage: webSocketManager.isConnected ? "checkmark.circle" : "xmark.circle")
//                    .font(.title)
//                    .foregroundColor(webSocketManager.isConnected ? .green : .red)
                //                Button(action: {webSocketManager.connect()}) {
//                HStack{
//                    Button(action: {
//                        if webSocketManager.isConnected {
//                            webSocketManager.disconnect()
//                        } else {
//                            webSocketManager.reConnectToServer()
//                        }
//                    }) {
//                        Text(webSocketManager.isConnected ? "Disconnect" : "Reconnect to Raspberry Pi")
//                    }
//                    .buttonStyle(BorderedButtonStyle())
//                    
//                    
//                    Button(action: {
//                        webSocketManager.connectLeftFinger()
//                    }) {
//                        Text("Get Force Data")
//                    }
//                    .disabled(!webSocketManager.isConnected)
////                    .padding()
//                    
//                    
//                }
//                Text("Received message: \(webSocketManager.receivedMessage)")
//                    .padding()
            }
        }
}

struct FilledButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(8)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
    }
}

struct ViaWifiView_Previews: PreviewProvider {
    static var previews: some View {
        RaspberryPiView()
            .environmentObject(WebSocketManager.shared)
    }
}
