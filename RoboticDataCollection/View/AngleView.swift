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
        Text("Angle: \(webSocketManager.angleDataforShow?.angle ?? 0)°")
            .font(.headline)
    }
}

#Preview {
    AngleView()
        .environmentObject(WebSocketManager.shared)
}
