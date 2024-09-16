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
    
    var body: some View {
            GeometryReader { geo in
                ARViewContainer(frameSize: CGSize(width: geo.size.width, height: verticalSizeClass == .regular ?  geo.size.width * 4 / 3 :  geo.size.width * 3 / 4), cameraTransform: $cameraTransform, recorder: recorder, frameRate: $frameRate)
//                 .id(verticalSizeClass) // 这将强制在方向改变时重新创建视图
                    .overlay {
                        VStack {
                            Spacer()
                            Text("\(geo.size.width)")
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
                                        .foregroundColor(Color("tintColor"))
                                }
                                .padding()
                                Spacer()
                                // 仅针对iPhone有屏幕旋转按钮
                                if UIDevice.current.userInterfaceIdiom == .phone {
                                            Spacer()
                                            Button(action: {
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
            .border(.red)
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
    var websocketServer = WebSocketServerManager(port: 8081)
  
    
    func makeUIViewController(context: Context) -> ARViewController {
        let arViewController = ARViewController(frameSize: frameSize, websocketServer: websocketServer)
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
    
    var distance = 0.0
   
    
    
    private var lastUpdateTime: CFTimeInterval = 0
        private var displayLink: CADisplayLink?
        private var frameRateBinding: Binding<Double>?
    
    init(frameSize: CGSize, websocketServer: WebSocketServerManager) {
        self.frameSize = frameSize
        self.websocketServer = websocketServer
        super.init(nibName: nil, bundle: nil)
        print("init")
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
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        arView.runARSession()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        arView.session.pause()
    }
    
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
 
        let status = frame.camera.trackingState
//        print("tracking state: \(status)")
        
       
        recorder.recordFrame(frame)
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
