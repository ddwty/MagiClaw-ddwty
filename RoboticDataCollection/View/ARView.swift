//
//  ARView.swift
//  talkWithRpi
//
//  Created by Tianyu on 7/25/24.
//

import SwiftUI
import RealityKit
import ARKit

struct MyARView: View {
    @State private var cameraTransform = simd_float4x4()
    @State private var isRecording = false
    @State private var isProcessing = false
    
    //    private var recorder = ARRecorder.shared
    @EnvironmentObject var recorder: ARRecorder
    @State private var currentOrientation = UIDevice.current.orientation
    
    var body: some View {
        VStack {
            ARViewContainer(cameraTransform: $cameraTransform, recorder: recorder)
//                .onAppear {
//                    print("on appear")
//                    ARViewContainer.resumeARSession()
//                }
//                .onDisappear {
//                    print("disappear")
//                    ARViewContainer.pauseARSession()
//                }
            
        }
    }
}



//#if DEBUG
//#Preview {
//    MyARView()
//}
//#endif


struct ARViewContainer: UIViewRepresentable {
    @Binding var cameraTransform: simd_float4x4
    var recorder: ARRecorder
    static private weak var arView: ARView?
    var isSessionRunning = false
    
    func makeUIView(context: Context) -> ARView {
        print("make AR UI View")
        let arView = ARView(frame: .zero)
        arView.setupARView()
        
        arView.session.delegate = context.coordinator
        ARViewContainer.arView = arView
        //        arView.environment.background = .color(.black)
        return arView
    }
    
    func updateUIView(_ uiView: ARView, context: Context) {
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self, recorder: recorder)
    }
    
    class Coordinator: NSObject, ARSessionDelegate {
        var parent: ARViewContainer
        var recorder: ARRecorder
        
        init(_ parent: ARViewContainer, recorder: ARRecorder) {
            self.parent = parent
            self.recorder = recorder
        }
        deinit {
            ARViewContainer.pauseARSession()
            print("Coordinator is being deinitialized and ARSession paused")
        }
        
        func session(_ session: ARSession, didUpdate frame: ARFrame) {
            DispatchQueue.main.async {
                self.parent.cameraTransform = frame.camera.transform
                //                print("Camera transform: \(self.parent.cameraTransform.description)")
                let intrinsics = frame.camera.intrinsics
                //                print("Camera intrinsics: \(intrinsics)")
            }
            recorder.recordFrame(frame)
        }
        
    }
//    static func pauseARSession() {
//        arView?.session.pause()
//        isSessionRunning = false
//        print("AR session paused")
//    }
//    static func resumeARSession() {
//        guard let arView = arView else { return }
//        if !isSessionRunning {
//            arView.runARSession()
//            isSessionRunning = true
//            print("AR session resumed")
//        }
//        
//    }
}

extension ARView {
    func setupARView() {
        runARSession()
        debugOptions = [.showWorldOrigin]
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

extension simd_float4x4 {
    var description: String {
        return """
        [\(columns.0.x), \(columns.0.y), \(columns.0.z), \(columns.0.w)]
        [\(columns.1.x), \(columns.1.y), \(columns.1.z), \(columns.1.w)]
        [\(columns.2.x), \(columns.2.y), \(columns.2.z), \(columns.2.w)]
        [\(columns.3.x), \(columns.3.y), \(columns.3.z), \(columns.3.w)]
        """
    }
}


