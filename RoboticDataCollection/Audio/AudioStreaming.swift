//
//  AudioStreaming.swift
//  MagiClaw
//
//  Created by 吴天禹 on 2024/9/11.
//

import Foundation
import AVFoundation
import Network

class AudioStreaming: NSObject, ObservableObject {
    // 单例模式
    static let shared = AudioStreaming()
    
    // WebSocket 连接
    var webSocketConnection: NWConnection?
    
    // 捕获会话
    private var captureSession: AVCaptureSession!
    private var audioDataOutput: AVCaptureAudioDataOutput!
    private let audioQueue = DispatchQueue(label: "audioQueue")
    
    // 录音状态
    @Published var isStreaming = false
    
    private override init() {
        super.init()
        setupAudioSession()
        setupWebSocket()
    }
    
    // 配置捕获会话
    private func setupAudioSession() {
        captureSession = AVCaptureSession()
        
        guard let audioDevice = AVCaptureDevice.default(for: .audio) else {
            print("Error: No audio device available")
            return
        }
        
        do {
            let audioInput = try AVCaptureDeviceInput(device: audioDevice)
            if captureSession.canAddInput(audioInput) {
                captureSession.addInput(audioInput)
            }
        } catch {
            print("Error: Cannot create audio input: \(error)")
        }
        
        audioDataOutput = AVCaptureAudioDataOutput()
        audioDataOutput.setSampleBufferDelegate(self, queue: audioQueue)
        
        if captureSession.canAddOutput(audioDataOutput) {
            captureSession.addOutput(audioDataOutput)
        }
    }
    
    // 配置 WebSocket 连接
    private func setupWebSocket() {
        let parameters = NWParameters.tcp
        let wsOptions = NWProtocolWebSocket.Options()
        wsOptions.autoReplyPing = true
        parameters.defaultProtocolStack.applicationProtocols.insert(wsOptions, at: 0)
        
        webSocketConnection = NWConnection(host: "yourserver.com", port: 8080, using: parameters)
        webSocketConnection?.stateUpdateHandler = { newState in
            switch newState {
            case .ready:
                print("WebSocket is ready")
            case .failed(let error):
                print("WebSocket connection failed: \(error)")
            default:
                break
            }
        }
        
        webSocketConnection?.start(queue: .main)
    }
    
    // 启动音频流
    func startStreaming() {
        guard !isStreaming else { return }
        
        captureSession.startRunning()
        isStreaming = true
        print("Started streaming audio")
    }
    
    // 停止音频流
    func stopStreaming() {
        guard isStreaming else { return }
        
        captureSession.stopRunning()
        isStreaming = false
        print("Stopped streaming audio")
    }
    
    // 发送音频数据到 WebSocket
    private func sendDataViaWebSocket(data: Data) {
        guard let webSocketConnection = webSocketConnection else { return }
        
        let metadata = NWProtocolWebSocket.Metadata(opcode: .binary)
        let context = NWConnection.ContentContext(identifier: "audioContext", metadata: [metadata])
        
        webSocketConnection.send(content: data, contentContext: context, isComplete: true, completion: .contentProcessed({ error in
            if let error = error {
                print("Failed to send audio data: \(error)")
            } else {
                print("Audio data sent")
            }
        }))
    }
}

extension AudioStreaming: AVCaptureAudioDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let blockBuffer = CMSampleBufferGetDataBuffer(sampleBuffer) else { return }
        
        let length = CMBlockBufferGetDataLength(blockBuffer)
        var data = Data(count: length)
        
        data.withUnsafeMutableBytes { ptr in
            CMBlockBufferCopyDataBytes(blockBuffer, atOffset: 0, dataLength: length, destination: ptr.baseAddress!)
        }
        
        // 发送音频数据到 WebSocket
        sendDataViaWebSocket(data: data)
    }
}

