//
//  WebSocketManager.swift
//  talkWithRpi
//
//  Created by Tianyu on 7/17/24.
//

import Foundation
import Starscream
import UIKit
import SwiftUI

struct TimeStamp: Codable {
    let secs: Int
    let nanos: Int
}

struct Force: Codable {
    let value: [Double]?
}

struct FingerForce: Codable {
    let force: Force?
    let time_stamp: TimeStamp
}

struct FingerAngle: Codable {
    let time_stamp: TimeStamp
    let data: Int
}

// TODO: - 退到后台重新进入重连
class WebSocketManager: ObservableObject {
    static let shared = WebSocketManager()
    var recordedForceData: [ForceData] = []  //用于储存
    var recordedAngleData: [AngleData] = []
    @Published var forceDataforShow: ForceData?
    @Published var angleDataforShow: AngleData?
    @Published var totalForce: Double = 0
    @Published var time: TimeStamp?
    //    @Published var isConnected = false {
    //            didSet {
    //                if isConnected {
    //                    pingTimer?.invalidate()
    //                } else if shouldPing {
    //                    startPingTimer()
    //                }
    //            }
    //        }
    
    
    @Published var isConnected = false
    
    // TODO: - 通过输入框来输入hostname
    //    @Published var hostName: String = "raspberrypi.local"
    @AppStorage("hostname") private var hostname = "raspberrypi.local"
    @Published var receivedMessage: String = ""
    
    private var angelSocket: WebSocket?
    private var leftFingerSocket: WebSocket?
    private var pingTimer: Timer?
    private var shouldPing: Bool = true
    var isRecording = false
    
    private var firstTimestampOfForce = 0.0
    private var isFirstFrameOfForce = false
    private var firstTimestampOfAngle = 0.0
    private var isFirstFrameOfAngle = false
    
    
    private var isLeftFingerConnected = false {
        didSet {
            updateConnectionStatus()
        }
    }
    private var isAngelConnected = false {
        didSet {
            updateConnectionStatus()
        }
    }
    
    private var throttleTimer: Timer?
    private let throttleInterval: TimeInterval = 0.1 // 更新UI时间

    
    
    // MARK: - AND both left finger and angel connected status
    private func updateConnectionStatus() {
        self.isConnected = isLeftFingerConnected && isAngelConnected
    }
    
    private init() {
        //        connectToServer()
        self.recordedForceData.reserveCapacity(10000)
        self.recordedAngleData.reserveCapacity(100000)
        connectLeftFinger()
        connectAngel()
        
    }
    
    func reConnectToServer() {
        disconnect()  // 先断开现有连接
        connectLeftFinger()
        connectAngel()
    }
    
    func disconnect() {
        shouldPing = false
        isLeftFingerConnected = false
        isAngelConnected = false
        angelSocket?.disconnect()
        leftFingerSocket?.disconnect()
    }
    
    func connectLeftFinger() {
        var leftFingerRequest = URLRequest(url: URL(string: "ws://\(self.hostname):8080/left_finger/force")!)
        leftFingerSocket = WebSocket(request: leftFingerRequest)
        leftFingerSocket?.connect()
        leftFingerRequest.timeoutInterval = 50
        leftFingerSocket?.onEvent = { event in
            switch event {
            case .connected(let headers):
                self.isLeftFingerConnected = true
                
                print("WebSocket is connected to left finger: \(headers)")
                print("isLeftFingerConnected: \(self.isLeftFingerConnected)")
                
            case .disconnected(let reason, let code):
                self.isLeftFingerConnected = false
                print("WebSocket disconnected: \(reason) to left finger with code: \(code)")
                self.attemptReconnect()
                
            case .text(let string):
//                if self.isRecording {
                    self.handleLeftFingerMessage(string: string)
                    //                            print("Receive text from left finger message, is recording: \(self.isRecording)")
//                }
//                                        print("\(string)")
            case .binary(let data):
                print("Received data: \(data.count)")
            case .ping(_):
                break
            case .pong(_):
                break
            case .viabilityChanged(_):
                break
            case .reconnectSuggested(_):
                break
            case .cancelled:
                self.isLeftFingerConnected = false
                print("WebSocket is cancelled")
                self.attemptReconnect()
            case .peerClosed:
                break
            case .error(let error):
                self.isLeftFingerConnected = false
                print("WebSocket encountered an error: \(error?.localizedDescription ?? "")")
                self.attemptReconnect()
            }
        }
    }
    
    func connectAngel() {
        var angelRequest = URLRequest(url: URL(string: "ws://\(self.hostname):8080/angle")!)
        angelSocket = WebSocket(request: angelRequest)
        angelSocket?.connect()
        angelRequest.timeoutInterval = 5000
        angelSocket?.onEvent = { event in
            switch event {
            case .connected(let headers):
                self.isAngelConnected = true
                print("WebSocket is connected to angel: \(headers)")
                print("isAngleConnected: \(self.isAngelConnected)")
                
            case .disconnected(let reason, let code):
                self.isAngelConnected = false
                print("WebSocket disconnected: \(reason) to angel with code: \(code)")
                self.attemptReconnect()
                
            case .text(let string):
//                if self.isRecording {
                    self.handleAngleMessage(string: string)
//                }
//                                        print(string)
            case .binary(let data):
                print("Received data: \(data.count)")
            case .ping(_):
                break
            case .pong(_):
                break
            case .viabilityChanged(_):
                break
            case .reconnectSuggested(_):
                break
            case .cancelled:
                self.isLeftFingerConnected = false
                print("WebSocket is cancelled")
                self.attemptReconnect()
            case .peerClosed:
                break
            case .error(let error):
                self.isLeftFingerConnected = false
                print("WebSocket encountered an error: \(error?.localizedDescription ?? "")")
                self.attemptReconnect()
            }
        }
        
    }
    
    // TODO: - 存到同一个结构体中，保持频率一致
    func startRecordingData() {
        recordedForceData.removeAll()
        recordedAngleData.removeAll()
        
        isRecording = true
        self.isFirstFrameOfAngle = true
        self.isFirstFrameOfForce = true
    }
    
    func stopRecordingForceData() {
        isRecording = false
    }
    
    private func attemptReconnect() {
        print("Attempting to reconnect...)")
        
        // 延迟重连
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            self.reConnectToServer() // 重连到服务器
        }
    }

}

extension WebSocketManager {
    func handleLeftFingerMessage(string: String) {
        if let data = string.data(using: .utf8) {
            if let fingerForce = try? JSONDecoder().decode(FingerForce.self, from: data) {
                
                let timestamp = Double(fingerForce.time_stamp.secs) + Double(fingerForce.time_stamp.nanos) * 1e-9
                if isFirstFrameOfForce {
                    self.firstTimestampOfForce = timestamp
                    self.isFirstFrameOfForce = false
                }
                let forceData = ForceData(
                    timeStamp: timestamp - firstTimestampOfForce,
                    forceData: fingerForce.force?.value)
               
//                self.forceDataforShow = forceData
//                print(forceDataforShow?.forceData ?? [1,2,4])
//                print(forceDataforShow ?? "No force data")
                let xForce = forceData.forceData?[0] ?? 0
                let yForce = forceData.forceData?[1] ?? 0
                let zForce = forceData.forceData?[2] ?? 0
                self.totalForce = sqrt(xForce * xForce + yForce * yForce + zForce * zForce)
//                print("\(totalForce)")
                if self.isRecording {
                    //TODO: - 检查是否需要async
                    DispatchQueue.main.async {
                        self.recordedForceData.append(forceData)
                    }
                }
                throttleUpdate() // 调用节流函数
            }
        }
    }
    
    func handleAngleMessage(string: String) {
        if let data = string.data(using: .utf8) {
            if let fingerAngle = try? JSONDecoder().decode(FingerAngle.self, from: data) {
                let timestamp = Double(fingerAngle.time_stamp.secs) + Double(fingerAngle.time_stamp.nanos) * 1e-9
                if isFirstFrameOfAngle {
                    self.firstTimestampOfAngle = timestamp
                    self.isFirstFrameOfAngle = false
                }
                let angleData = AngleData(
                    timeStamp: timestamp - firstTimestampOfAngle,
                    angle: fingerAngle.data)
                self.angleDataforShow = angleData

                if self.isRecording {
                    DispatchQueue.main.async {
                        self.recordedAngleData.append(angleData)
                    }
                }
                throttleUpdate() // 调用节流函数
            }
        }
    }
}

extension WebSocketManager {
    func generateSampleData() {
        let sampleForces = [
            ForceData(timeStamp: 0, forceData: [1.0, 2.0, 3.0, 4.0, 5.0, 6.0]),
            ForceData(timeStamp: 1, forceData: [2.0, 3.0, 4.0, 5.0, 6.0, 7.0]),
            ForceData(timeStamp: 2, forceData: [3.0, 4.0, 5.0, 6.0, 7.0, 8.0])
        ]
        recordedForceData = sampleForces
    }
}

extension WebSocketManager {
  
    private func throttleUpdate() {
        throttleTimer?.invalidate() // 取消之前的定时器
        throttleTimer = Timer.scheduledTimer(withTimeInterval: throttleInterval, repeats: false) { [weak self] _ in
            DispatchQueue.main.async {
                self?.updateUI()
            }
        }
    }

    private func updateUI() {
//        self.forceDataforShow = self.recordedForceData.last
        self.totalForce = self.totalForce
        self.angleDataforShow = self.angleDataforShow
    }

    
}
