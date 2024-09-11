//
//  RemoteARView.swift
//  MagiClaw
//
//  Created by 吴天禹 on 2024/9/10.
//


import SwiftUI
import RealityKit
import ARKit

struct RemoteARView: View {
    @State private var cameraTransform = simd_float4x4()
    @State private var isRecording = false
    @State private var isProcessing = false
    
//    private var recorder = ARRecorder.shared
    @EnvironmentObject var recorder: ARRecorder
    
    var body: some View {
        VStack {
            RemoteARViewContainer(cameraTransform: $cameraTransform, recorder: recorder)
//                .edgesIgnoringSafeArea(.all)
                
            
//            Text("Camera Transform:")
//            Text("\(cameraTransform.description)")
//                .font(.footnote)
//                .padding()
//
        }
    }
}



#if DEBUG
#Preview {
    RemoteARView()
}
#endif


struct RemoteARViewContainer: UIViewRepresentable {
    @Binding var cameraTransform: simd_float4x4
    var recorder: ARRecorder

    func makeUIView(context: Context) -> ARView {
        let arView = ARView(frame: .zero)
        arView.setupARView()
//        arView.debugOptions.insert(.showStatistics)
        arView.debugOptions.insert(.showWorldOrigin)
        
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
        var parent: RemoteARViewContainer
        var recorder: ARRecorder

        init(_ parent: RemoteARViewContainer, recorder: ARRecorder) {
            self.parent = parent
            self.recorder = recorder
        }

        func session(_ session: ARSession, didUpdate frame: ARFrame) {
            DispatchQueue.main.async {
                self.parent.cameraTransform = frame.camera.transform
//                print("Camera transform: \(self.parent.cameraTransform.description)")
            }
            recorder.recordFrame(frame)
        }
    }
}

extension ARView {
    func setupARView() {
        let config = ARWorldTrackingConfiguration()
//        config.frameSemantics = .sceneDepth
        config.isAutoFocusEnabled = true
        session.run(config)
//        debugOptions = [.showWorldOrigin]
//        debugOptions = []
    }
}

#Preview {
    RemoteARView()
}
