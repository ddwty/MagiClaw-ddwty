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
    @Environment(\.verticalSizeClass) var verticalSizeClass
    @Environment(WebSocketManager.self) private var webSocketManager
    @State private var message: String = ""
        var body: some View {
            HStack {
               
                
                if webSocketManager.isConnected {
                    Label("Connected", systemImage: "checkmark.circle")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.green)
                    
                        .symbolEffect(.bounce, value: webSocketManager.isConnected)
                } else {
                    HStack {
                        Label("Disconnected", systemImage: "wifi.router")
                            .foregroundColor(.red)
                            .font(.title3)
                            .fontWeight(.bold)
                            .symbolEffect(.variableColor.iterative.reversing)
                        Button(action: {
                                webSocketManager.reConnectToServer()
                        }) {
                            Image(systemName: "arrow.clockwise.circle")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 30, height: 30)
                        }
                    }
                }
               
                   
                
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
            .environment(WebSocketManager.shared)
    }
}
