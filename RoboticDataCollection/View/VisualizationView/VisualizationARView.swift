//
//  RemoteARView.swift
//  MagiClaw
//
//  Created by 吴天禹 on 2024/9/10.
//
#if os(iOS)
import SwiftUI
import RealityKit
import ARKit
import simd
import Accelerate
import AVFoundation
import SceneKit
import CoreImage
import UIKit

struct VisualizationARView: View {
    @State private var cameraTransform = simd_float4x4()
    @Environment(\.verticalSizeClass) var verticalSizeClass
    
    @Binding var minDepth: Float
    @Binding var maxDepth: Float
    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                // 只保留并排显示视图
                SideBySideARView(
                    depthInfoUpdateCallback: { min, max in
                        self.minDepth = min
                        self.maxDepth = max
                    })
                
                // 显示深度信息
                GeometryReader { proxy in
                    VStack {
                        HStack {
                            Spacer()
                            
                            DepthInfoView(minDepth: minDepth, maxDepth: maxDepth)
                                .frame(width: proxy.size.width * 0.45)
                                .padding()
                                .transition(.opacity)
                        }
                        Spacer()
                    }
                }
                
            }
        }
        .checkPermissions([.camera, .microphone, .localNetwork])
    }
}

// 并排视图 - 优化版本
struct SideBySideARView: UIViewRepresentable {
    var depthInfoUpdateCallback: ((Float, Float) -> Void)?
    
    func makeUIView(context: Context) -> UIView {
        let containerView = UIView(frame: .zero)
        
        // 创建RGB和深度视图
        let rgbImageView = UIImageView()
        rgbImageView.contentMode = .scaleAspectFit
        rgbImageView.tag = 101
        containerView.addSubview(rgbImageView)
        
        let depthImageView = UIImageView()
        depthImageView.contentMode = .scaleAspectFit
        depthImageView.tag = 100
        containerView.addSubview(depthImageView)
        
        // 分隔线
        let separator = UIView()
        separator.backgroundColor = UIColor.white
        separator.tag = 102
        containerView.addSubview(separator)
        
        // 创建AR会话
        let session = ARSession()
        session.delegate = context.coordinator
        
        // 配置AR会话
        let config = configureARSession()
        session.run(config, options: [.resetTracking, .removeExistingAnchors])
        
        // 存储会话和容器视图引用
        context.coordinator.session = session
        context.coordinator.containerView = containerView
        
        return containerView
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        context.coordinator.depthInfoUpdateCallback = depthInfoUpdateCallback
        context.coordinator.updateLayout()
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    // 配置AR会话
    private func configureARSession() -> ARWorldTrackingConfiguration {
        let config = ARWorldTrackingConfiguration()
        
        // 设置用户选择的帧率
        let desiredFrameRate = SettingModel.shared.frameRate
        if let videoFormat = ARWorldTrackingConfiguration.supportedVideoFormats.first(where: { $0.framesPerSecond == desiredFrameRate }) {
            config.videoFormat = videoFormat
        }
        
        // 设置是否使用smooth depth
        if SettingModel.shared.smoothDepth {
            if ARWorldTrackingConfiguration.supportsFrameSemantics(.smoothedSceneDepth) {
                config.frameSemantics.insert(.smoothedSceneDepth)
            }
        } else {
            if ARWorldTrackingConfiguration.supportsFrameSemantics(.sceneDepth) {
                config.frameSemantics.insert(.sceneDepth)
            }
        }
        
        return config
    }
    
    // 协调器
    class Coordinator: NSObject, ARSessionDelegate {
        var parent: SideBySideARView
        var session: ARSession?
        var containerView: UIView?
        var depthInfoUpdateCallback: ((Float, Float) -> Void)?
        
        init(_ parent: SideBySideARView) {
            self.parent = parent
            super.init()
        }
        
        func session(_ session: ARSession, didUpdate frame: ARFrame) {
            // 创建一个弱引用以避免循环引用
            weak var weakSelf = self
            
            // 使用主线程处理 UI 更新，但在后台线程处理图像处理
            DispatchQueue.global(qos: .userInteractive).async {
                // 处理 RGB 图像
                let ciImage = CIImage(cvPixelBuffer: frame.capturedImage)
                let context = CIContext()
                var rgbImage: UIImage? = nil
                
                if let cgImage = context.createCGImage(ciImage, from: ciImage.extent) {
                    // 在横屏模式下，不需要旋转图像，使用原始方向
                    rgbImage = UIImage(cgImage: cgImage, scale: 1.0, orientation: .up)
                }
                
                // 处理深度图像
                var coloredDepthImage: UIImage? = nil
                var minDepth: Float = 0.0
                var maxDepth: Float = 5.0
                
                if let depthMap = SettingModel.shared.smoothDepth ? frame.smoothedSceneDepth?.depthMap : frame.sceneDepth?.depthMap {
                    let result = createColoredDepthImageOptimized(from: depthMap)
                    coloredDepthImage = result.0
                    minDepth = result.1
                    maxDepth = result.2
                }
                
                // 在主线程更新 UI
                DispatchQueue.main.async {
                    guard let strongSelf = weakSelf else { return }
                    
                    // 更新 RGB 图像
                    if let rgbImage = rgbImage, let rgbImageView = strongSelf.containerView?.viewWithTag(101) as? UIImageView {
                        rgbImageView.image = rgbImage
                    }
                    
                    // 更新深度图像
                    if let coloredDepthImage = coloredDepthImage, let depthView = strongSelf.containerView?.viewWithTag(100) as? UIImageView {
                        depthView.image = coloredDepthImage
                        strongSelf.depthInfoUpdateCallback?(minDepth, maxDepth)
                    }
                    
                    // 确保布局正确
                    strongSelf.updateLayout()
                }
            }
        }
        
        // 更新布局
        func updateLayout() {
            guard let containerView = containerView,
                  let rgbImageView = containerView.viewWithTag(101) as? UIImageView,
                  let depthView = containerView.viewWithTag(100) as? UIImageView,
                  let separator = containerView.viewWithTag(102) else {
                return
            }
            
            // 在横屏模式下，左RGB右深度
            let halfWidth = containerView.bounds.width / 2
            
            // 设置内容模式以保持4:3的宽高比
            rgbImageView.contentMode = .scaleAspectFit
            depthView.contentMode = .scaleAspectFit
            
            // 计算4:3宽高比的视图高度
            let viewHeight = containerView.bounds.height
            let aspectRatio: CGFloat = 4.0 / 3.0
            let idealWidth = viewHeight * aspectRatio
            
            // 如果理想宽度小于可用宽度，居中显示
            let rgbX: CGFloat = idealWidth < halfWidth ? (halfWidth - idealWidth) / 2 : 0
            let depthX: CGFloat = halfWidth + (idealWidth < halfWidth ? (halfWidth - idealWidth) / 2 : 0)
            
            // 设置视图框架
            rgbImageView.frame = CGRect(x: rgbX, y: 0, 
                                       width: min(idealWidth, halfWidth), 
                                       height: viewHeight)
            
            depthView.frame = CGRect(x: depthX, y: 0, 
                                    width: min(idealWidth, halfWidth), 
                                    height: viewHeight)
            
            // 分隔线始终在中间
            separator.frame = CGRect(x: halfWidth - 1, y: 0, 
                                    width: 2, 
                                    height: viewHeight)
        }
    }
}

// 使用vDSP优化的深度图像渲染函数
func createColoredDepthImageOptimized(from depthMap: CVPixelBuffer) -> (UIImage?, Float, Float) {
    CVPixelBufferLockBaseAddress(depthMap, .readOnly)
    defer { CVPixelBufferUnlockBaseAddress(depthMap, .readOnly) }
    
    let width = CVPixelBufferGetWidth(depthMap)
    let height = CVPixelBufferGetHeight(depthMap)
    let totalPixels = width * height
    
    // 创建RGB图像缓冲区
    var rgbPixelBuffer: CVPixelBuffer?
    let attrs = [
        kCVPixelBufferCGImageCompatibilityKey: kCFBooleanTrue,
        kCVPixelBufferCGBitmapContextCompatibilityKey: kCFBooleanTrue
    ] as CFDictionary
    
    CVPixelBufferCreate(kCFAllocatorDefault,
                       width,
                       height,
                       kCVPixelFormatType_32BGRA,
                       attrs,
                       &rgbPixelBuffer)
    
    guard let rgbPixelBuffer = rgbPixelBuffer else { return (nil, 0, 0) }
    
    CVPixelBufferLockBaseAddress(rgbPixelBuffer, [])
    defer { CVPixelBufferUnlockBaseAddress(rgbPixelBuffer, []) }
    
    let rgbBaseAddress = CVPixelBufferGetBaseAddress(rgbPixelBuffer)!
    let rgbBytesPerRow = CVPixelBufferGetBytesPerRow(rgbPixelBuffer)
    let rgbBuffer = rgbBaseAddress.assumingMemoryBound(to: UInt8.self)
    
    // 获取深度数据
    let depthBaseAddress = CVPixelBufferGetBaseAddress(depthMap)!
    let depthValues = depthBaseAddress.assumingMemoryBound(to: Float.self)
    
    // 使用更高效的方法查找最小和最大深度值
    var minDepth: Float = 10.0
    var maxDepth: Float = 0.0
    var validDepthCount = 0
    
    // 使用 vDSP 查找有效深度值的范围
    for i in 0..<totalPixels {
        let depth = depthValues[i]
        if depth > 0.0 && depth < 10.0 {
            minDepth = min(minDepth, depth)
            maxDepth = max(maxDepth, depth)
            validDepthCount += 1
        }
    }
    
    // 如果没有有效深度值，使用默认范围
    if validDepthCount == 0 || minDepth >= maxDepth {
        minDepth = 0.0
        maxDepth = 5.0
    }
    
    // 归一化深度值的范围
    let range = maxDepth - minDepth
    let invRange = 1.0 / range
    
    // 预计算彩虹色映射表以提高性能
    let colorMapSize = 256
    var colorMap = [(UInt8, UInt8, UInt8)](repeating: (0, 0, 0), count: colorMapSize)
    
    for i in 0..<colorMapSize {
        let normalizedDepth = Float(i) / Float(colorMapSize - 1)
        colorMap[i] = depthToRainbowOptimized(normalizedDepth)
    }
    
    // 使用并行处理提高性能
    DispatchQueue.concurrentPerform(iterations: height) { y in
        for x in 0..<width {
            let index = y * width + x
            let depthValue = depthValues[index]
            let pixelOffset = y * rgbBytesPerRow + x * 4
            
            if depthValue > 0 && depthValue < 10 { // 有效深度值
                // 归一化深度值到0-1范围
                let normalizedDepth = (depthValue - minDepth) * invRange
                // 将归一化值映射到颜色表索引
                let colorIndex = min(colorMapSize - 1, Int(normalizedDepth * Float(colorMapSize - 1)))
                let (r, g, b) = colorMap[colorIndex]
                
                // BGRA格式
                rgbBuffer[pixelOffset] = b     // B
                rgbBuffer[pixelOffset + 1] = g // G
                rgbBuffer[pixelOffset + 2] = r // R
                rgbBuffer[pixelOffset + 3] = 255 // A (完全不透明)
            } else {
                // 无效深度值显示为黑色
                rgbBuffer[pixelOffset] = 0     // B
                rgbBuffer[pixelOffset + 1] = 0 // G
                rgbBuffer[pixelOffset + 2] = 0 // R
                rgbBuffer[pixelOffset + 3] = 255 // A
            }
        }
    }
    
    // 创建CGImage
    let colorSpace = CGColorSpaceCreateDeviceRGB()
    let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedFirst.rawValue | CGBitmapInfo.byteOrder32Little.rawValue)
    
    guard let context = CGContext(data: rgbBaseAddress,
                                 width: width,
                                 height: height,
                                 bitsPerComponent: 8,
                                 bytesPerRow: rgbBytesPerRow,
                                 space: colorSpace,
                                 bitmapInfo: bitmapInfo.rawValue) else {
        return (nil, minDepth, maxDepth)
    }
    
    guard let cgImage = context.makeImage() else { return (nil, minDepth, maxDepth) }
    
    // 创建正确方向的UIImage - 不旋转，保持原始方向
    let uiImage = UIImage(cgImage: cgImage, scale: 1.0, orientation: .up)
    return (uiImage, minDepth, maxDepth)
}

// 优化的彩虹色映射函数
func depthToRainbowOptimized(_ depth: Float) -> (UInt8, UInt8, UInt8) {
    // 使用HSV颜色空间，将深度映射到色相(0-240度)
    let hue = depth * 240.0 // 直接映射，近处(0)为红色，远处(1)为蓝色
    
    // 预计算色相区间
    let hDiv60 = hue / 60.0
    let region = Int(hDiv60)
    let frac = hDiv60 - Float(region)
    
    let c: Float = 1.0 // 色度最大
    let x: Float = c * (1.0 - abs(fmod(hDiv60, 2.0) - 1.0))
    
    var r, g, b: Float
    
    switch region {
    case 0:
        r = c; g = x; b = 0.0
    case 1:
        r = x; g = c; b = 0.0
    case 2:
        r = 0.0; g = c; b = x
    case 3:
        r = 0.0; g = x; b = c
    default:
        r = 0.0; g = 0.0; b = c
    }
    
    // 转换为0-255范围的UInt8
    return (
        UInt8(min(255, r * 255)),
        UInt8(min(255, g * 255)),
        UInt8(min(255, b * 255))
    )
}


#endif
