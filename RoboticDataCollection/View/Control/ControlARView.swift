//
//  ControlView.swift
//  MagiClaw
//
//  Created by Tianyu on 11/17/24.
//

import SwiftUI
import RealityKit

struct ControlView: View {
    var body: some View {
        ZStack {
            SimulationView()
                    
        }
    }
}

struct SimulationView: UIViewRepresentable {
    func makeUIView(context: Context) -> ARView {
       
        let arView = ARView(frame: .zero, cameraMode: .nonAR, automaticallyConfigureSession: true)
        
        
        let mesh = MeshResource.generateBox(size: 0.5)
        let material = SimpleMaterial(color: UIColor(.green), roughness: 1, isMetallic: false)
        let boxEntity = ModelEntity(mesh: mesh, materials: [material])
        boxEntity.position = [0, -0.5, -0.5]
        // 加载 3D 模型
        let tableEntity = try! Entity.load(named: "tableModel.usdz")
        tableEntity.position = [0, -0.2, -0]
//        tableEntity.scale = [0.6, 0.1, 0.1]
        // 创建一个场景锚点
        let anchor = AnchorEntity()
        anchor.addChild(tableEntity)
        anchor.addChild(boxEntity)
        
        
        boxEntity.generateCollisionShapes(recursive: true)
        
        let directionalLight = DirectionalLight()
        directionalLight.light.intensity = 10000
        
        directionalLight.look(at: [0, 0, -1], from: [0, 1, 0], relativeTo: nil)

        // 添加光源到场景
        let lightAnchor = AnchorEntity(world: .zero)
        lightAnchor.addChild(directionalLight)
        arView.scene.addAnchor(lightAnchor)
        
        // -------------------------------------
        let planeMesh = MeshResource.generatePlane(width: 10, depth: 10)
        let planeMaterial = SimpleMaterial(color: .gray, roughness: 0.5, isMetallic: false)
        let planeEntity = ModelEntity(mesh: planeMesh, materials: [planeMaterial])
        let planeAnchor = AnchorEntity(world: .zero)
        planeAnchor.addChild(planeEntity)
        arView.scene.addAnchor(planeAnchor)
        
        let camera = PerspectiveCamera()
        camera.look(at: [0, 0, 0], from: [0, 1, 0], relativeTo: nil)
        let cameraAnchor = AnchorEntity(world: .zero)
        cameraAnchor.addChild(camera)

       
        arView.environment.background = .color(.gray)
        arView.scene.addAnchor(cameraAnchor)
        
       
        arView.installGestures([.rotation, .translation, .scale], for: boxEntity as HasCollision)
        
        // 将锚点添加到 ARView 的场景中
        arView.scene.addAnchor(anchor)
        
       
        return arView
    }
    
    func updateUIView(_ uiView: ARView, context: Context) {
    }
    
    
}
#Preview {
    ControlView()
}
