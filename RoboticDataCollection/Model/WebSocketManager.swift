//
//  WebSocketManager.swift
//  talkWithRpi
//
//  Created by Tianyu on 7/17/24.
//

import Foundation
import Starscream
import UIKit

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
    
   
    @Published var hostName: String = "raspberrypi.local"
    @Published var receivedMessage: String = ""
    
    private var angelSocket: WebSocket?
    private var leftFingerSocket: WebSocket?
    private var pingTimer: Timer?
    private var shouldPing: Bool = true
    var isRecording = false
    
    
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
    
    // MARK: - And both left finger and angel
    private func updateConnectionStatus() {
        self.isConnected = isLeftFingerConnected && isAngelConnected
    }
    
    private init() {
//        connectToServer()
        self.recordedForceData.reserveCapacity(10000)
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
        var leftFingerRequest = URLRequest(url: URL(string: "ws://\(self.hostName):8080/left_finger/force")!)
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
                        
                    case .text(let string):
                        if self.isRecording {
                            self.handleLeftFingerMessage(string: string)
//                            print("Receive text from left finger message, is recording: \(self.isRecording)")
                        }
//                        print("\(string)")
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
                    case .peerClosed:
                        break
                    case .error(let error):
                        self.isLeftFingerConnected = false
                        print("WebSocket encountered an error: \(error?.localizedDescription ?? "")")
                    }
                }
    }
    
    func connectAngel() {
        var angelRequest = URLRequest(url: URL(string: "ws://\(self.hostName):8080/angle")!)
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
                        
                    case .text(let string):
                        if self.isRecording {
//                            self.handleLeftFingerMessage(string: string)
                        }
//                        print("\(string)")
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
                    case .peerClosed:
                        break
                    case .error(let error):
                        self.isLeftFingerConnected = false
                        print("WebSocket encountered an error: \(error?.localizedDescription ?? "")")
                    }
                }
        
    }
    
    func startRecordingForceData() {
        recordedForceData.removeAll()
        isRecording = true
        connectLeftFinger()
    }
    
    func stopRecordingForceData() {
        isRecording = false
    }
}

extension WebSocketManager {
    func handleLeftFingerMessage(string: String) {
            if let data = string.data(using: .utf8) {
                if let fingerForce = try? JSONDecoder().decode(FingerForce.self, from: data) {
                    let forceData = ForceData(
                        timeStamp: "\(fingerForce.time_stamp.secs).\(fingerForce.time_stamp.nanos)",
                        forceData: fingerForce.force?.value)
                    DispatchQueue.main.async {
                        if self.isRecording {
                            self.recordedForceData.append(forceData)
                        }
                    }
                }
            }
        
    }
    
    func handleAngleMessage(string: String) {
        if let data = string.data(using: .utf8) {
            if let fingerAngle = try? JSONDecoder().decode(FingerAngle.self, from: data) {
                let angleData = AngleData(
                    timeStamp: "\(fingerAngle.time_stamp.secs).\(fingerAngle.time_stamp.nanos)", angle: fingerAngle.data)
                DispatchQueue.main.async {
                    if self.isRecording {
                        self.recordedAngleData.append(angleData)
                    }
                }
            }
        }
    }
    
}
