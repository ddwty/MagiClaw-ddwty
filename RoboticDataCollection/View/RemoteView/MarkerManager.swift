//
//  MarkerManager.swift
//  MagiClaw
//
//  Created by Tianyu on 9/30/24.
//

import RealityKit
import ARKit
import simd
import RealityKit
import ARKit
import simd

struct MarkerEntity {
    var id: Int
    var entity: AnchorEntity
}

class MarkerManager {
    var markers: [MarkerEntity] = []
    let arView: ARView

    init(arView: ARView) {
        self.arView = arView
    }

    // 添加或更新标记对应的立方体
    func updateMarker(id: Int, position: SIMD3<Float>) {
        if let index = markers.firstIndex(where: { $0.id == id }) {
            // 更新现有立方体的位置
            markers[index].entity.position = position
        } else {
            // 添加新的立方体
            let box = MeshResource.generateBox(size: 0.05)
            let material = SimpleMaterial(color: .blue, isMetallic: false)
            let modelEntity = ModelEntity(mesh: box, materials: [material])

            let anchor = AnchorEntity(world: position)
            anchor.addChild(modelEntity)
            arView.scene.addAnchor(anchor)

            markers.append(MarkerEntity(id: id, entity: anchor))
        }
    }

    // 移除不再检测到的标记对应的立方体
    func removeMarker(id: Int) {
        if let index = markers.firstIndex(where: { $0.id == id }) {
            markers[index].entity.removeFromParent()
            markers.remove(at: index)
        }
    }

    // 移除所有标记（可选）
    func removeAllMarkers() {
        for marker in markers {
            marker.entity.removeFromParent()
        }
        markers.removeAll()
    }
}
