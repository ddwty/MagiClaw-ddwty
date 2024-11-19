//
//  WebSocketManager.swift
//  MagiClawClient
//
//  Created by Tianyu on 9/20/24.
//


import SwiftUI
import Starscream
import CoreImage
import CoreImage.CIFilterBuiltins

@Observable
class ControlWebsocket {
    var isConnected: Bool = false
    var receivedTextMessage: String = ""
    var receivedBinaryData: Data = Data()
    
    var receivedAngle: Float = 0
    var receivedPose: [Float] = []
    var receivedDepthBuffer: [UInt16] = []
    var receivedImage: UIImage? = nil
    
    var hostname = "192.168.5.3"
    var port = "8080"
    
    private var controlSocket: WebSocket?
    
    func connect2iphone() {
        guard let url = URL(string: "ws://\(self.hostname):\(self.port)") else {
            print("Invalid URL")
            return
        }
        
        let connectRequest = URLRequest(url: url)
        controlSocket = WebSocket(request: connectRequest)
        controlSocket?.connect()
        controlSocket?.onEvent = {[weak self] event in
            guard let self = self else { return }
            switch event {
            case .connected(let headers):
                self.isConnected = true
            case .disconnected(let reason, let code):
                self.isConnected = false
//                self.attemptReconnect()
            case .text(let string):
                print("Receive text:")
                print("\(string)")
            case .binary(let data):
                handleReceivedData(data: data)
            case .ping(_):
                break
            case .pong(_):
                break
            case .viabilityChanged(let isViable):
                self.isConnected = isViable  //在这里得知是否连接
            case .reconnectSuggested(_):
                break
            case .cancelled:
                self.isConnected = false
                print("WebSocket is cancelled")
//                self.attemptReconnect()
            case .peerClosed:
                break
            case .error(let error):
                self.isConnected = false
                print("WebSocket encountered an error: \(error?.localizedDescription ?? "")")
//                self.attemptReconnect()
            }
        }
    }
    private func attemptReconnect() {
        print("Attempting to reconnect...)")
        
        // 延迟重连
//        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
//            self.reConnectToServer() // 重连到服务器
//        }
    }
    
    func reConnectToServer() {
        disconnect()  // 先断开现有连接
        connect2iphone()
//        connectAngel()
    }
    
    func disconnect() {
        print("trying to disconnect")
        isConnected = false
        controlSocket?.disconnect()
        // 确保所有 WebSocket 都断开后更新连接状态
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                let newIsConnected = self.isConnected
                if self.isConnected != newIsConnected {
                    self.isConnected = newIsConnected
                }
            }
    }
    
    private func handleReceivedData(data: Data) {
        let angleSize = MemoryLayout<Float>.size
        let poseSize = 16 * MemoryLayout<Float>.size  // 假设 pose 包含 16 个 Float
        let depthWidth = 256
        let depthHeight = 192
        let depthSize = depthWidth * depthHeight * MemoryLayout<UInt16>.size
        
        var currentOffset = 0
        
        // 解析 angle 数据
        let angleData = data.subdata(in: currentOffset..<(currentOffset + angleSize))
        let angle = angleData.withUnsafeBytes { $0.load(as: Float.self) }
        self.receivedAngle = angle
        currentOffset += angleSize
        
        // 解析 pose 数据
        let poseData = data.subdata(in: currentOffset..<(currentOffset + poseSize))
        var pose: [Float] = []
        for i in stride(from: 0, to: poseSize, by: MemoryLayout<Float>.size) {
            let floatData = poseData.subdata(in: i..<(i + MemoryLayout<Float>.size))
            let floatValue = floatData.withUnsafeBytes { $0.load(as: Float.self) }
            pose.append(floatValue)
        }
        self.receivedPose = pose
        currentOffset += poseSize
        
        // 解析 depth 数据
        if data.count >= currentOffset + depthSize {
            let depthData = data.subdata(in: currentOffset..<(currentOffset + depthSize))
            var depthBuffer = [UInt16](repeating: 0, count: depthWidth * depthHeight)
            depthData.withUnsafeBytes { bufferPointer in
                _ = memcpy(&depthBuffer, bufferPointer.baseAddress!, depthSize)
            }
            self.receivedDepthBuffer = depthBuffer  // 假设您有一个变量存储 depthBuffer
            currentOffset += depthSize
//            print("Received dePTH data")
        } else {
            print("No depth data found")
        }
        
        // 解析 image 数据
        if data.count > currentOffset {
            let imageData = data.subdata(in: currentOffset..<data.count)
            if let image = UIImage(data: imageData) {
                self.receivedImage = image
            } else {
                print("Failed to create image from received data")
            }
        } else {
            print("No image data found")
        }
    }
}

