//
//  TestServerVieww.swift
//  MagiClaw
//
//  Created by 吴天禹 on 2024/8/23.
//
#if os(iOS)
import SwiftUI

struct TestServerView: View {
    @EnvironmentObject var serverManager: WebSocketServerManager
    
    @State private var message = ""
    @State private var messages: [String] = []
    
    var body: some View {
        VStack {
            TextField("Enter message", text: $message)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
            
            Button("Send to all clients") {
                sendToClients(message: message)
                message = "" 
            }
            .padding()
            
            List(messages, id: \.self) { msg in
                Text(msg)
            }
        }
        .padding()
    }
    
    private func sendToClients(message: String) {
        // 发送文本数据到所有连接的客户端
        serverManager.connectionsByID.values.forEach { connection in
            connection.send(text: message)
        }

        // 将发送的消息添加到视图中以显示
        messages.append("Sent: \(message)")
    }
    
    
}

#Preview {
    TestServerView()
}
#endif
