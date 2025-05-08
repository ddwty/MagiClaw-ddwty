//
//  ZMQSubscriber.swift
//  MagiClaw
//
//  Created by Tianyu on 5/7/25.
//

import Foundation
import SwiftUI
import Combine

@Observable
class ZMQSubscriber {
    static let shared = ZMQSubscriber()
    
    private(set) var isConnected = false
    private(set) var lastError: String?
    private(set) var endpoint: String = "tcp://localhost:5555"
    private(set) var messages: [ZMQMessage] = []
    private(set) var isReceiving = false
    
    private var receiveTimer: Timer?
    private let maxMessages = 100
    
    // 消息回调类型
    typealias MessageCallback = (String, Data) -> Void
    
    // 消息回调属性
    var messageCallback: MessageCallback?
    
    struct ZMQMessage: Identifiable {
        let id = UUID()
        let topic: String
        let content: String
        let timestamp: Date
        
        init(topic: String, content: String) {
            self.topic = topic
            self.content = content
            self.timestamp = Date()
        }
    }
    
    private init() {}
    
    // 初始化ZMQ订阅者
    func initSubscriber(endpoint: String? = nil, topics: [String]? = nil) -> Bool {
        if let endpoint = endpoint {
            self.endpoint = endpoint
        }
        
        guard let endpointCString = self.endpoint.cString(using: .utf8) else {
            lastError = "无效的端点地址"
            return false
        }
        
        let result: Int32
        
        if let topics = topics, !topics.isEmpty {
            // 使用临时数组存储C字符串
            let topicsCount = topics.count
            let topicsCStrings = UnsafeMutablePointer<UnsafeMutablePointer<CChar>?>.allocate(capacity: topicsCount)
            
            // 为每个主题分配内存并复制字符串
            for i in 0..<topicsCount {
                if let cString = topics[i].cString(using: .utf8) {
                    let buffer = UnsafeMutablePointer<CChar>.allocate(capacity: cString.count)
                    buffer.initialize(from: cString, count: cString.count)
                    topicsCStrings[i] = buffer
                }
            }
            
            // 使用unsafeBitCast进行类型转换
            let constTopics = unsafeBitCast(topicsCStrings, to: UnsafeMutablePointer<UnsafePointer<CChar>?>.self)
            
            // 调用C函数
            result = zmq_init_subscriber(endpointCString, constTopics, Int32(topicsCount))
            
            // 释放内存
            for i in 0..<topicsCount {
                if let ptr = topicsCStrings[i] {
                    ptr.deallocate()
                }
            }
            topicsCStrings.deallocate()
        } else {
            result = zmq_init_subscriber(endpointCString, nil, 0)
        }
        
        if result == 0 {
            isConnected = true
            lastError = nil
            return true
        } else {
            isConnected = false
            lastError = "初始化ZMQ订阅者失败，错误代码: \(result)"
            return false
        }
    }
    
    // 开始接收消息
    func startReceiving() {
        guard isConnected else {
            lastError = "ZMQ未连接"
            return
        }
        
        if isReceiving {
            stopReceiving()
        }
        
        isReceiving = true
        
        // 创建定时器，定期检查是否有新消息
        receiveTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            self?.receiveMessage()
        }
    }
    
    // 停止接收消息
    func stopReceiving() {
        receiveTimer?.invalidate()
        receiveTimer = nil
        isReceiving = false
    }
    
    // 接收消息
    private func receiveMessage() {
        let topicBufferSize = 256
        let dataBufferSize = 1024 * 1024  // 增加到1MB
        
        let topicBuffer = UnsafeMutablePointer<CChar>.allocate(capacity: topicBufferSize)
        let dataBuffer = UnsafeMutablePointer<CChar>.allocate(capacity: dataBufferSize)
        
        defer {
            topicBuffer.deallocate()
            dataBuffer.deallocate()
        }
        
        let result = zmq_receive_data(topicBuffer, topicBufferSize, dataBuffer, dataBufferSize)
        
        if result > 0 {
            // 成功接收到消息
            let topic = String(cString: topicBuffer)
            
            // 创建Data对象
            let data = Data(bytes: dataBuffer, count: Int(result))
            
            // 如果是文本消息，创建ZMQMessage对象
            if let content = String(data: data, encoding: .utf8) {
                let message = ZMQMessage(topic: topic, content: content)
                
                DispatchQueue.main.async { [weak self] in
                    guard let self = self else { return }
                    
                    // 添加新消息到列表
                    self.messages.insert(message, at: 0)
                    
                    // 限制消息数量
                    if self.messages.count > self.maxMessages {
                        self.messages = Array(self.messages.prefix(self.maxMessages))
                    }
                }
            }
            
            // 调用回调函数
            messageCallback?(topic, data)
        } else if result < 0 {
            // 接收错误
            lastError = "接收消息失败，错误代码: \(result)"
            stopReceiving()
        }
    }
    
    // 清除消息
    func clearMessages() {
        messages.removeAll()
    }
    
    // 关闭ZMQ订阅者
    func closeSubscriber() {
        stopReceiving()
        zmq_close_subscriber()
        isConnected = false
    }
    
    // 添加本地发送的消息到消息列表
    func addLocalMessage(_ message: ZMQMessage) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            // 添加新消息到列表
            self.messages.insert(message, at: 0)
            
            // 限制消息数量
            if self.messages.count > self.maxMessages {
                self.messages = Array(self.messages.prefix(self.maxMessages))
            }
        }
    }
    
    deinit {
        closeSubscriber()
    }
}
