//
//  StatusCard.swift
//  MagiClaw
//
//  Created by Tianyu on 9/14/24.
//

import SwiftUI


struct StatusCard: View {
    @Environment(\.verticalSizeClass) var verticalSizeClass
    @Binding var showPopover: Bool
    var clawAngle: ClawAngleManager
    var body: some View {
        if verticalSizeClass == .regular {
            VStack(alignment: .leading) {
                HStack {
                    Text("Status")
                        .font(.title3)
                        .fontWeight(.bold)
                    Spacer()
                    RaspberryPiView(showPopover: $showPopover)
                }
                
                Divider()
                HStack {
                    TotalForceView(leftOrRight: "L")
                        .padding(.trailing)
                    Spacer()
                    
                    TotalForceView(leftOrRight: "R")
                }
                Divider()
//                AngleView()
                Text("Opening range: " + String(format: "%.3f", clawAngle.ClawAngleDataforShow?.angle ?? 0))
                    .font(.headline)
            }
            .cardBackground()
            
        } else {
            VStack(alignment: .center) {
                HStack {
                    Spacer()
                    Text("Status")
                        .font(.title3)
                        .fontWeight(.bold)
                    RaspberryPiView(showPopover: $showPopover)
                }
                Divider()
                HStack {
                    TotalForceView(leftOrRight: "L")
                    //                                        .frame(width: screenHeight * 0.3)
                        .frame(minWidth: 200)
                    Spacer()
                    Text("Opening range \n" + String(format: "%.3f", clawAngle.ClawAngleDataforShow?.angle ?? 0))
                        .font(.headline)
                        .frame(width: 140)
                    Spacer()
                    TotalForceView(leftOrRight: "R")
                    //                                        .frame(width: screenHeight * 0.3)
                        .frame(minWidth: 200)
                }
            }
            .cardBackground()
        }
    }
}

#Preview {
    StatusCard(showPopover: .constant(false), clawAngle: ClawAngleManager.shared)
        .environment(WebSocketManager.shared)
        .environmentObject(ARRecorder.shared)
        .environmentObject(WebSocketServerManager(port: 8080))
}
