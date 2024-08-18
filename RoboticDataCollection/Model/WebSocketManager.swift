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
@Observable class WebSocketManager {
    static let shared = WebSocketManager()
   
    var recordedForceData: [ForceData] = []  //用于储存
    var recordedRightFingerForceData: [ForceData] = []
    var recordedAngleData: [AngleData] = []
    
    public var forceDataforShow: ForceData?
    public var angleDataforShow: Int = 0
    public var totalLeftForce: Double = 0
    public var totalRightForce: Double = 0
    public var time: TimeStamp?
    
    public var isConnected = false
    
    @ObservationIgnored @AppStorage("hostname") private var hostname = "raspberrypi.local"
    public var receivedMessage: String = ""
    
    private var angelSocket: WebSocket?
    private var leftFingerSocket: WebSocket?
    private var rightFingerSocket: WebSocket?
    private var pingTimer: Timer?
    private var shouldPing: Bool = true
    var isRecording = false
    
    private var firstTimestampOfForce = 0.0
    private var isFirstFrameOfForce = false
    private var firstTimestampOfAngle = 0.0
    private var isFirstFrameOfAngle = false
    
    
    public var isLeftFingerConnected = false {
        didSet {
            updateConnectionStatus()
        }
    }
    
    public var isRightFingerConnected = false {
        didSet {
            updateConnectionStatus()
        }
    }
    
    public var isAngelConnected = false {
        didSet {
            updateConnectionStatus()
        }
    }
    
    
//    public var isRightFingerConnected = false
    
    private var throttleTimer: Timer?
    private let throttleInterval: TimeInterval = 1 // 更新UI时间
    
    
    
    // MARK: - AND both left finger and angel connected status
    private func updateConnectionStatus() {
        self.isConnected = isLeftFingerConnected  && isRightFingerConnected && isAngelConnected
    }
    
    private init() {
        //        connectToServer()
        self.recordedForceData.reserveCapacity(10000)
        self.recordedRightFingerForceData.reserveCapacity(10000)
        self.recordedAngleData.reserveCapacity(100000)
        connectLeftFinger()
        connectRightFinger()
        
        connectAngel()
        
    }
    
    func reConnectToServer() {
        disconnect()  // 先断开现有连接
        connectLeftFinger()
        connectAngel()
    }
    
    private func disconnect() {
        shouldPing = false
        isLeftFingerConnected = false
        isAngelConnected = false
        angelSocket?.disconnect()
        leftFingerSocket?.disconnect()
    }
    
    private func connectLeftFinger() {
        let leftFingerRequest = URLRequest(url: URL(string: "ws://\(self.hostname):8080/left_finger/force")!)
        leftFingerSocket = WebSocket(request: leftFingerRequest)
        leftFingerSocket?.connect()
        //        leftFingerRequest.timeoutInterval = 1
        leftFingerSocket?.onEvent = {[weak self] event in
            guard let self = self else { return }
            switch event {
            case .connected(let headers):
                self.isLeftFingerConnected = true
                
                print("WebSocket is connected to left finger:")
                print("isLeftFingerConnected: \(self.isLeftFingerConnected)")
                
            case .disconnected(let reason, let code):
                self.isLeftFingerConnected = false
                print("disconnect to left finger: \(self.isLeftFingerConnected)")
                print("WebSocket disconnected: \(reason) to left finger with code: \(code)")
                self.attemptReconnect()
                
            case .text(let string):
                //                if self.isRecording {
                self.handleLeftFingerMessage(string: string)
                //                            print("Receive text from left finger message, is recording: \(self.isRecording)")
                //                }
//                print("\(string)")
            case .binary(let data):
                print("Received data: \(data.count)")
            case .ping(_):
                break
            case .pong(_):
                break
            case .viabilityChanged(let isViable):
                self.isLeftFingerConnected = isViable  //在这里得知是否连接
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
    
    private func connectRightFinger() {
        let rightFingerRequest = URLRequest(url: URL(string: "ws://\(self.hostname):8080/right_finger/force")!)
        rightFingerSocket = WebSocket(request: rightFingerRequest)
        rightFingerSocket?.connect()
        //        leftFingerRequest.timeoutInterval = 1
        rightFingerSocket?.onEvent = {[weak self] event in
            guard let self = self else { return }
            switch event {
            case .connected(let headers):
                self.isRightFingerConnected = true
                
                print("WebSocket is connected to right finger:")
                
            case .disconnected(let reason, let code):
                self.isRightFingerConnected = false
//                print("disconnect to left finger: \(self.isLeftFingerConnected)")
                print("WebSocket disconnected: \(reason) to left finger with code: \(code)")
                self.attemptReconnect()
                
            case .text(let string):
                //                if self.isRecording {
                self.handleRightFingerMessage(string: string)
                //                            print("Receive text from left finger message, is recording: \(self.isRecording)")
                //                }
//                print("\(string)")
            case .binary(let data):
                print("Received data: \(data.count)")
            case .ping(_):
                break
            case .pong(_):
                break
            case .viabilityChanged(let isViable):
                self.isRightFingerConnected = isViable  //在这里得知是否连接
            case .reconnectSuggested(_):
                break
            case .cancelled:
                self.isRightFingerConnected = false
                print("WebSocket is cancelled")
                self.attemptReconnect()
            case .peerClosed:
                break
            case .error(let error):
                self.isRightFingerConnected = false
                print("WebSocket encountered an error: \(error?.localizedDescription ?? "")")
                self.attemptReconnect()
            }
        }
    }
    
    private func connectAngel() {
        let angelRequest = URLRequest(url: URL(string: "ws://\(self.hostname):8080/angle")!)
        angelSocket = WebSocket(request: angelRequest)
        angelSocket?.connect()
        //        angelRequest.timeoutInterval = 1
        angelSocket?.onEvent = { [weak self]  event in
            guard let self = self else { return }
            switch event {
            case .connected(let headers):
                self.isAngelConnected = true
                print("WebSocket is connected to angel")
                print("isAngleConnected: \(self.isAngelConnected)")
                
            case .disconnected(let reason, let code):
                self.isAngelConnected = false
                print("disconnect to Angel: \(self.isAngelConnected)")
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
            case .viabilityChanged(let isViable):
                print("WebSocket viability changed: \(isViable)")
                self.isAngelConnected = isViable //在这里得知是否连接
            case .reconnectSuggested(let shouldReconnect):
                print("Reconnect suggested: \(shouldReconnect)")
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
        self.recordedForceData.removeAll()
        self.recordedAngleData.removeAll()
        
        isRecording = true
        self.isFirstFrameOfAngle = true
        self.isFirstFrameOfForce = true
        print("start recording data")
    }
    
   func stopRecordingForceData() {
        isRecording = false
       print("stop recording data")
    }
    
    private func attemptReconnect() {
        print("Attempting to reconnect...)")
        
        // 延迟重连
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.reConnectToServer() // 重连到服务器
        }
    }
    
}

extension WebSocketManager {
    private func handleLeftFingerMessage(string: String) {
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
                self.totalLeftForce = sqrt(xForce * xForce + yForce * yForce + zForce * zForce)
                //                print("\(totalForce)")
               
                if self.isRecording {
                    print("isrecording: \(isRecording)")
                    self.recordedForceData.append(forceData)
                   
                }
                //                throttleUpdate() // 调用节流函数
            }
        }
    }
    
    private func handleRightFingerMessage(string: String) {
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
                
                let xForce = forceData.forceData?[0] ?? 0
                let yForce = forceData.forceData?[1] ?? 0
                let zForce = forceData.forceData?[2] ?? 0
                self.totalRightForce = sqrt(xForce * xForce + yForce * yForce + zForce * zForce)
                //                print("\(totalForce)")
               
                if self.isRecording {
                    print("isrecording: \(isRecording)")
                    self.recordedRightFingerForceData.append(forceData)
                }
                //                throttleUpdate() // 调用节流函数
            }
        }
    }
    
    private func handleAngleMessage(string: String) {
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
                self.angleDataforShow = angleData.angle
                
                if self.isRecording {
                    self.recordedAngleData.append(angleData)
//                    print("angle data: \(angleData)")
                }
                //                throttleUpdate() // 调用节流函数
            }
        }
    }
}

extension WebSocketManager {
    private func generateSampleData() {
        let sampleForces = [
            ForceData(timeStamp: 0, forceData: [1.0, 2.0, 3.0, 4.0, 5.0, 6.0]),
            ForceData(timeStamp: 1, forceData: [2.0, 3.0, 4.0, 5.0, 6.0, 7.0]),
            ForceData(timeStamp: 2, forceData: [3.0, 4.0, 5.0, 6.0, 7.0, 8.0])
        ]
        self.recordedForceData = sampleForces
    }
}

extension WebSocketManager {
    
    //    private func throttleUpdate() {
    //        throttleTimer?.invalidate() // 取消之前的定时器
    //        throttleTimer = Timer.scheduledTimer(withTimeInterval: throttleInterval, repeats: false) { [weak self] _ in
    //            DispatchQueue.main.async {
    //                self?.updateUI()
    //            }
    //        }
    //    }
    
    //    private func updateUI() {
    ////        self.forceDataforShow = self.recordedForceData.last
    //        self.totalForce = self.totalForce
    //        self.angleDataforShow = self.angleDataforShow
    //    }
    
    
}
