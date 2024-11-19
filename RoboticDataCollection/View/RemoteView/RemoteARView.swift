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
        .checkPermissions([.camera,.microphone, .localNetwork])
        
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
                config.frameSemantics.insert(.sceneDepth)
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
        let cameraTransform = frame.camera.transform
        
        // 使用串行队列来确保处理顺序
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            var angleData: Float = -1.0
            var detectedIds: Set<Int> = []
            var marker0Position: simd_float3?
            var marker1Position: simd_float3?
            
            if let transMatrixArray = ArucoCV.estimatePose(frame.capturedImage, withIntrinsics: frame.camera.intrinsics, andMarkerSize: ArucoProperty.ArucoMarkerSize) as? [SKWorldTransform] {
                detectedIds = Set(transMatrixArray.map { Int($0.arucoId) })
                
                for transform in transMatrixArray {
                    let arucoId = transform.arucoId
                    let markerTransformMatrix = matrix_multiply(cameraTransform, transform.transform)
                    let position = markerTransformMatrix.columns.3
                    
                    if arucoId == 0 {
                        marker0Position = simd_float3(position.x, position.y, position.z)
                    } else if arucoId == 1 {
                        marker1Position = simd_float3(position.x, position.y, position.z)
                    }
                    
                    DispatchQueue.main.async {
                        self.updateMarkerEntity(for: Int(arucoId), with: markerTransformMatrix)
                    }
                }
                
                if let marker0 = marker0Position, let marker1 = marker1Position {
                    let distance = simd_distance(marker0, marker1)
                    angleData = ClawAngleData.calculateTheta(distance: distance)
                    
                    DispatchQueue.main.async {
                        self.clawAngle.ClawAngleDataforShow = angleData
                    }
                    print("found")
                } else {
                    print("no marker")
                    DispatchQueue.main.async {
                        self.clawAngle.ClawAngleDataforShow = nil
                        angleData = -1
                    }
                }
            }
            
            if RemoteControlManager.shared.enableSendingData {
                let pose = cameraTransform.getPoseMatrix()
                let pixelBuffer = frame.capturedImage
                let depthBuffer = SettingModel.shared.smoothDepth ? frame.smoothedSceneDepth?.depthMap : frame.sceneDepth?.depthMap
                
                if let combinedData = self.prepareSentData(pixelBuffer: pixelBuffer, pose: pose, angle: angleData, depthBuffer: depthBuffer) {
                    self.sendToClients(data: combinedData)
                }
            }
            
            DispatchQueue.main.async {
                self.removeUndetectedMarkers(detectedIds: detectedIds)
            }
        }
    }
    
    private func updateMarkerEntity(for arucoId: Int, with transform: simd_float4x4) {
        if let existingEntity = self.markerEntities[arucoId] {
            existingEntity.transform.matrix = transform
        } else {
            let color: Color = arucoId == 0 ? .blue : (arucoId == 1 ? .green : .gray)
            let boxEntity = self.createBoxEntity(color: color)
            let anchor = AnchorEntity()
            anchor.transform.matrix = transform
            anchor.addChild(boxEntity)
            self.arView.scene.addAnchor(anchor)
            self.markerEntities[arucoId] = anchor
        }
    }
    
    private func removeUndetectedMarkers(detectedIds: Set<Int>) {
        let currentMarkerIds = Set(self.markerEntities.keys)
        let removedIds = currentMarkerIds.subtracting(detectedIds)
        
        for id in removedIds {
            if let entityToRemove = self.markerEntities[id] {
                entityToRemove.removeFromParent()
                self.markerEntities.removeValue(forKey: id)
            }
        }
    }
    
    func createBoxEntity(color: Color) -> ModelEntity {
        let mesh = MeshResource.generateBox(size: 0.005)
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
    
    private func prepareSentData(pixelBuffer: CVPixelBuffer, pose: [Float], angle: Float, depthBuffer: CVPixelBuffer?) -> Data? {
       
        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
        let context = CIContext()
        
        let targetSize = CGSize(width: 640, height: 480)
        let scaleTransform = CGAffineTransform(scaleX: targetSize.width / ciImage.extent.width, y: targetSize.height / ciImage.extent.height)
        let scaledCIImage = ciImage.transformed(by: scaleTransform)
        
        var angleFloatValue = angle
        print("angleValue: \(angleFloatValue)")
        var angleData = Data(bytes: &angleFloatValue, count: MemoryLayout<Float>.size)
        
        //0.004
        
        var poseData = Data()
        for value in pose {
            var floatValue = value
            let floatData = Data(bytes: &floatValue, count: MemoryLayout<Float>.size)
            poseData.append(floatData)
        }
        
        //0.002
        let startTime = CACurrentMediaTime()
        var depthData = Data()
        if let depthBuffer = depthBuffer {
            CVPixelBufferLockBaseAddress(depthBuffer, .readOnly)
            defer { CVPixelBufferUnlockBaseAddress(depthBuffer, .readOnly) }
            let width = CVPixelBufferGetWidth(depthBuffer)
            let height = CVPixelBufferGetHeight(depthBuffer)
            
            if let baseAddress = CVPixelBufferGetBaseAddress(depthBuffer) {
                let float32Pointer = baseAddress.assumingMemoryBound(to: Float32.self)
                let bufferSize = width * height
                
                var floatBuffer = [Float](repeating: 0, count: bufferSize)
        
                // 使用 vDSP 进行缩放
                vDSP_vsmul(float32Pointer, 1, [Float(10000)], &floatBuffer, 1, vDSP_Length(bufferSize))
                
                var uint16Buffer = [UInt16](repeating: 0, count: bufferSize)
                
                var lower: Float = 0
                var upper: Float = 65535
                vDSP_vclip(floatBuffer, 1, &lower, &upper, &floatBuffer, 1, vDSP_Length(bufferSize))
                
                vDSP_vfixu16(floatBuffer, 1, &uint16Buffer, 1, vDSP_Length(bufferSize))
                
                depthData = Data(bytes: &uint16Buffer, count: bufferSize * MemoryLayout<UInt16>.size)
            } else {
                print("No baseAddress")
            }
        } else {
            print("No depth buffer")
        }
        let endTime = CACurrentMediaTime()
        print("depthData time: \(endTime - startTime)")
        
        
        
        var imageData = Data()
        if let cgImage = context.createCGImage(scaledCIImage, from: CGRect(origin: .zero, size: targetSize)) {
            let uiImage = UIImage(cgImage: cgImage)
            
            imageData = uiImage.jpegData(compressionQuality: 0.8) ?? Data()
            //            imageData = uiImage.pngData() ?? Data()
        }
        //0.05
       // 0.0002
        
        var combinedData = Data()
        combinedData.append(angleData)
        combinedData.append(poseData)
        if !depthData.isEmpty {
            combinedData.append(depthData)
        }
        
        combinedData.append(imageData)
        
        return combinedData
    }
    
}


