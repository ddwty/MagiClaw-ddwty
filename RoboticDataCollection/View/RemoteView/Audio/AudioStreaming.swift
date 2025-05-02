//
//  AudioStreaming.swift
//  MagiClaw
//
//  Created by 吴天禹 on 2024/9/11.
//
#if os(iOS)
import AVFoundation

class AudioStreamManager {
    private var audioEngine: AVAudioEngine!
    private var inputNode: AVAudioInputNode!
    private var format: AVAudioFormat!
    private var websocketServerManager: WebSocketServerManager?

    init(websocketServerManager: WebSocketServerManager?) {
        self.websocketServerManager = websocketServerManager
        setupAudioEngine()
    }

    private func setupAudioEngine() {
        audioEngine = AVAudioEngine()
        inputNode = audioEngine.inputNode

        // 自定义采样率和通道数
        let sampleRate: Double = 48000.0  // 例如 48000Hz
        let channelCount: AVAudioChannelCount = 1

        // 设置音频格式为标准 PCM
        format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: channelCount)
    }

    func startStreaming() {
        guard let websocketServerManager = websocketServerManager else {
            print("WebSocket server manager not available")
            return
        }
        
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: format) { (buffer, time) in
            let audioData = self.convertAudioBufferToData(buffer: buffer)
            
            // Send audio data to all connected clients
            websocketServerManager.connectionsByID.values.forEach { connection in
                connection.send(data: audioData)
            }
        }

        do {
            try audioEngine.start()
            print("Audio streaming started")
        } catch {
            print("Error starting audio engine: \(error.localizedDescription)")
        }
    }

    func stopStreaming() {
        inputNode.removeTap(onBus: 0)
        audioEngine.stop()
        print("Audio streaming stopped")
    }

    private func convertAudioBufferToData(buffer: AVAudioPCMBuffer) -> Data {
        let audioBuffer = buffer.audioBufferList.pointee.mBuffers
        let data = Data(bytes: audioBuffer.mData!, count: Int(audioBuffer.mDataByteSize))
        return data
    }
}


//import AVFoundation
//
//class AudioStreamManager: NSObject, AVCaptureAudioDataOutputSampleBufferDelegate {
//    private var captureSession: AVCaptureSession!
//    private var audioOutput: AVCaptureAudioDataOutput!
//    private var websocketServerManager: WebSocketServerManager?
//
//    init(websocketServerManager: WebSocketServerManager?) {
//        self.websocketServerManager = websocketServerManager
//        super.init()
//        setupAudioCapture()
//    }
//
//    private func setupAudioCapture() {
//        captureSession = AVCaptureSession()
//        
//        // 获取麦克风设备
//        guard let audioDevice = AVCaptureDevice.default(for: .audio) else {
//            print("无法获取音频设备")
//            return
//        }
//        
//        do {
//            // 创建音频输入
//            let audioInput = try AVCaptureDeviceInput(device: audioDevice)
//            if captureSession.canAddInput(audioInput) {
//                captureSession.addInput(audioInput)
//            }
//            
//            // 创建音频输出
//            audioOutput = AVCaptureAudioDataOutput()
//            if captureSession.canAddOutput(audioOutput) {
//                captureSession.addOutput(audioOutput)
//            }
//            
//            // 设置音频输出的回调代理
//            let queue = DispatchQueue(label: "audioQueue")
//            audioOutput.setSampleBufferDelegate(self, queue: queue)
//            
//        } catch {
//            print("设置音频捕获时出错: \(error.localizedDescription)")
//        }
//    }
//
//    func startStreaming() {
//        guard let websocketServerManager = websocketServerManager else {
//            print("WebSocket server manager not available")
//            return
//        }
//
//        // 启动音频捕获会话
//        captureSession.startRunning()
//        print("Audio streaming started")
//    }
//
//    func stopStreaming() {
//        // 停止音频捕获会话
//        captureSession.stopRunning()
//        print("Audio streaming stopped")
//    }
//
//    // 处理捕获的音频数据
//    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
//        guard let websocketServerManager = websocketServerManager else {
//            return
//        }
//        
//        // 从 sampleBuffer 中获取音频数据
//        if let blockBuffer = CMSampleBufferGetDataBuffer(sampleBuffer) {
//            var length: Int = 0
//            var dataPointer: UnsafeMutablePointer<Int8>?
//            
//            if CMBlockBufferGetDataPointer(blockBuffer, atOffset: 0, lengthAtOffsetOut: nil, totalLengthOut: &length, dataPointerOut: &dataPointer) == noErr {
//                let data = Data(bytes: dataPointer!, count: length)
//                
//                // 通过 WebSocket 发送音频数据给所有连接的客户端
//                websocketServerManager.connectionsByID.values.forEach { connection in
//                    connection.send(data: data)
//                }
//            }
//        }
//    }
//}
//
#endif
