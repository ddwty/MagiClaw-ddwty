//
//  AngleView.swift
//  RoboticDataCollection
//
//  Created by Tianyu on 8/8/24.
//

import SwiftUI
import Combine

struct AngleView: View {
    @Environment(WebSocketManager.self) private var webSocketManager
    
    @State private var displayedAngle: Int = 0
    @State private var timer: Timer?
    private var updateInterval: TimeInterval = 1/20
    
    var body: some View {
        VStack(alignment: .leading) {
            // Text displaying the angle
            Text("Angle: \(displayedAngle)°")
                .font(.headline)
        }
        
        .onAppear {
            // 创建定时器
            timer = Timer.scheduledTimer(withTimeInterval: updateInterval, repeats: true) { _ in
                displayedAngle = webSocketManager.angleDataforShow
            }
        }
        .onDisappear {
            // 视图消失时取消定时器
            timer?.invalidate()
            timer = nil
        }
    }
}

//#Preview {
//    AngleView()
//        .environmentObject(WebSocketManager.shared)
//}
