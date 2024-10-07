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
import SceneKit
import CoreImage

#Preview {
    RemoteARView(clawAngle: ClawAngleManager.shared)
}

struct RemoteARView: View {
    @State private var cameraTransform = simd_float4x4()
    @Environment(\.verticalSizeClass) var verticalSizeClass
    var clawAngle: ClawAngleManager
    var body: some View {
        GeometryReader { geo in
            RemoteARViewContainer(clawAngle: clawAngle, cameraTransform: $cameraTransform)
            
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
    var clawAngle: ClawAngleManager
    @Binding var cameraTransform: simd_float4x4
    @EnvironmentObject var websocketServer: WebSocketServerManager
    
    
    func makeUIViewController(context: Context) -> RemoteARViewController {
        let arViewController = RemoteARViewController(websocketServer: websocketServer, clawAngle: clawAngle)
        
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
    var websocketServer: WebSocketServerManager
    var clawAngle: ClawAngleManager
    var settingModel = SettingModel.shared
    
    
    //    var boxEntity: ModelEntity!
    // 存储当前场景中与 marker 对应的立方体，使用 arucoId 作为 key
//    var markerEntities: [Int: ModelEntity] = [:]
    var markerEntities: [Int: AnchorEntity] = [:]
    var marker0Position: simd_float3? = nil
    var marker1Position: simd_float3? = nil
    
    let boxEntity = ModelEntity(mesh: MeshResource.generateBox(size: 0.1, cornerRadius: 0.005), materials: [SimpleMaterial(color: .gray, roughness: 0.15, isMetallic: true)])
    let boxAnchor = AnchorEntity()
    var imageAnchorToEntity: [ARImageAnchor: AnchorEntity] = [:]
    
    
    
    
    private var lastUpdateTime: CFTimeInterval = 0
    private var displayLink: CADisplayLink?
    private var frameRateBinding: Binding<Double>?
    
    init(websocketServer: WebSocketServerManager, clawAngle: ClawAngleManager) {
        self.websocketServer = websocketServer
        self.clawAngle = clawAngle
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
        
        //        boxAnchor.addChild(boxEntity)
        //        arView.scene.addAnchor(boxAnchor)
        
        
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
        if let imagesToTrack = ARReferenceImage.referenceImages(inGroupNamed: "AR Resources", bundle: Bundle.main) {
            
            config.detectionImages = imagesToTrack
            config.maximumNumberOfTrackedImages = 1
        }
        
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
    
    //    func session(_ session: ARSession, didAdd anchors: [ARAnchor]) {
    //            anchors.compactMap { $0 as? ARImageAnchor }.forEach {
    //                let anchorEntity = AnchorEntity()
    //                let modelEntity = boxEntity
    //                anchorEntity.addChild(modelEntity)
    //                arView.scene.addAnchor(anchorEntity)
    //                anchorEntity.transform.matrix = $0.transform
    //                imageAnchorToEntity[$0] = anchorEntity
    //            }
    //        }
    //
    //    func session(_ session: ARSession, didUpdate anchors: [ARAnchor]) {
    //        anchors.compactMap { $0 as? ARImageAnchor }.forEach {
    //            let anchorEntity = imageAnchorToEntity[$0]
    //            anchorEntity?.transform.matrix = $0.transform
    //        }
    //    }
    
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        // Update camera transform and other data
        //        if let exifData = frame.exifData as? [String: Any] {
        //                print(exifData)
        //        }
        let cameraTransform = frame.camera.transform
       
        //        print(cameraTransform)
        
        
        
        //        DispatchQueue.global(qos: .userInitiated).async {
        //            let start = CFAbsoluteTimeGetCurrent()
        ////            self.distance = ArucoCV.calculateDistance(frame.capturedImage, withIntrinsics: frame.camera.intrinsics, andMarkerSize: ArucoProperty.ArucoMarkerSize)
        //
        ////            if transMatrixArray.count > 0 {
        ////                print(transMatrixArray[0])
        ////            }
        //            let end = CFAbsoluteTimeGetCurrent()
        //            //                    print("Time: \(end - start)")
        //
        //        }
        // 获取 Aruco marker 的位置信息
        DispatchQueue.global(qos: .userInitiated).async {
            var angleData: Float = 0.0
//            guard let resizedPixelBuffer = self.resizePixelBufferWithCoreImage(frame.capturedImage, width: 640, height: 480) else {
//                print("failed to resize")
//                return
//            }
            guard let transMatrixArray = ArucoCV.estimatePose(frame.capturedImage, withIntrinsics: frame.camera.intrinsics, andMarkerSize: ArucoProperty.ArucoMarkerSize) as? [SKWorldTransform] else {
                return
            }
            
//            var detectedIds: Set<Int> = []
            let detectedIds: Set<Int> = Set(transMatrixArray.map { Int($0.arucoId) })
          
            for transform in transMatrixArray {
                let arucoId = transform.arucoId
//                let markerTransformMatrix = matrix_multiply(cameraTransform, transform.transform)
                let markerTransformMatrix = matrix_multiply(cameraTransform, transform.transform)
                
                
                DispatchQueue.main.async { [self] in
                    if let existingEntity = self.markerEntities[Int(arucoId)] {
                        existingEntity.transform.matrix = markerTransformMatrix
                    } else {
                        var color = Color.blue
                        switch arucoId {
                        case 0: color = Color.blue
                        case 1: color = Color.green
                        default: color = Color.gray
                        }
                        
                        let boxEntity = self.createBoxEntity(color: color)
//                        boxEntity.transform.matrix = markerTransformMatrix
                        
                        let anchor = AnchorEntity()
                        anchor.transform.matrix = markerTransformMatrix
                        anchor.addChild(boxEntity)
                        self.arView.scene.addAnchor(anchor)
                        
                        self.markerEntities[Int(arucoId)] = anchor
                    }
                    if !(detectedIds.contains(0) && detectedIds.contains(1)) {
                        // 如果没有同时检测到 id 为 0 和 1 的 marker，则将 distance 和 angle 设置为 -1
//                        self.clawAngle.ClawAngleDataforShow = ClawAngleData(distance: -1.0)
//                        angleData = -1.0
                    } else {
                        let position = markerTransformMatrix.columns.3 // 平移向量
                        if arucoId == 0 {
                            self.marker0Position = simd_float3(position.x, position.y, position.z)
                        } else if arucoId == 1 {
                            self.marker1Position = simd_float3(position.x, position.y, position.z)
                        }
                    }
                }
            } //: for
            
            if let marker0 = self.marker0Position, let marker1 = self.marker1Position {
                self.clawAngle.ClawAngleDataforShow = ClawAngleData(distance: simd_distance(marker0, marker1))
                angleData = ClawAngleData.calculateTheta(distance: simd_distance(marker0, marker1))
//                            print("angle calu: \(angleData)")
              print("Distance between Marker 0 and Marker 1: \(simd_distance(marker0, marker1))")
                
                self.marker0Position = nil
                self.marker1Position = nil
//                            print("Normal angle: \(String(describing: self.clawAngle.ClawAngleDataforShow))")
            } else {
                self.clawAngle.ClawAngleDataforShow = ClawAngleData(distance: -1.0)
                angleData = -1.0
            }
            
            if RemoteControlManager.shared.enableSendingData {
                    let pose = cameraTransform.getPoseMatrix()
                    let pixelBuffer = frame.capturedImage
//                    print("angle send: \(angleData)")
                    if let combinedData = self.prepareSentData(pixelBuffer: pixelBuffer, pose: pose, angle: angleData) {
                        self.sendToClients(data: combinedData)
                    }
            }
            
            // 检查并移除未检测到的 marker 对应的立方体
            DispatchQueue.main.async {
                let currentMarkerIds = Set(self.markerEntities.keys)
                let removedIds = currentMarkerIds.subtracting(detectedIds)
                
                for id in removedIds {
                    if let entityToRemove = self.markerEntities[id] {
                        // 从场景中移除对应的立方体
                        entityToRemove.removeFromParent()
                        // 从字典中移除
                        self.markerEntities.removeValue(forKey: id)
                    }
                }
            }
        }
    }
    func createBoxEntity(color: Color) -> ModelEntity {
        let mesh = MeshResource.generateBox(size: 0.0)
        let material = SimpleMaterial(color: UIColor(color), roughness: 1, isMetallic: false)
        let boxEntity = ModelEntity(mesh: mesh, materials: [material])
        boxEntity.generateCollisionShapes(recursive: true)
        return boxEntity
    }
    
    func resizePixelBufferWithCoreImage(_ pixelBuffer: CVPixelBuffer, width: Int, height: Int) -> CVPixelBuffer? {
        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
        let scaleX = CGFloat(width) / CGFloat(CVPixelBufferGetWidth(pixelBuffer))
        let scaleY = CGFloat(height) / CGFloat(CVPixelBufferGetHeight(pixelBuffer))
        
        let resizedImage = ciImage.transformed(by: CGAffineTransform(scaleX: scaleX, y: scaleY))
        
        let ciContext = CIContext(options: nil)
        
        var newPixelBuffer: CVPixelBuffer?
        let attrs = [kCVPixelBufferIOSurfacePropertiesKey: [:]] as CFDictionary
        CVPixelBufferCreate(kCFAllocatorDefault, width, height, kCVPixelFormatType_32BGRA, attrs, &newPixelBuffer)
        
        if let newPixelBuffer = newPixelBuffer {
            ciContext.render(resizedImage, to: newPixelBuffer)
            return newPixelBuffer
        }
        return nil
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
    
    private func prepareSentData(pixelBuffer: CVPixelBuffer, pose: [Float], angle: Float) -> Data? {
        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
        let context = CIContext()
        
        let targetSize = CGSize(width: 640, height: 480)
        let scaleTransform = CGAffineTransform(scaleX: targetSize.width / ciImage.extent.width, y: targetSize.height / ciImage.extent.height)
        let scaledCIImage = ciImage.transformed(by: scaleTransform)
        
        var angleFloatValue = angle
        var angleData = Data(bytes: &angleFloatValue, count: MemoryLayout<Float>.size)
        
        
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
        
        var combinedData = Data()
        combinedData.append(angleData)
        combinedData.append(poseData)
        combinedData.append(imageData)
        
        return combinedData
    }
    
}


