//
//  RemoteARView.swift
//  MagiClaw
//
//  Created by 吴天禹 on 2024/9/10.
//



import SwiftUI
import RealityKit
import ARKit
import simd
import Accelerate
import AVFoundation


#Preview {
    RemoteARView()
}




struct RemoteARView: View {
    @State private var cameraTransform = simd_float4x4()
    @Environment(\.verticalSizeClass) var verticalSizeClass
    var body: some View {
        GeometryReader { geo in
            RemoteARViewContainer(cameraTransform: $cameraTransform)
            
        }
        //            .checkPermissions([.camera,.microphone, .localNetwork])
        
    }
}



//#if DEBUG
//#Preview {
//    MyARView()
//}
//#endif


struct RemoteARViewContainer: UIViewControllerRepresentable {
    //    var frameSize: CGSize
    @Binding var cameraTransform: simd_float4x4
    @EnvironmentObject var websocketServer: WebSocketServerManager
    
    
    func makeUIViewController(context: Context) -> RemoteARViewController {
        let arViewController = RemoteARViewController(websocketServer: websocketServer)
        
        return arViewController
    }
    
    func updateUIViewController(_ uiViewController: RemoteARViewController, context: Context) {
        
        //        uiViewController.updateARViewFrame(frameSize: frameSize)
    }
    
    class Coordinator: NSObject {
        var parent: RemoteARViewContainer
        
        init(parent: RemoteARViewContainer) {
            self.parent = parent
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }
}





class RemoteARViewController: UIViewController, ARSessionDelegate {
    var arView: ARView!
    //    var frameSize: CGSize
    //    var tcpServerManager: TCPServerManager
    var markerManager: MarkerManager!
    var websocketServer: WebSocketServerManager
    var settingModel = SettingModel.shared
    
    var boxEntity: ModelEntity!
    
    var distance = 0.0
    
    
    
    private var lastUpdateTime: CFTimeInterval = 0
    private var displayLink: CADisplayLink?
    private var frameRateBinding: Binding<Double>?
    
    init(websocketServer: WebSocketServerManager) {
        self.websocketServer = websocketServer
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        arView = ARView(frame: self.view.bounds) // 将 frame 设置为 view 的 bounds
        arView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        arView.addCoaching()
        self.view.addSubview(arView)
        arView.session.delegate = self
        
        let mesh = MeshResource.generateBox(size: 0.1, cornerRadius: 0.005)
        let material = SimpleMaterial(color: .gray, roughness: 0.15, isMetallic: true)
        boxEntity = ModelEntity(mesh: mesh, materials: [material])
        
        let anchor = AnchorEntity()
        anchor.addChild(boxEntity)
        arView.scene.addAnchor(anchor)
        
        
        // 初始化 MarkerManager
        markerManager = MarkerManager(arView: arView)
    }
    
    
    //    func updateARViewFrame(frameSize: CGSize) {
    //           // Update the frame size when passed from SwiftUI
    //           self.frameSize = frameSize
    //           arView.frame = CGRect(origin: .zero, size: frameSize)
    //    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        let config = ARWorldTrackingConfiguration()
        //        config.isAutoFocusEnabled = true
        
        // 设置用户选择的帧率
        let desiredFrameRate = SettingModel.shared.frameRate
        if let videoFormat = ARWorldTrackingConfiguration.supportedVideoFormats.first(where: { $0.framesPerSecond == desiredFrameRate }) {
            config.videoFormat = videoFormat
            print("Using video format with \(desiredFrameRate) FPS")
        } else {
            print("No video format with \(desiredFrameRate) FPS found")
        }
        
        // 设置是否使用smooth depth
        if SettingModel.shared.smoothDepth {
            if ARWorldTrackingConfiguration.supportsFrameSemantics(.smoothedSceneDepth) {
                config.frameSemantics.insert(.smoothedSceneDepth)
                print("Using smoothed scene depth")
            }
        } else {
            if ARWorldTrackingConfiguration.supportsFrameSemantics(.sceneDepth) {
                config.frameSemantics = .sceneDepth
                print("Using scene depth without smoothing")
            }
        }
        
        if settingModel.showWorldOrigin {
            arView.debugOptions = [.showWorldOrigin]
        }
        arView.session.run(config, options: [.resetTracking, .removeExistingAnchors])
        //        arView.runARSession()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        arView.session.pause()
    }
    
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        // Update camera transform and other data
        //        let transformString = frame.camera.transform.description
        //        tcpServerManager?.broadcastMessage(transformString)
        //        print("session\(Date.now)")
        
        
        //        if let exifData = frame.exifData as? [String: Any] {
        //                print(exifData)
        //        }
        let cameraTransform = frame.camera.transform
        if RemoteControlManager.shared.enableSendingData {
            //            let cameraTransform = frame.camera.transform
            //            // 将 transform 转换为 JSON 字符串
            //            if let jsonString = cameraTransform.toJSONString() {
            //
            //                DispatchQueue.global(qos: .background).async {
            //                    //                    self.tcpServerManager.broadcastMessage(jsonString)
            //                    //                    self.websocketServer.broadcastMessage(jsonString)
            //                    self.sendToClients(message: jsonString)
            //                }
            //            }
            //
            //            let pixelBuffer = frame.capturedImage
            //            if let imageData = pixelBufferToData(pixelBuffer: pixelBuffer) {
            //                DispatchQueue.global(qos: .background).async {
            //                    self.sendToClients(data: imageData)
            //                }
            //            }
            
            DispatchQueue.global(qos: .background).async {
                let pose = cameraTransform.getPoseMatrix()
                let pixelBuffer = frame.capturedImage
                
                if let combinedData = self.prepareSentData(pixelBuffer: pixelBuffer, pose: pose) {
                    
                    self.sendToClients(data: combinedData)
                }
            }
        }
        
        
        DispatchQueue.global(qos: .userInitiated).async {
            let start = CFAbsoluteTimeGetCurrent()
            self.distance = ArucoCV.calculateDistance(frame.capturedImage, withIntrinsics: frame.camera.intrinsics, andMarkerSize: ArucoProperty.ArucoMarkerSize)
            let end = CFAbsoluteTimeGetCurrent()
            //                    print("Time: \(end - start)")
            
        }
        let theta: Float = .pi / 4  // 45 度
        let transformationMatrix: [[Float]] = [
            [cos(theta), 0, sin(theta), 0.5],
            [0, 1, 0, 0.0],
            [-sin(theta), 0, cos(theta), -1],
            [0, 0, 0, 1]
        ]
        
        // 转换为 simd_float4x4
        let simdMatrix = float4x4(
            [transformationMatrix[0][0], transformationMatrix[1][0], transformationMatrix[2][0], transformationMatrix[3][0]],
            [transformationMatrix[0][1], transformationMatrix[1][1], transformationMatrix[2][1], transformationMatrix[3][1]],
            [transformationMatrix[0][2], transformationMatrix[1][2], transformationMatrix[2][2], transformationMatrix[3][2]],
            [transformationMatrix[0][3], transformationMatrix[1][3], transformationMatrix[2][3], transformationMatrix[3][3]]
        )
        let transformMatrix = matrix_multiply(cameraTransform, simdMatrix)
        // 更新立方体的位置和旋转
        boxEntity.transform.matrix = transformMatrix
        
    }
    
    
    
    
    
    // 定义一个结构体来存储标记数据
//    struct MarkerData {
//        let id: Int
//        let corners: [simd_float3]
//    }
//    
//    // 将 2D 点转换为 3D 坐标
//    func unproject(point: CGPoint, with cameraTransform: simd_float4x4, projectionMatrix: simd_float4x4, viewportSize: CGSize) -> simd_float3? {
//        // 归一化设备坐标
//        let x = (2.0 * Float(point.x) / Float(viewportSize.width)) - 1.0
//        let y = 1.0 - (2.0 * Float(point.y) / Float(viewportSize.height))
//        let z: Float = 1.0 // 远平面
//        
//        let ndc = simd_float4(x, y, z, 1.0)
//        
//        // 计算逆投影矩阵
//        let inverseProjection = simd_inverse(projectionMatrix)
//        let viewNdc = inverseProjection * ndc
//        
//        // 归一化
//        let viewNdcNormalized = simd_float3(viewNdc.x, viewNdc.y, viewNdc.z) / viewNdc.w
//        
//        // 计算逆视图矩阵
//        let inverseView = simd_inverse(cameraTransform)
//        
//        // 计算世界坐标
//        let worldPosition = inverseView * simd_float4(viewNdcNormalized, 1.0)
//        
//        return simd_float3(worldPosition.x, worldPosition.y, worldPosition.z)
//    }
    
    
}

extension RemoteARViewController {
    private func sendToClients(message: String) {
        websocketServer.connectionsByID.values.forEach { connection in
            connection.send(text: message)
        }
    }
    
    private func sendToClients(data: Data) {
        websocketServer.connectionsByID.values.forEach { connection in
            connection.send(data: data)
        }
    }
    
    // 将 CVPixelBuffer 转换为 Data
    //    private func pixelBufferToData(pixelBuffer: CVPixelBuffer) -> Data? {
    //        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
    //        let context = CIContext()
    //
    //        let targetSize = CGSize(width: 640, height: 480)
    //        let scaleTransform = CGAffineTransform(scaleX: targetSize.width / ciImage.extent.width, y: targetSize.height / ciImage.extent.height)
    //        let scaledCIImage = ciImage.transformed(by: scaleTransform)
    //
    //        if let cgImage = context.createCGImage(scaledCIImage, from: CGRect(origin: .zero, size: targetSize)) {
    //            let uiImage = UIImage(cgImage: cgImage)
    //
    //            // 编码为 JPEG Data
    //            if let imageData = uiImage.jpegData(compressionQuality: 0.8) {
    //                return imageData
    //            }
    //        }
    //        return nil
    //    }
    
    private func prepareSentData(pixelBuffer: CVPixelBuffer, pose: [Float]) -> Data? {
        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
        let context = CIContext()
        
        let targetSize = CGSize(width: 640, height: 480)
        let scaleTransform = CGAffineTransform(scaleX: targetSize.width / ciImage.extent.width, y: targetSize.height / ciImage.extent.height)
        let scaledCIImage = ciImage.transformed(by: scaleTransform)
        
        var poseData = Data()
        for value in pose {
            var floatValue = value
            let floatData = Data(bytes: &floatValue, count: MemoryLayout<Float>.size)
            poseData.append(floatData)
        }
        
        var imageData = Data()
        if let cgImage = context.createCGImage(scaledCIImage, from: CGRect(origin: .zero, size: targetSize)) {
            let uiImage = UIImage(cgImage: cgImage)
            
            imageData = uiImage.jpegData(compressionQuality: 0.8) ?? Data()
            //            imageData = uiImage.pngData() ?? Data()
        }
        
        // 在 imageData 前面插入 prefixData
        var combinedData = Data()
        combinedData.append(poseData)
        combinedData.append(imageData)
        
        return combinedData
    }
    
}


