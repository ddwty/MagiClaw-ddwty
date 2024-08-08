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
    
    var body: some View {
        VStack {
            ARViewContainer(cameraTransform: $cameraTransform, recorder: recorder)
//                .edgesIgnoringSafeArea(.all)
        }
    }
}



#if DEBUG
#Preview {
    MyARView()
}
#endif


struct ARViewContainer: UIViewRepresentable {
    @Binding var cameraTransform: simd_float4x4
    var recorder: ARRecorder

    func makeUIView(context: Context) -> ARView {
        let arView = ARView(frame: .zero)
        arView.setupARView()
//        arView.debugOptions.insert(.showStatistics)
//        arView.debugOptions.insert([.showWorldOrigin])
    
        
        arView.session.delegate = context.coordinator
        
        //
//        arView.environment.background = .color(.black)
        return arView
    }

    func updateUIView(_ uiView: ARView, context: Context) {}

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
}

extension ARView {
    func setupARView() {
        let config = ARWorldTrackingConfiguration()
        config.isAutoFocusEnabled = true
        if ARWorldTrackingConfiguration.supportsFrameSemantics(.sceneDepth) {
                   config.frameSemantics = .sceneDepth
               }
        if ARWorldTrackingConfiguration.supportsFrameSemantics(.smoothedSceneDepth) {
                   config.frameSemantics.insert(.smoothedSceneDepth)
               }
        
//        // 设置视频格式
//               if let videoFormat = ARWorldTrackingConfiguration.supportedVideoFormats.first(where: { $0.framesPerSecond == 3 }) {
//                   config.videoFormat = videoFormat
//                   print("Using video format with 30 FPS")
//               } else {
//                   print("No video format with 30 FPS found")
//               }
       
        session.run(config)
        debugOptions = [.showWorldOrigin, .showStatistics]
     
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
