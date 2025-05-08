//
//  ZMQChatView.swift
//  MagiClaw
//
//  Created by Tianyu on 5/7/25.
//

import SwiftUI

#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

struct ZMQChatView: View {
    @State private var publisher = ZMQManager.shared
    @State private var subscriber = ZMQSubscriber.shared
    
    @State private var message = ""
    
    // 根据平台设置不同的默认值
    #if os(iOS)
    @State private var publisherEndpoint = "tcp://*:5555"
    @State private var subscriberEndpoint = "tcp://192.168.31.37:5556"  // Mac的IP
    #elseif os(macOS)
    @State private var publisherEndpoint = "tcp://*:5556"
    @State private var subscriberEndpoint = "tcp://192.168.31.222:5555"  // iPhone的IP
    #endif
    
    @State private var deviceName = getDeviceName()
    
    @State private var statusMessage = ""
    @State private var statusColor: Color = .gray
    
    @State private var isEditingPublisher = false
    @State private var isEditingSubscriber = false
    @State private var tempPublisherEndpoint = ""
    @State private var tempSubscriberEndpoint = ""
    
    var body: some View {
        VStack(spacing: 0) {
            // Status bar
            HStack {
                Circle()
                    .fill(statusColor)
                    .frame(width: 10, height: 10)
                Text(statusMessage)
                    .font(.caption)
                Spacer()
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background(Color.gray.opacity(0.1))
            
            Form {
                Section(header: Text("Device Information")) {
                    TextField("Device Name", text: $deviceName)
                }
                
                Section(header: Text("Connection Settings")) {
                    VStack(alignment: .leading) {
                        HStack {
                            Text("Publisher: \(publisher.isConnected ? "Connected" : "Disconnected")")
                                .foregroundColor(publisher.isConnected ? .green : .red)
                            Spacer()
                            Button(isEditingPublisher ? "Done" : "Edit") {
                                if isEditingPublisher {
                                    // 完成编辑，应用更改
                                    if tempPublisherEndpoint != publisherEndpoint {
                                        publisherEndpoint = tempPublisherEndpoint
                                        if publisher.isConnected {
                                            publisher.closePublisher()
                                            connectPublisher()
                                        }
                                    }
                                } else {
                                    // 开始编辑
                                    tempPublisherEndpoint = publisherEndpoint
                                }
                                isEditingPublisher.toggle()
                            }
                            .buttonStyle(.borderless)
                        }
                        
                        if isEditingPublisher {
                            TextField("Publisher Endpoint", text: $tempPublisherEndpoint)
                                #if os(iOS)
                                .autocapitalization(.none)
                                .disableAutocorrection(true)
                                #endif
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                        } else {
                            Text(publisherEndpoint)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Button(publisher.isConnected ? "Disconnect Publisher" : "Connect Publisher") {
                            if publisher.isConnected {
                                publisher.closePublisher()
                                updateStatus("Publisher disconnected", color: .orange)
                            } else {
                                connectPublisher()
                            }
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    
                    Divider()
                    
                    VStack(alignment: .leading) {
                        HStack {
                            Text("Subscriber: \(subscriber.isConnected ? "Connected" : "Disconnected")")
                                .foregroundColor(subscriber.isConnected ? .green : .red)
                            Spacer()
                            Button(isEditingSubscriber ? "Done" : "Edit") {
                                if isEditingSubscriber {
                                    // 完成编辑，应用更改
                                    if tempSubscriberEndpoint != subscriberEndpoint {
                                        subscriberEndpoint = tempSubscriberEndpoint
                                        if subscriber.isConnected {
                                            subscriber.closeSubscriber()
                                            connectSubscriber()
                                        }
                                    }
                                } else {
                                    // 开始编辑
                                    tempSubscriberEndpoint = subscriberEndpoint
                                }
                                isEditingSubscriber.toggle()
                            }
                            .buttonStyle(.borderless)
                        }
                        
                        if isEditingSubscriber {
                            TextField("Subscriber Endpoint", text: $tempSubscriberEndpoint)
                                #if os(iOS)
                                .autocapitalization(.none)
                                .disableAutocorrection(true)
                                #endif
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                        } else {
                            Text(subscriberEndpoint)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Button(subscriber.isConnected ? "Disconnect Subscriber" : "Connect Subscriber") {
                            if subscriber.isConnected {
                                subscriber.closeSubscriber()
                                updateStatus("Subscriber disconnected", color: .orange)
                            } else {
                                connectSubscriber()
                            }
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }
                
                Section(header: Text("Messages")) {
                    VStack(spacing: 12) {
                        // Message input area
                        HStack {
                            TextField("Type a message...", text: $message)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                            
                            Button(action: {
                                sendMessage()
                            }) {
                                Image(systemName: "paperplane.fill")
                            }
                            .disabled(!publisher.isConnected || message.isEmpty)
                        }
                        
                        // Messages display area
                        if subscriber.messages.isEmpty {
                            Text("No messages yet")
                                .foregroundColor(.secondary)
                                .frame(maxWidth: .infinity, alignment: .center)
                                .padding()
                        } else {
                            ScrollViewReader { proxy in
                                ScrollView {
                                    LazyVStack(alignment: .leading, spacing: 8) {
                                        ForEach(subscriber.messages) { message in
                                            MessageView(message: message)
                                                .id(message.id)
                                        }
                                    }
                                    .padding(.horizontal, 4)
                                }
                                .frame(height: 300)
                                .onChange(of: subscriber.messages.count) { _ in
                                    if let lastMessage = subscriber.messages.first {
                                        withAnimation {
                                            proxy.scrollTo(lastMessage.id, anchor: .bottom)
                                        }
                                    }
                                }
                            }
                            
                            Button("Clear Messages") {
                                subscriber.clearMessages()
                            }
                            .foregroundStyle(.red)
                        }
                    }
                }
            }
            #if os(macOS)
            .formStyle(.grouped)
            #endif
        }
        .navigationTitle("ZMQ Chat")
        .onAppear {
            // 自动连接发布者和订阅者
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                connectPublisher()
                
                // 延迟一点连接订阅者，确保发布者已经启动
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    connectSubscriber()
                }
            }
        }
        .onDisappear {
            if publisher.isConnected {
                publisher.closePublisher()
            }
            if subscriber.isConnected {
                subscriber.closeSubscriber()
            }
        }
    }
    
    private func connectPublisher() {
        let success = publisher.initPublisher(endpoint: publisherEndpoint)
        if success {
            updateStatus("Publisher connected successfully", color: .green)
        } else {
            updateStatus(publisher.lastError ?? "Publisher connection failed", color: .red)
        }
    }
    
    private func connectSubscriber() {
        let success = subscriber.initSubscriber(endpoint: subscriberEndpoint)
        if success {
            subscriber.startReceiving()
            updateStatus("Subscriber connected successfully", color: .green)
        } else {
            updateStatus(subscriber.lastError ?? "Subscriber connection failed", color: .red)
        }
    }
    
    private func sendMessage() {
        guard !message.isEmpty, publisher.isConnected else { return }
        
        // Build message with device name
        let fullMessage = "\(deviceName): \(message)"
        
        let success = publisher.sendString(fullMessage, topic: "chat")
        if success {
            // Add the sent message to our own message list for display
            let sentMessage = ZMQSubscriber.ZMQMessage(topic: "chat", content: fullMessage)
            subscriber.addLocalMessage(sentMessage)
            
            message = ""
            updateStatus("Message sent", color: .green)
        } else {
            updateStatus(publisher.lastError ?? "Send failed", color: .red)
        }
    }
    
    private func updateStatus(_ message: String, color: Color) {
        statusMessage = message
        statusColor = color
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        return formatter.string(from: date)
    }
    
    // 获取设备名称的跨平台函数
    private static func getDeviceName() -> String {
        #if os(iOS)
        return UIDevice.current.name
        #elseif os(macOS)
        return Host.current().localizedName ?? "Mac"
        #else
        return "Unknown Device"
        #endif
    }
}

struct MessageView: View {
    let message: ZMQSubscriber.ZMQMessage
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(message.topic)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                Spacer()
                
                Text(formatDate(message.timestamp))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Text(message.content)
                .font(.body)
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 10)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(backgroundColor)
                .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
        )
    }
    
    private var backgroundColor: Color {
        #if os(iOS)
        return Color(UIColor.systemBackground)
        #elseif os(macOS)
        return Color(NSColor.windowBackgroundColor)
        #else
        return Color.white
        #endif
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        return formatter.string(from: date)
    }
}

#Preview {
    ZMQChatView()
}
