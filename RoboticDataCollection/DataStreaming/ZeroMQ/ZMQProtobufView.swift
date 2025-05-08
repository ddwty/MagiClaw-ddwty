//
//  ZMQProtobufView.swift
//  MagiClaw
//
//  Created by Tianyu on 5/7/25.
//

import SwiftUI
import SwiftProtobuf

#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

struct ZMQProtobufView: View {
    @State private var publisher = ZMQManager.shared
    @State private var subscriber = ZMQSubscriber.shared
    
    // 根据平台设置不同的默认值
    #if os(iOS)
    @State private var publisherEndpoint = "tcp://*:5555"
    @State private var subscriberEndpoint = "tcp://192.168.31.37:5556"  // Mac的IP
    #elseif os(macOS)
    @State private var publisherEndpoint = "tcp://*:5556"
    @State private var subscriberEndpoint = "tcp://192.168.31.222:5555"  // iPhone的IP
    #endif
    
    @State private var statusMessage = ""
    @State private var statusColor: Color = .gray
    
    @State private var receivedPhoneData: Phone_Phone?
    @State private var receivedImageData: Data?
    
    // 图片循环发送相关状态
    @State private var currentImageIndex = 0
    private let imageNames = ["fakeARView", "fakeARView2", "fakeRemoteView"]
    
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
            
            ScrollView {
                VStack(spacing: 20) {
                    #if os(iOS)
                    // iPhone: 发送数据部分
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Send Protobuf Data")
                            .font(.headline)
                        
                        // 显示当前将要发送的图片名称
                        Text("Next image: \(imageNames[currentImageIndex])")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Button("Send Phone Data") {
                            sendPhoneData()
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(!publisher.isConnected)
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.blue.opacity(0.1))
                    )
                    .padding(.horizontal)
                    #endif
                    
                    #if os(macOS)
                    // Mac: 接收数据部分
                    if let phoneData = receivedPhoneData {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Received Phone Data")
                                .font(.headline)
                            
                            Group {
                                Text("Timestamp: \(phoneData.timestamp)")
                                Text("Depth Size: \(phoneData.depthWidth) x \(phoneData.depthHeight)")
                                Text("Depth Data: \(phoneData.depthImg.prefix(5).map { String($0) }.joined(separator: ", "))...")
                                Text("Pose Data: \(phoneData.pose.prefix(5).map { String($0) }.joined(separator: ", "))...")
                            }
                            .font(.caption)
                            
                            if let imageData = receivedImageData, let image = createImage(from: imageData) {
                                Image(nsImage: image)
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(height: 300)
                            } else {
                                Text("No image data received")
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color.green.opacity(0.1))
                        )
                        .padding(.horizontal)
                    } else {
                        Text("Waiting for data...")
                            .foregroundColor(.secondary)
                            .padding()
                    }
                    #endif
                    
                    // 连接状态
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Connection Status")
                            .font(.headline)
                        
                        HStack {
                            Text("Publisher: \(publisher.isConnected ? "Connected" : "Disconnected")")
                                .foregroundColor(publisher.isConnected ? .green : .red)
                            
                            Spacer()
                            
                            Button(publisher.isConnected ? "Disconnect" : "Connect") {
                                if publisher.isConnected {
                                    safeDisconnectPublisher()
                                } else {
                                    connectPublisher()
                                }
                            }
                            .buttonStyle(.bordered)
                        }
                        
                        Text(publisherEndpoint)
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Divider()
                        
                        HStack {
                            Text("Subscriber: \(subscriber.isConnected ? "Connected" : "Disconnected")")
                                .foregroundColor(subscriber.isConnected ? .green : .red)
                            
                            Spacer()
                            
                            Button(subscriber.isConnected ? "Disconnect" : "Connect") {
                                if subscriber.isConnected {
                                    safeDisconnectSubscriber()
                                } else {
                                    connectSubscriber()
                                }
                            }
                            .buttonStyle(.bordered)
                        }
                        
                        Text(subscriberEndpoint)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.gray.opacity(0.1))
                    )
                    .padding(.horizontal)
                }
                .padding(.vertical)
            }
        }
        .navigationTitle("ZMQ Protobuf")
        .onAppear {
            // 自动连接发布者和订阅者
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                connectPublisher()
                
                // 延迟一点连接订阅者，确保发布者已经启动
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    connectSubscriber()
                    
                    // 设置订阅者回调
                    setupSubscriberCallback()
                }
            }
        }
        .onDisappear {
            safeDisconnectPublisher()
            safeDisconnectSubscriber()
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
    
    private func safeDisconnectPublisher() {
        // 使用主线程安全地断开连接
        DispatchQueue.main.async {
            if publisher.isConnected {
                publisher.closePublisher()
                updateStatus("Publisher disconnected", color: .orange)
            }
        }
    }
    
    private func connectSubscriber() {
        let success = subscriber.initSubscriber(endpoint: subscriberEndpoint, topics: ["protobuf"])
        if success {
            subscriber.startReceiving()
            updateStatus("Subscriber connected successfully", color: .green)
        } else {
            updateStatus(subscriber.lastError ?? "Subscriber connection failed", color: .red)
        }
    }
    
    private func safeDisconnectSubscriber() {
        // 使用主线程安全地断开连接
        DispatchQueue.main.async {
            if subscriber.isConnected {
                // 先移除回调，避免回调中访问已释放的资源
                subscriber.messageCallback = nil
                subscriber.closeSubscriber()
                updateStatus("Subscriber disconnected", color: .orange)
            }
        }
    }
    
    private func setupSubscriberCallback() {
        #if os(macOS)
        // 设置接收到消息的回调
        subscriber.messageCallback = { topic, content in
            if topic == "protobuf" {
                do {
                    print("Received protobuf data: \(content.count) bytes")
                    
                    // 解析Protobuf数据
                    let phoneData = try Phone_Phone(serializedData: content)
                    
                    // 更新UI
                    DispatchQueue.main.async { [self] in
                        self.receivedPhoneData = phoneData
                        self.receivedImageData = phoneData.colorImg
                        self.updateStatus("Received phone data (\(content.count) bytes)", color: .green)
                    }
                } catch {
                    print("Failed to parse protobuf data: \(error)")
                    print("Data size: \(content.count) bytes")
                    
                    DispatchQueue.main.async { [self] in
                        self.updateStatus("Failed to parse protobuf data: \(error.localizedDescription)", color: .red)
                    }
                }
            }
        }
        #endif
    }
    
    #if os(iOS)
    private func sendPhoneData() {
        // 创建Phone_Phone对象
        var phoneData = Phone_Phone()
        
        // 设置时间戳为当前时间
        phoneData.timestamp = Float(Date().timeIntervalSince1970)
        
        // 获取当前要发送的图片名称
        let currentImageName = imageNames[currentImageIndex]
        
        // 设置图像数据 - 使用更低的压缩质量
        if let image = UIImage(named: currentImageName) {
            // 先调整图像大小
            let maxSize: CGFloat = 800
            let scale = min(maxSize / image.size.width, maxSize / image.size.height)
            let newSize = CGSize(width: image.size.width * scale, height: image.size.height * scale)
            
            UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
            image.draw(in: CGRect(origin: .zero, size: newSize))
            let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            
            // 使用较低的压缩质量
            if let imageData = resizedImage?.jpegData(compressionQuality: 0.5) {
                phoneData.colorImg = imageData
                print("Image data size: \(imageData.count) bytes for image: \(currentImageName)")
            } else {
                updateStatus("Failed to compress image", color: .red)
                return
            }
        } else {
            updateStatus("Failed to load image: \(currentImageName)", color: .red)
            return
        }
        
        // 设置深度图尺寸
        phoneData.depthWidth = 256
        phoneData.depthHeight = 192
        
        // 设置随机深度图数据 - 减少数据量
        phoneData.depthImg = (0..<50).map { _ in Int32.random(in: 0...1000) }
        
        // 设置随机姿态数据
        phoneData.pose = (0..<16).map { _ in Float.random(in: 0...200) }
        
        do {
            // 序列化为二进制数据
            let serializedData = try phoneData.serializedData()
            print("Serialized data size: \(serializedData.count) bytes")
            
            // 使用ZMQ发送
            let success = publisher.sendData(serializedData, topic: "protobuf")
            
            if success {
                updateStatus("Sent image: \(currentImageName) (\(serializedData.count) bytes)", color: .green)
                
                // 更新索引，准备下一次发送不同的图片
                currentImageIndex = (currentImageIndex + 1) % imageNames.count
            } else {
                updateStatus(publisher.lastError ?? "Failed to send data", color: .red)
            }
        } catch {
            updateStatus("Failed to serialize protobuf data: \(error.localizedDescription)", color: .red)
        }
    }
    #endif
    
    private func updateStatus(_ message: String, color: Color) {
        DispatchQueue.main.async {
            self.statusMessage = message
            self.statusColor = color
        }
    }
    
    #if os(macOS)
    private func createImage(from data: Data) -> NSImage? {
        return NSImage(data: data)
    }
    #endif
}

#Preview {
    ZMQProtobufView()
} 
