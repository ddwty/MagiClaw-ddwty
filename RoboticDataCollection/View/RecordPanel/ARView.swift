//
//  ARView.swift
//  talkWithRpi
//
//  Created by Tianyu on 7/25/24.
//

import SwiftUI
import RealityKit
import ARKit
import simd
import Accelerate
import AVFoundation
import CoreImage

//TODO: 第二次旋转后，立方体会停留在原处，没有跟随marker移动
struct MyARView: View {
    @State private var cameraTransform = simd_float4x4()
    @State private var isRecording = false
    @State private var isProcessing = false
    @Binding var isPortrait: Bool  // 用于按钮控制屏幕方向
    @State var flashLightOn: Bool = false
    
    @EnvironmentObject var recorder: ARRecorder
    @Environment(\.verticalSizeClass) var verticalSizeClass
    @Environment(\.colorScheme) var colorScheme
    @State private var frameRate: Double = 0
    @State private var viewIdentityID = 0
    var clawAngle: ClawAngleManager
    
    var body: some View {
            GeometryReader { geo in
                ARViewContainer(frameSize: CGSize(width: geo.size.width, height: verticalSizeClass == .regular ?  geo.size.width * 4 / 3 :  geo.size.width * 3 / 4), cameraTransform: $cameraTransform, recorder: recorder, frameRate: $frameRate, clawAngle: clawAngle)
//                 .id(viewIdentityID) // 这将强制在方向改变时重新创建视图
//#if DEBUG
//                    .overlay{
//
//Image("fakeARView")
//    .resizable()
//    .aspectRatio(contentMode: .fill)
//
//                    }
//#endif
                    .overlay {
                        VStack {
                            Spacer()
                            HStack {
                                Button(action: {
                                    self.flashLightOn.toggle()
                                    let impactFeedbackGenerator = UIImpactFeedbackGenerator(style: .medium)
                                    impactFeedbackGenerator.impactOccurred()
                                    toggleTorch(on: flashLightOn)
                                   
                                }) {
                                    Image(systemName: self.flashLightOn ? "flashlight.on.fill" : "flashlight.off.fill")
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(width: 25, height: 25)
                                        .padding(5)
                                        .background(
                                            .regularMaterial,
                                            in: RoundedRectangle(cornerRadius: 8, style: .continuous)
                                        )
                                        .foregroundColor(self.flashLightOn ? Color.yellow : Color("tintColor"))
                                }
                                .padding()
                                Spacer()
                                // 仅针对iPhone有屏幕旋转按钮
                                if UIDevice.current.userInterfaceIdiom == .phone {
                                            Spacer()
                                            Button(action: {
                                                self.viewIdentityID += 1
                                                print("id: \(viewIdentityID)")
                                                toggleOrientation(isPortrait: &isPortrait)
                                                
                                            }) {
                                                Image(systemName: "rectangle.portrait.rotate")
                                                    .resizable()
                                                    .aspectRatio(contentMode: .fit)
                                                    .frame(width: 25, height: 25)
                                                    .padding(5)
                                                    .background(
                                                        .regularMaterial,
                                                        in: RoundedRectangle(cornerRadius: 8, style: .continuous)
                                                    )
                                                    .foregroundColor(Color("tintColor"))
                                            }
                                            .padding()
                                }
                            }
                        }
                        
                    }
                    
            }
    }
  
}



//#if DEBUG
//#Preview {
//    MyARView()
//}
//#endif


struct ARViewContainer: UIViewControllerRepresentable {
    var frameSize: CGSize
    @Binding var cameraTransform: simd_float4x4
    var recorder: ARRecorder
    @Binding var frameRate: Double
    @EnvironmentObject var websocketServer: WebSocketServerManager
    var clawAngle: ClawAngleManager
  
    
    func makeUIViewController(context: Context) -> ARViewController {
        let arViewController = ARViewController(frameSize: frameSize, websocketServer: websocketServer, clawAngle: clawAngle)
                arViewController.recorder = recorder
                return arViewController
    }
    
    func updateUIViewController(_ uiViewController: ARViewController, context: Context) {
        uiViewController.updateARViewFrame(frameSize: frameSize)
    }
    
    class Coordinator: NSObject {
        var parent: ARViewContainer
        var recorder: ARRecorder
        
        init(parent: ARViewContainer, recorder: ARRecorder) {
            self.parent = parent
            self.recorder = recorder
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self, recorder: recorder)
    }
}





class ARViewController: UIViewController, ARSessionDelegate {
    var arView: ARView!
    var frameSize: CGSize
    var recorder: ARRecorder!
//    var tcpServerManager: TCPServerManager
    var websocketServer: WebSocketServerManager
    var settingModel = SettingModel.shared
    var clawAngle: ClawAngleManager
    var distance = 0.0
    
//    var markerEntities: [Int: ModelEntity] = [:]
    var markerEntities: [Int: AnchorEntity] = [:]
    var marker0Position: simd_float3? = nil
    var marker1Position: simd_float3? = nil
   
    
    
    private var lastUpdateTime: CFTimeInterval = 0
        private var displayLink: CADisplayLink?
        private var frameRateBinding: Binding<Double>?
    
    init(frameSize: CGSize, websocketServer: WebSocketServerManager, clawAngle: ClawAngleManager) {
        self.frameSize = frameSize
        self.websocketServer = websocketServer
        self.clawAngle = clawAngle
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    override func viewDidLoad() {
        print("viewDidLoad")
        super.viewDidLoad()
        arView = ARView(frame: CGRect(origin: .zero, size: frameSize))
        print("view did load frameSize: \(frameSize)")
        arView.addCoaching()
        self.view.addSubview(arView)
        arView.session.delegate = self
        
       
    }
    
   
    override func viewDidLayoutSubviews() {
           super.viewDidLayoutSubviews()
           // Update ARView frame when layout changes
           arView.frame = CGRect(origin: .zero, size: frameSize)
        
        if let coachingOverlay = arView.subviews.first(where: {$0 is ARCoachingOverlayView}) as? ARCoachingOverlayView {
            coachingOverlay.frame = arView.frame
        }
          
    }
    
//    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
//        super.viewWillTransition(to: size, with: coordinator)
//        self.updateARViewFrame(frameSize: self.frameSize)
//    }
    
    func updateARViewFrame(frameSize: CGSize) {
           // Update the frame size when passed from SwiftUI
           self.frameSize = frameSize
           arView.frame = CGRect(origin: .zero, size: frameSize)
        print("2222222")
//        removeAllMarkers()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        arView.runARSession()
        print("33333333")
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        arView.session.pause()
        print("44444444")
    }
    
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
 
        let status = frame.camera.trackingState
        let cameraTransform = frame.camera.transform
//        print("tracking state: \(status)")
        recorder.recordFrame(frame)
//        print("frame size: \(frame.camera.imageResolution)")
        // convert frame to 640x480
//        let start = CFAbsoluteTimeGetCurrent()
//        let imageBuffer = frame.capturedImage
//        let resizeBuffer = resizePixelBuffer(imageBuffer, width: 640, height: 480)
//        let srcWidth = CVPixelBufferGetWidth(resizeBuffer!)
//        let srcHeight = CVPixelBufferGetHeight(resizeBuffer!)
////        print("frame size: \(srcWidth)")
//        let end = CFAbsoluteTimeGetCurrent()
////        print("Time: \(end - start)")
//                // 在后台线程中处理 marker 检测和实体创建
        DispatchQueue.global(qos: .userInitiated).async {
            guard let transMatrixArray = ArucoCV.estimatePose(frame.capturedImage, withIntrinsics: frame.camera.intrinsics, andMarkerSize: ArucoProperty.ArucoMarkerSize) as? [SKWorldTransform] else {
               
                
                return
            }
           
            let detectedIds: Set<Int> = Set(transMatrixArray.map { Int($0.arucoId) })
            for transform in transMatrixArray {
                let arucoId = transform.arucoId
//                let markerTransformMatrix = matrix_multiply(cameraTransform, transform.transform)
                let markerTransformMatrix = matrix_multiply(cameraTransform, transform.transform)
                
                DispatchQueue.main.async { [self] in
                    // 如果 marker 对应的立方体已经存在，则更新其位置
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
                        self.clawAngle.ClawAngleDataforShow = ClawAngleData(distance: -1.0)
                    } else {
                        // 获取 marker 0 和 marker 1 的位置信息
                        let position = markerTransformMatrix.columns.3 // 平移向量
                        if arucoId == 0 {
                            self.marker0Position = simd_float3(position.x, position.y, position.z)
                        } else if arucoId == 1 {
                            self.marker1Position = simd_float3(position.x, position.y, position.z)
                        }
                        
                        // 计算并打印欧式距离
                        if let marker0 = self.marker0Position, let marker1 = marker1Position {
                            //                        clawAngle.distance =
//                            clawAngle.distance = simd_distance(marker0, marker1)
                            self.clawAngle.ClawAngleDataforShow = ClawAngleData(distance: simd_distance(marker0, marker1))
                            //                        print("Euclidean distance between Marker 0 and Marker 1: \(distance)")
                            if clawAngle.isRecording {
                                self.clawAngle.recordedAngleData.append(ClawAngleData(timeStamp: Date().timeIntervalSince1970 - clawAngle.startTime, distance: simd_distance(marker0, marker1)))
                            }
                        }
                    }
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
        let mesh = MeshResource.generateBox(size: 0.02, cornerRadius: 0.001)
        let material = SimpleMaterial(color: UIColor(color), roughness: 0.4, isMetallic: false)
        let boxEntity = ModelEntity(mesh: mesh, materials: [material])
        boxEntity.generateCollisionShapes(recursive: true)
        return boxEntity
    }
    // 移除所有 marker 对应的锚点
   
    func removeAllMarkers() {
        for (_, anchor) in markerEntities {
            arView.scene.removeAnchor(anchor)
        }
        markerEntities.removeAll()
    }
}


extension ARView {
    
    func runARSession() {
        let config = ARWorldTrackingConfiguration()
//        config.isAutoFocusEnabled = true
        
        // 设置用户选择的帧率
        let desiredFrameRate = SettingModel.shared.frameRate
        print("desiredFrameRate: \(desiredFrameRate)")
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

//         配置相机的焦距等设置
//            if let device = ARWorldTrackingConfiguration.configurableCaptureDeviceForPrimaryCamera {
//                do {
//                    try device.lockForConfiguration()
//
//                    // 配置焦点模式，例如：
//                    device.focusMode = .locked
//                    print("exposure duration: \(device.exposureDuration)")
//                    device.exposureMode = .locked
//                    let minDuration = CMTime(value: 1, timescale: 1000) // 1ms
//                    let maxDuration = CMTime(value: 1, timescale: 3000)   // 1/30s
//                    device.setExposureModeCustom(duration: maxDuration, iso: device.iso, completionHandler: nil)
//
////                    device.setExposureModeCustom(duration: device.activeFormat.minExposureDuration, iso: 100, completionHandler: nil)
//                    device.setFocusModeLocked(lensPosition: 1.0, completionHandler: nil)
//                    print("set focus!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!")
//                    
//                    
//
//                    
////                    config.isAutoFocusEnabled = true  // 或根据需要设置为 true
//
//                    device.unlockForConfiguration()
//                } catch {
//                    print("Failed to configure camera device: \(error.localizedDescription)")
//                }
//            }
        
        
        if SettingModel.shared.showWorldOrigin {
            debugOptions = [.showWorldOrigin]
        }
        session.run(config, options: [.resetTracking, .removeExistingAnchors])
    }

}

extension ARView: ARCoachingOverlayViewDelegate {
    func addCoaching() {
        let coachingOverlay = ARCoachingOverlayView()

        // Goal is a field that indicates your app's tracking requirements.
        coachingOverlay.goal = .tracking
             
        // The session this view uses to provide coaching.
        coachingOverlay.session = self.session
             
        // How a view should resize itself when its superview's bounds change.
        coachingOverlay.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        coachingOverlay.frame = self.frame

        self.addSubview(coachingOverlay)
    }
}
