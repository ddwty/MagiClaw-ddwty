//
//  ForceView.swift
//  talkWithRpi
//
//  Created by Tianyu on 7/24/24.
//

import SwiftUI
import Charts
import SceneKit

struct ForceView: View {
    @EnvironmentObject var webSocketManager: WebSocketManager
    var body: some View {
        ForceBarChartView()
            .environmentObject(webSocketManager)
    }
}

#Preview() {
    TotalForceView()
        .environmentObject(WebSocketManager.shared)
}

struct ForceBarChartView: View {
    @EnvironmentObject var webSocketManager: WebSocketManager
    
    var body: some View {
        VStack {
            let latestForceData = webSocketManager.forceDataforShow?.forceData ?? [0, 0, 0]
            
            Chart {
                ForEach(0..<3, id: \.self) { index in
                    let forceValue = latestForceData[index]
                    BarMark(
                        x: .value("Direction", index),
                        y: .value("Force", forceValue)
                    )
                    .foregroundStyle(by: .value("Direction", index))
                    
                }
            }
            //            .chartXAxisLabel("Direction")
            .chartYAxisLabel("Force Value")
            .frame(width: 300, height: 300)
            .padding()
            .animation(.easeInOut(duration: 0.1), value: latestForceData)
            
        }
    }
}

struct TotalForceView: View {
    @EnvironmentObject var webSocketManager: WebSocketManager
    var body: some View {
        VStack {
            VStack(alignment: .leading) {
                Text("Force (N)")
                    .font(.headline)
//                    .fontWeight(.bold)
                    .multilineTextAlignment(.leading)
                    .lineLimit(1)
                Chart {
                    BarMark(
                        x: .value("Force", webSocketManager.totalForce),
                        y: .value("Value", "force")
                    )
                    .foregroundStyle(LinearGradient(
                        colors: [.green,.yellow, .orange, .red],
                        startPoint: .leading,
                        endPoint: .trailing
                    ))
                    .alignsMarkStylesWithPlotArea()
                    
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .chartYAxis(Visibility.hidden)
                .chartXScale(domain: 0...100)
                .chartXAxis {
                    AxisMarks() { _ in
                        AxisGridLine()
                            .foregroundStyle(Color.gray)
                        AxisTick(
                        )
                        .foregroundStyle(Color.gray)
                        AxisValueLabel()
                            .foregroundStyle(Color.primary)
                        
                    }
                    AxisMarks(
                        values: [0, 10, 20, 30, 40, 50, 60, 70, 80, 90, 100]
                    ) {
                        AxisGridLine()
                    }
                }
                .frame(height: 30)
            }
            .animation(.easeInOut(duration: 0.5), value: webSocketManager.totalForce)
            //                .padding()
        }
    }
}

func createArrow(color: UIColor, length: CGFloat) -> SCNNode {
    let arrowNode = SCNNode()
    
    // Cylinder part of the arrow (shaft)
    let cylinder = SCNCylinder(radius: 0.05, height: abs(length))
    cylinder.firstMaterial?.diffuse.contents = color
    let cylinderNode = SCNNode(geometry: cylinder)
    cylinderNode.position = SCNVector3(0, abs(length) / 2, 0)
    
    // Cone part of the arrow (head)
    let cone = SCNCone(topRadius: 0, bottomRadius: 0.1, height: 0.2)
    cone.firstMaterial?.diffuse.contents = color
    let coneNode = SCNNode(geometry: cone)
    coneNode.position = SCNVector3(0, abs(length) + 0.1, 0)
    
    // Combine cylinder and cone to form an arrow
    arrowNode.addChildNode(cylinderNode)
    arrowNode.addChildNode(coneNode)
    
    return arrowNode
}

//struct Force3DView: View {
//    @EnvironmentObject var webSocketManager: WebSocketManager
//    @State private var latestForceData: [CGFloat] = [0.1, 0.1, 0.1]
//
//    private let timer = Timer.publish(every: 1.0 / 30.0, on: .main, in: .common).autoconnect()
//    private let scene = SCNScene()
//    private let coordinateSystemNode = SCNNode()
//    private let xArrowNode = createArrow(color: .red, length: 0.1)
//    private let yArrowNode = createArrow(color: .green, length: 0.1)
//    private let zArrowNode = createArrow(color: .blue, length: 0.1)
//    private let cameraNode = SCNNode()
//
//    init() {
//        // Rotate the arrows to align with the coordinate axes
//        xArrowNode.eulerAngles = SCNVector3(0, 0, -Double.pi / 2)
//        zArrowNode.eulerAngles = SCNVector3(Double.pi / 2, 0, 0)
//
//        coordinateSystemNode.addChildNode(xArrowNode)
//        coordinateSystemNode.addChildNode(yArrowNode)
//        coordinateSystemNode.addChildNode(zArrowNode)
//
//        scene.rootNode.addChildNode(coordinateSystemNode)
//
//        // Setup camera node and constraints
//        let camera = SCNCamera()
//        cameraNode.camera = camera
//        cameraNode.position = SCNVector3(x: 3, y: 3, z: 3)
//        scene.rootNode.addChildNode(cameraNode)
//
//        let constraint = SCNLookAtConstraint(target: coordinateSystemNode)
//        constraint.isGimbalLockEnabled = true
//        cameraNode.constraints = [constraint]
//    }
//
//    var body: some View {
//        SceneView(
//            scene: scene,
//            options: [.allowsCameraControl, .autoenablesDefaultLighting]
//        )
//        .onReceive(timer) { _ in
//            if let forceData = webSocketManager.forceDataforShow?.forceData {
//                latestForceData = forceData.map { CGFloat($0) }
//                animateArrows()
//            }
//        }
//    }
//
//    private func animateArrows() {
//        let duration = 1.0 / 30.0
//
//        animateArrow(node: xArrowNode, newLength: latestForceData[0], duration: duration)
//        animateArrow(node: yArrowNode, newLength: latestForceData[1], duration: duration)
//        animateArrow(node: zArrowNode, newLength: latestForceData[2], duration: duration)
//    }
//
//    private func animateArrow(node: SCNNode, newLength: CGFloat, duration: TimeInterval) {
//        guard let cylinderNode = node.childNode(withName: "cylinder", recursively: false),
//              let coneNode = node.childNode(withName: "cone", recursively: false),
//              let cylinder = cylinderNode.geometry as? SCNCylinder,
//              let cone = coneNode.geometry as? SCNCone else {
//            return
//        }
//
//        let oldLength = CGFloat(cylinder.height)
//        let lengthChange = newLength - oldLength
//
//        let cylinderAction = SCNAction.customAction(duration: duration) { (node, elapsedTime) in
//            let progress = elapsedTime / CGFloat(duration)
//            let newHeight = oldLength + lengthChange * progress
//            cylinder.height = newHeight
//            cylinderNode.position = SCNVector3(0, newHeight / 2, 0)
//            coneNode.position = SCNVector3(0, newHeight + 0.1, 0)
//        }
//
//        cylinderNode.runAction(cylinderAction)
//    }
//}




struct Force3DView: View {
    @EnvironmentObject var webSocketManager: WebSocketManager
    @State private var latestForceData: [CGFloat] = [0.1, 0.1, 0.1]
    
    private let timer = Timer.publish(every: 1.0 / 30.0, on: .main, in: .common).autoconnect()
    private let scene = SCNScene()
    private let coordinateSystemNode = SCNNode()
    private let xArrowNode = createArrow(color: .red, length: 0.1)
    private let yArrowNode = createArrow(color: .green, length: 0.1)
    private let zArrowNode = createArrow(color: .blue, length: 0.1)
    private let cameraNode = SCNNode()
    
    init() {
        // Rotate the arrows to align with the coordinate axes
        xArrowNode.eulerAngles = SCNVector3(0, 0, -Double.pi / 2)
        zArrowNode.eulerAngles = SCNVector3(Double.pi / 2, 0, 0)
        
        coordinateSystemNode.addChildNode(xArrowNode)
        coordinateSystemNode.addChildNode(yArrowNode)
        coordinateSystemNode.addChildNode(zArrowNode)
        
        scene.rootNode.addChildNode(coordinateSystemNode)
        
        // Setup camera node and constraints
        let camera = SCNCamera()
        cameraNode.camera = camera
        cameraNode.position = SCNVector3(x: 3, y: 3, z: 3)
        scene.rootNode.addChildNode(cameraNode)
        
        let constraint = SCNLookAtConstraint(target: coordinateSystemNode)
        constraint.isGimbalLockEnabled = true
        cameraNode.constraints = [constraint]
    }
    
    var body: some View {
        SceneView(
            scene: scene,
            options: [.allowsCameraControl, .autoenablesDefaultLighting]
        )
        .onReceive(timer) { _ in
            if let forceData = webSocketManager.forceDataforShow?.forceData {
                withAnimation(.easeInOut(duration: 1.0 / 30.0)) {
                    latestForceData = forceData.map { CGFloat($0) }
                    self.xArrowNode.scale.y = Float(latestForceData[0])
                    self.yArrowNode.scale.y = Float(latestForceData[1])
                    self.zArrowNode.scale.y = Float(latestForceData[2])
                }
            }
        }
    }
}
