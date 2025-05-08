//
//  ZMQManager.swift
//  MagiClaw
//
//  Created by Tianyu on 5/7/25.
//

import Foundation
import SwiftUI

@Observable
class ZMQManager {
    static let shared = ZMQManager()
    
    private(set) var isConnected = false
    private(set) var lastError: String?
    private(set) var endpoint: String = "tcp://*:5555"
    
    private init() {}
    
    // 初始化ZMQ发布者
    func initPublisher(endpoint: String? = nil) -> Bool {
        if let endpoint = endpoint {
            self.endpoint = endpoint
        }
        
        guard let endpointCString = self.endpoint.cString(using: .utf8) else {
            lastError = "无效的端点地址"
            return false
        }
        
        let result = zmq_init_publisher(endpointCString)
        if result == 0 {
            isConnected = true
            lastError = nil
            return true
        } else {
            isConnected = false
            lastError = "初始化ZMQ发布者失败，错误代码: \(result)"
            return false
        }
    }
    
    // 发送字符串数据
    func sendString(_ message: String, topic: String = "message") -> Bool {
        guard isConnected else {
            lastError = "ZMQ未连接"
            return false
        }
        
        guard let messageCString = message.cString(using: .utf8),
              let topicCString = topic.cString(using: .utf8) else {
            lastError = "无效的消息或主题"
            return false
        }
        
        let result = zmq_send_data(topicCString, messageCString, strlen(messageCString))
        if result == 0 {
            lastError = nil
            return true
        } else {
            lastError = "发送消息失败，错误代码: \(result)"
            return false
        }
    }
    
    // 发送JSON数据
    func sendJSON<T: Encodable>(_ data: T, topic: String = "json") -> Bool {
        do {
            let jsonData = try JSONEncoder().encode(data)
            return sendData(jsonData, topic: topic)
        } catch {
            lastError = "JSON编码失败: \(error.localizedDescription)"
            return false
        }
    }
    
    // 发送二进制数据
    func sendData(_ data: Data, topic: String = "data") -> Bool {
        guard isConnected else {
            lastError = "ZMQ未连接"
            return false
        }
        
        guard let topicCString = topic.cString(using: .utf8) else {
            lastError = "无效的主题"
            return false
        }
        
        return data.withUnsafeBytes { bufferPointer in
            let result = zmq_send_data(topicCString, bufferPointer.baseAddress, data.count)
            if result == 0 {
                lastError = nil
                return true
            } else {
                lastError = "发送数据失败，错误代码: \(result)"
                return false
            }
        }
    }
    
    // 关闭ZMQ发布者
    func closePublisher() {
        zmq_close_publisher()
        isConnected = false
    }
}
