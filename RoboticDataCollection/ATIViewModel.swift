//
//  ATIViewModel.swift
//  MagiClaw
//
//  Created by Tianyu on 4/20/25.
//

import Foundation
import SwiftUI
import Combine

@Observable
class ATIViewModel {
    // 发布的状态
    var ftData: [Int] = [0, 0, 0, 0, 0, 0]
    var ipAddress: String = "192.168.1.1"
    var errorMessage: String = ""
    var frequency: Double = 60
    var isConnected: Bool = false
    var isStreaming: Bool = false
    var showCameraView: Bool = true
    var ftDataHistory: [[FTDataPoint]] = Array(repeating: [], count: 6)
    
    // 私有状态
    private var uiUpdateTimer: Timer? = nil
    private var dataBuffer: [Int] = [0, 0, 0, 0, 0, 0]
    private let dataBufferLock = NSLock()
    private let maxDataPoints = 200
    // 颜色配置
    let forceColors: [Color] = [.red, .green, .blue]
    let torqueColors: [Color] = [.red, .green, .blue]
    
    // 析构函数
    deinit {
        stopStreaming()
        disconnectSensor()
    }
    
    // MARK: - 公共方法
    
    /// 连接传感器
    func connectSensor() {
        let cString = ipAddress.cString(using: .utf8)
        
        let result = connectFT_sensor(cString)
        
        if result == 0 {
            isConnected = true
            startStreaming()
            
            errorMessage = ""
            // 清空历史数据
            resetChartData()
        } else {
            errorMessage = "连接传感器失败，错误代码: \(result)"
        }
    }
    
    /// 断开传感器连接
    func disconnectSensor() {
        stopStreaming()
        let result = disconnectFT_sensor()
        isConnected = false
        
        errorMessage = ""
        resetChartData()
    }
    
    /// 开始数据流
    func startStreaming() {
        guard !ipAddress.isEmpty else { return }
        
        isStreaming = true
        
        // 连接传感器
        let cString = ipAddress.cString(using: .utf8)
        let result = connectFT_sensor(cString)
        
        if result != 0 {
            errorMessage = "Connect failed: \(result)"
            isStreaming = false
            return
        }
        resetChartData()
        
        // 设置60Hz的图表更新 (1/60 ≈ 0.01667秒)
        setupUIUpdateTimer()
        
        // 使用后台队列进行高频率采样
        let interval = 1.0 / Double(frequency)
        
        // 创建与UI更新相同QoS的队列，避免优先级反转
        let queue = DispatchQueue(label: "com.app.ftsensor", qos: .userInitiated)
        
        // 创建数据读取队列，使用较低优先级
        let dataQueue = DispatchQueue(label: "com.app.ftsensor.data", qos: .utility)
        
        queue.async { [weak self] in
            guard let self = self else { return }
            
            var i = 0
            var lastTime = DispatchTime.now()
            
            while self.isStreaming {
                // 在单独的队列中读取数据，不阻塞UI更新队列
                var data = [Int32](repeating: 0, count: 6)
                var result: Int32 = 0
                
                // 使用同步调用确保数据读取完成后再继续
                dataQueue.sync {
                    result = readFT_data_continuous(&data)
                }
                
                if result == 0 {
                    // 更新数据缓冲区，但不立即更新UI
                    self.dataBufferLock.lock()
                    for j in 0..<6 {
                        self.dataBuffer[j] = Int(data[j])
                    }
                    self.dataBufferLock.unlock()
                } else {
                    DispatchQueue.main.async {
                        self.errorMessage = "Read ft data failed: \(result)"
                        self.stopStreaming()
                    }
                    break
                }
                
//                i += 1
//                if i % 100 == 0 {
//                    let now = DispatchTime.now()
//                    let elapsed = Double(now.uptimeNanoseconds - lastTime.uptimeNanoseconds) / 1_000_000_000
//                    let actualFreq = 100.0 / elapsed
////                    print("采样100次用时: \(elapsed)秒, 实际频率: \(actualFreq)Hz")
//                    lastTime = now
//                }
                
                // 精确控制循环间隔
                usleep(UInt32(interval * 1_000_000))
            }
        }
    }
    
    /// 停止数据流
    func stopStreaming() {
        isStreaming = false
        uiUpdateTimer?.invalidate()
        uiUpdateTimer = nil
        disconnectFT_sensor()
    }
    
    /// 重置传感器数据
    func resetSensorData() {
        let cString = ipAddress.cString(using: .utf8)
        resetFT_sensor(cString)
    }
    
    /// 获取轴名称
    func getAxisName(_ index: Int) -> String {
        let axes = ["Fx", "Fy", "Fz", "Tx", "Ty", "Tz"]
        return axes[index]
    }
    
    // MARK: - 私有方法
    
    /// 设置UI更新定时器
    private func setupUIUpdateTimer() {
        // 停止现有的定时器
        uiUpdateTimer?.invalidate()
        
        // 创建新的定时器，以60Hz更新图表 (1/60 ≈ 0.01667秒)
        uiUpdateTimer = Timer.scheduledTimer(withTimeInterval: 1.0/60.0, repeats: true) { [weak self] _ in
            self?.updateUIFromBuffer()
        }
        
        // 确保定时器在滚动等操作期间也能触发
        if let timer = uiUpdateTimer {
            RunLoop.current.add(timer, forMode: .common)
        }
    }
    
    /// 从缓冲区更新UI
    private func updateUIFromBuffer() {
        // 从缓冲区更新UI数据
        dataBufferLock.lock()
        for i in 0..<6 {
            ftData[i] = dataBuffer[i]
        }
        dataBufferLock.unlock()
        
        // 更新图表
        updateChartData()
    }
    
    /// 读取连续传感器数据
    private func readContinuousSensorData() {
        var data = [Int32](repeating: 0, count: 6)
        
        let result = readFT_data_continuous(&data)
        
        if result == 0 {
            for i in 0..<6 {
                ftData[i] = Int(data[i])
            }
            errorMessage = ""
        } else {
            errorMessage = "读取传感器失败，错误代码: \(result)"
            stopStreaming()
        }
    }
    
    /// 读取传感器数据
    private func readSensorData() {
        var data = [Int32](repeating: 0, count: 6)
        
        let cString = ipAddress.cString(using: .utf8)
        
        let result = readFT_data(cString, &data)
        
        if result == 0 {
            for i in 0..<6 {
                ftData[i] = Int(data[i])
            }
            errorMessage = ""
        } else {
            errorMessage = "读取传感器失败，错误代码: \(result)"
        }
    }
    
    /// 更新图表数据
    private func updateChartData() {
        let now = Date()
        
        // 更新力数据
        for i in 0..<6 {
            if i < 3 {
                // 力数据
                let forceValue = Double(ftData[i]) / 1000000 // 转换为牛顿
                let newPoint = FTDataPoint(timestamp: now, value: forceValue, type: getAxisName(i))
                ftDataHistory[i].append(newPoint)
            } else {
                // 扭矩数据
                let torqueValue = Double(ftData[i]) / 1000 // 转换为牛米
                let newPoint = FTDataPoint(timestamp: now, value: torqueValue, type: getAxisName(i))
                ftDataHistory[i].append(newPoint)
            }
            // 限制数据点数量
            if ftDataHistory[i].count > maxDataPoints {
                ftDataHistory[i].removeFirst()
            }
        }
    }
    
    /// 重置图表数据
    private func resetChartData() {
        ftDataHistory = Array(repeating: [], count: 6)
    }
} 
