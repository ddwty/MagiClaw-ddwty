//
//  AngleView.swift
//  RoboticDataCollection
//
//  Created by Tianyu on 8/8/24.
//

import SwiftUI

struct AngleView: View {
    @EnvironmentObject var webSocketManager: WebSocketManager
    
    var body: some View {
        VStack {
            // Text displaying the angle
            Text("Angle: \(webSocketManager.angleDataforShow?.angle ?? 0)°")
                .font(.headline)
            
            // Visualization of the angle
//            ModernGripperView(angle: Double(webSocketManager.angleDataforShow?.angle ?? 40))
//                .frame(width: 150, height: 150)
//                .padding()
        }
    }
}

struct ModernGripperView: View {
    var angle: Double
    
    var body: some View {
        ZStack {
            // Background Circle
            Circle()
                .stroke(lineWidth: 10)
                .opacity(0.3)
                .foregroundColor(.gray)
            
            // Foreground Arc representing the gripper angle
            Arc(startAngle: .degrees(0), endAngle: .degrees(angle), clockwise: false)
                .stroke(Color.blue, lineWidth: 10)
                .animation(.easeInOut(duration: 0.5), value: angle)
        }
    }
}

struct Arc: Shape {
    var startAngle: Angle
    var endAngle: Angle
    var clockwise: Bool

    func path(in rect: CGRect) -> Path {
        let radius = rect.width / 2
        let center = CGPoint(x: rect.midX, y: rect.midY)
        var path = Path()
        path.addArc(center: center, radius: radius, startAngle: startAngle, endAngle: endAngle, clockwise: clockwise)
        return path
    }
}

#Preview {
    AngleView()
        .environmentObject(WebSocketManager.shared)
}
