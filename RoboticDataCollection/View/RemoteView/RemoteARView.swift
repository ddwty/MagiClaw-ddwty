//
//  RemoteARView.swift
//  MagiClaw
//
//  Created by 吴天禹 on 2024/9/10.
//


import SwiftUI
import RealityKit
import ARKit
//
//struct RemoteARView: View {
//    @State private var cameraTransform = simd_float4x4()
//    @State private var frameRate: Double = 0
//    
//    var body: some View {
//        VStack {
//            RemoteARViewContainer(cameraTransform: $cameraTransform, frameRate: $frameRate)
////                .edgesIgnoringSafeArea(.all)
//        }
//    }
//}
//
//
//
//#if DEBUG
//#Preview {
//    RemoteARView()
//}
//#endif
//
//
//struct RemoteARViewContainer: UIViewRepresentable {
//    @Binding var cameraTransform: simd_float4x4
//    @Binding var frameRate: Double
//   
//    
//    func makeUIView(context: Context) -> ARView {
//        let arView = ARView(frame: .zero)
//        let config = ARWorldTrackingConfiguration()
////        config.frameSemantics = .sceneDepth
//        config.isAutoFocusEnabled = true
//       
////        debugOptions = [.showWorldOrigin]
////        arView.debugOptions.insert(.showStatistics)
//        arView.debugOptions.insert(.showWorldOrigin)
//        
//        arView.session.delegate = context.coordinator
//        arView.session.run(config)
//        
//        //
////        arView.environment.background = .color(.black)
//        return arView
//    }
//
//    func updateUIView(_ uiView: ARView, context: Context) {}
//
//    func makeCoordinator() -> Coordinator {
//        Coordinator(self)
//    }
//
//    class Coordinator: NSObject, ARSessionDelegate {
//        var parent: RemoteARViewContainer
//        var settingModel = SettingModel.shared
////        @EnvironmentObject var websocketServer: WebSocketServerManager
//        var websocketServer = WebSocketServerManager(port: 8080)
//
//        init(_ parent: RemoteARViewContainer) {
//            self.parent = parent
//        }
//
//        func session(_ session: ARSession, didUpdate frame: ARFrame) {
//            if settingModel.enableSendingData {
//                DispatchQueue.global(qos: .background).async {
//                let cameraTransform = frame.camera.transform
//                let pose = cameraTransform.getPoseMatrix()
//                let pixelBuffer = frame.capturedImage
////                    print(cameraTransform)
//                
//                    if let combinedData = self.prepareSentData(pixelBuffer: pixelBuffer, pose: pose) {
//                   
//                        self.sendToClients(data: combinedData)
//                    }
//                }
//            }
//                self.parent.cameraTransform = frame.camera.transform
////
//            
//        }
//        
//        private func sendToClients(message: String) {
//            // 发送文本数据到所有连接的客户端
//            websocketServer.connectionsByID.values.forEach { connection in
//                connection.send(text: message)
//            }
//        }
//        
//        private func sendToClients(data: Data) {
//            // 发送二进制数据到所有连接的客户端
//            websocketServer.connectionsByID.values.forEach { connection in
//                connection.send(data: data)
//            }
//        }
//        private func prepareSentData(pixelBuffer: CVPixelBuffer, pose: [Float]) -> Data? {
//            let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
//            let context = CIContext()
//
//            let targetSize = CGSize(width: 640, height: 480)
//            let scaleTransform = CGAffineTransform(scaleX: targetSize.width / ciImage.extent.width, y: targetSize.height / ciImage.extent.height)
//            let scaledCIImage = ciImage.transformed(by: scaleTransform)
//            
//            var poseData = Data()
//            for value in pose {
//                var floatValue = value
//                let floatData = Data(bytes: &floatValue, count: MemoryLayout<Float>.size)
//                poseData.append(floatData)
//            }
//            
//            var imageData = Data()
//            if let cgImage = context.createCGImage(scaledCIImage, from: CGRect(origin: .zero, size: targetSize)) {
//                let uiImage = UIImage(cgImage: cgImage)
//               
//                imageData = uiImage.jpegData(compressionQuality: 0.8) ?? Data()
//            }
//            
//            // 在 imageData 前面插入 prefixData
//            var combinedData = Data()
//                combinedData.append(poseData)
//            combinedData.append(imageData)
//            
//            return combinedData
//        }
//    }
//    
    
    
//}

#Preview {
    RemoteARView()
}



import SwiftUI
import RealityKit
import ARKit
import simd
import Accelerate
import AVFoundation

struct RemoteARView: View {
    @State private var cameraTransform = simd_float4x4()
    @Environment(\.verticalSizeClass) var verticalSizeClass
    var body: some View {
            GeometryReader { geo in
                RemoteARViewContainer(cameraTransform: $cameraTransform)
                
            }
        
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
    var websocketServer: WebSocketServerManager
    var settingModel = SettingModel.shared
    
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
        arView.autoresizingMask = [.flexibleWidth, .flexibleHeight] // 确保 ARView 会随着视图的大小变化而调整
        self.view.addSubview(arView)
        arView.session.delegate = self
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
        

        arView.debugOptions = [.showWorldOrigin]
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
        
        if SettingModel.shared.enableSendingData {
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
            let cameraTransform = frame.camera.transform
            let pose = cameraTransform.getPoseMatrix()
            let pixelBuffer = frame.capturedImage
            
                if let combinedData = self.prepareSentData(pixelBuffer: pixelBuffer, pose: pose) {
               
                    self.sendToClients(data: combinedData)
                }
            }
        }
//        DispatchQueue.global(qos: .userInitiated).async {
//            self.distance = ArucoCV.calculateDistance(frame.capturedImage, withIntrinsics: frame.camera.intrinsics, andMarkerSize: ArucoProperty.ArucoMarkerSize)
//        }
       
    }
}

extension RemoteARViewController {
    private func sendToClients(message: String) {
        // 发送文本数据到所有连接的客户端
        websocketServer.connectionsByID.values.forEach { connection in
            connection.send(text: message)
        }
    }
    
    private func sendToClients(data: Data) {
        // 发送二进制数据到所有连接的客户端
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
        }
        
        // 在 imageData 前面插入 prefixData
        var combinedData = Data()
            combinedData.append(poseData)
        combinedData.append(imageData)
        
        return combinedData
    }

}


