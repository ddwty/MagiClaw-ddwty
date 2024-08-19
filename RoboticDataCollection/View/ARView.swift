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

struct MyARView: View {
    @State private var cameraTransform = simd_float4x4()
    @State private var isRecording = false
    @State private var isProcessing = false
    @EnvironmentObject var recorder: ARRecorder
    @Environment(\.verticalSizeClass) var verticalSizeClass
    @State private var frameRate: Double = 0
    var body: some View {
            GeometryReader { geo in
                ARViewContainer(frameSize: CGSize(width: geo.size.width, height: verticalSizeClass == .regular ?  geo.size.width * 4 / 3 :  geo.size.width * 3 / 4), cameraTransform: $cameraTransform, recorder: recorder, frameRate: $frameRate)
                
//                Text("Frame Rate: \n\(String(format: "%.2f", frameRate)) FPS")
//                               .padding()
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
    
    func makeUIViewController(context: Context) -> ARViewController {
        let arViewController = ARViewController(frameSize: frameSize)
                arViewController.recorder = recorder
                arViewController.updateFrameRateBinding($frameRate)
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
    private var tcpServerManager: TCPServerManager?
    
    private var lastUpdateTime: CFTimeInterval = 0
        private var displayLink: CADisplayLink?
        private var frameRateBinding: Binding<Double>?
    
    init(frameSize: CGSize) {
            self.frameSize = frameSize
            super.init(nibName: nil, bundle: nil)
        }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        arView = ARView(frame: CGRect(origin: .zero, size: frameSize))
        self.view.addSubview(arView)
        arView.setupARView()
        arView.session.delegate = self
        // 启动TCP服务器
        tcpServerManager = TCPServerManager(port: 8080)
        
        // Setup CADisplayLink to track frame rate
                displayLink = CADisplayLink(target: self, selector: #selector(updateFrameRate))
                displayLink?.add(to: .main, forMode: .default)
    }
    
    func updateFrameRateBinding(_ binding: Binding<Double>) {
            self.frameRateBinding = binding
        }
        
        @objc private func updateFrameRate() {
            let now = CACurrentMediaTime()
            let delta = now - lastUpdateTime
            if delta > 0 {
                frameRateBinding?.wrappedValue = 1.0 / delta
            }
            lastUpdateTime = now
        }
    
    override func viewDidLayoutSubviews() {
           super.viewDidLayoutSubviews()
           // Update ARView frame when layout changes
           arView.frame = CGRect(origin: .zero, size: frameSize)
       }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
            super.viewWillTransition(to: size, with: coordinator)
            // 在屏幕旋转时更新框架大小
            coordinator.animate(alongsideTransition: { _ in
                self.frameSize = size
                self.arView.frame = CGRect(origin: .zero, size: size)
            }, completion: { _ in
                self.arView.runARSession() // 重新确保 ARSession 继续运行
            })
        }
    
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
        // Update camera transform and other data
//        let transformString = frame.camera.transform.description
//        tcpServerManager?.broadcastMessage(transformString)
        
            let cameraTransform = frame.camera.transform
            // 将 transform 转换为 JSON 字符串
        if let jsonString = cameraTransform.toJSONString() {
                // 发送网络请求在后台线程
                DispatchQueue.global(qos: .background).async {
                    self.tcpServerManager?.broadcastMessage(jsonString)
                }
            }
       
        recorder.recordFrame(frame)
    }
}

extension ARView {
    func setupARView() {
//        runARSession()
//        debugOptions = [.showWorldOrigin]
    }
    
    func runARSession() {
        let config = ARWorldTrackingConfiguration()
        config.isAutoFocusEnabled = true
        print("run AR Session")
        // 设置用户选择的帧率
        let desiredFrameRate = ARRecorder.shared.frameRate
        print("desiredFrameRate: \(desiredFrameRate)")
        if let videoFormat = ARWorldTrackingConfiguration.supportedVideoFormats.first(where: { $0.framesPerSecond == desiredFrameRate }) {
            config.videoFormat = videoFormat
            print("Using video format with \(desiredFrameRate) FPS")
        } else {
            print("No video format with \(desiredFrameRate) FPS found")
        }
        if ARWorldTrackingConfiguration.supportsFrameSemantics(.sceneDepth) {
            config.frameSemantics = .sceneDepth
        }
        if ARWorldTrackingConfiguration.supportsFrameSemantics(.smoothedSceneDepth) {
            config.frameSemantics.insert(.smoothedSceneDepth)
        }
        
        
        session.run(config, options: [.resetTracking, .removeExistingAnchors])
        
    }
}
