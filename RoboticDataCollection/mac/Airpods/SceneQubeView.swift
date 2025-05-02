//
//  SceneQubeView.swift
//  MagiClaw
//
//  Created by Tianyu on 4/16/25.
//

import CoreMotion
import SwiftUI
#if os(macOS)
struct SceneCubeView: NSViewRepresentable {
    var motionData: CMDeviceMotion?
    var calibrationQuaternion: CMQuaternion?
    
    func makeNSView(context: Context) -> SCNView {
        let sceneView = SCNView()
        sceneView.scene = createScene()
        sceneView.allowsCameraControl = true
        sceneView.backgroundColor = .clear
        sceneView.autoenablesDefaultLighting = true
        return sceneView
    }
    
    func updateNSView(_ nsView: SCNView, context: Context) {
        if let motionData = motionData, let cube = nsView.scene?.rootNode.childNode(withName: "cube", recursively: true) {
            // Convert quaternion from CoreMotion to SceneKit
            let q = motionData.attitude.quaternion
            
            // Apply calibration if available
            if let calibration = calibrationQuaternion {
                // Calculate the inverse of the calibration quaternion
                let invCal = inverseQuaternion(calibration)
                
                // Apply the inverse calibration to the current quaternion
                let calibratedQ = multiplyQuaternions(invCal, q)
                
                // Convert to SceneKit quaternion - 反转 y 轴方向
                let rotation = SCNQuaternion(
                    x: CGFloat(Float(-calibratedQ.x)),
                    y: CGFloat(Float(-calibratedQ.z)),  // 注意这里改为负号
                    z: CGFloat(Float(-calibratedQ.y)),
                    w: CGFloat(Float(calibratedQ.w))
                )
                
                // Apply smooth animation
                SCNTransaction.begin()
                SCNTransaction.animationDuration = 0.1
                cube.orientation = rotation
                SCNTransaction.commit()
            } else {
                // No calibration, use raw quaternion - 反转 y 轴方向
                let rotation = SCNQuaternion(
                    x: CGFloat(Float(-q.x)),
                    y: CGFloat(Float(-q.z)),  // 注意这里改为负号
                    z: CGFloat(Float(-q.y)),
                    w: CGFloat(Float(q.w))
                )
                
                // Apply smooth animation
                SCNTransaction.begin()
                SCNTransaction.animationDuration = 0.1
                cube.orientation = rotation
                SCNTransaction.commit()
            }
        }
    }
    
    // Helper function to calculate inverse quaternion
    private func inverseQuaternion(_ q: CMQuaternion) -> CMQuaternion {
        let norm = q.x * q.x + q.y * q.y + q.z * q.z + q.w * q.w
        return CMQuaternion(x: -q.x / norm, y: -q.y / norm, z: -q.z / norm, w: q.w / norm)
    }
    
    // Helper function to multiply quaternions
    private func multiplyQuaternions(_ q1: CMQuaternion, _ q2: CMQuaternion) -> CMQuaternion {
        return CMQuaternion(
            x: q1.w * q2.x + q1.x * q2.w + q1.y * q2.z - q1.z * q2.y,
            y: q1.w * q2.y - q1.x * q2.z + q1.y * q2.w + q1.z * q2.x,
            z: q1.w * q2.z + q1.x * q2.y - q1.y * q2.x + q1.z * q2.w,
            w: q1.w * q2.w - q1.x * q2.x - q1.y * q2.y - q1.z * q2.z
        )
    }
    
    private func createScene() -> SCNScene {
        let scene = SCNScene()
        
        // Create a cube
        let boxGeometry = SCNBox(width: 0.5, height: 0.5, length: 0.5, chamferRadius: 0.05)
        
        // Create materials for each face with different colors
        let materials = [
            createMaterial(color: .red),
            createMaterial(color: .green),
            createMaterial(color: .blue),
            createMaterial(color: .yellow),
            createMaterial(color: .cyan),
            createMaterial(color: .magenta)
        ]
        
        boxGeometry.materials = materials
        
        // Create a node with the box geometry
        let cubeNode = SCNNode(geometry: boxGeometry)
        cubeNode.name = "cube"
        
        // Add the cube to the scene
        scene.rootNode.addChildNode(cubeNode)
        
        // Add a grid floor for reference
        let floor = SCNFloor()
        floor.reflectivity = 0.2
        let floorMaterial = SCNMaterial()
        floorMaterial.diffuse.contents = createGridImage()
        floor.materials = [floorMaterial]
        
        let floorNode = SCNNode(geometry: floor)
        floorNode.position = SCNVector3(0, -0.5, 0)
        scene.rootNode.addChildNode(floorNode)
        
        // Add axes for reference
        addAxes(to: scene.rootNode)
        
        return scene
    }
    
    private func createMaterial(color: NSColor) -> SCNMaterial {
        let material = SCNMaterial()
        material.diffuse.contents = color
        material.specular.contents = NSColor.white
        material.shininess = 0.7
        return material
    }
    
    private func createGridImage() -> NSImage {
        let size = CGSize(width: 512, height: 512)
        let image = NSImage(size: size)
        
        image.lockFocus()
        
        // Fill with light color
        NSColor.lightGray.withAlphaComponent(0.2).setFill()
        NSRect(origin: .zero, size: size).fill()
        
        // Draw grid lines
        NSColor.darkGray.withAlphaComponent(0.5).setStroke()
        
        let bezierPath = NSBezierPath()
        bezierPath.lineWidth = 1.0
        
        let gridSize: CGFloat = 50
        
        for i in 0...Int(size.width / gridSize) {
            let x = CGFloat(i) * gridSize
            bezierPath.move(to: NSPoint(x: x, y: 0))
            bezierPath.line(to: NSPoint(x: x, y: size.height))
        }
        
        for i in 0...Int(size.height / gridSize) {
            let y = CGFloat(i) * gridSize
            bezierPath.move(to: NSPoint(x: 0, y: y))
            bezierPath.line(to: NSPoint(x: size.width, y: y))
        }
        
        bezierPath.stroke()
        
        image.unlockFocus()
        
        return image
    }
    
    private func addAxes(to node: SCNNode) {
        let axisLength: CGFloat = 1.0
        let axisThickness: CGFloat = 0.01
        
        // X-axis (red)
        let xAxis = SCNCylinder(radius: axisThickness, height: axisLength)
        xAxis.materials = [createMaterial(color: .red)]
        let xAxisNode = SCNNode(geometry: xAxis)
        xAxisNode.position = SCNVector3(axisLength/2, 0, 0)
        xAxisNode.eulerAngles = SCNVector3(0, 0, -Float.pi/2)
        
        // Y-axis (green)
        let yAxis = SCNCylinder(radius: axisThickness, height: axisLength)
        yAxis.materials = [createMaterial(color: .green)]
        let yAxisNode = SCNNode(geometry: yAxis)
        yAxisNode.position = SCNVector3(0, axisLength/2, 0)
        
        // Z-axis (blue)
        let zAxis = SCNCylinder(radius: axisThickness, height: axisLength)
        zAxis.materials = [createMaterial(color: .blue)]
        let zAxisNode = SCNNode(geometry: zAxis)
        zAxisNode.position = SCNVector3(0, 0, axisLength/2)
        zAxisNode.eulerAngles = SCNVector3(Float.pi/2, 0, 0)
        
        let axesNode = SCNNode()
        axesNode.addChildNode(xAxisNode)
        axesNode.addChildNode(yAxisNode)
        axesNode.addChildNode(zAxisNode)
        
        node.addChildNode(axesNode)
    }
}
#endif
