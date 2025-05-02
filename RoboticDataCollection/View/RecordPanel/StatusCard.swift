//
//  StatusCard.swift
//  MagiClaw
//
//  Created by Tianyu on 9/14/24.
//
#if os(iOS)
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
//                if let angle = clawAngle.ClawAngleDataforShow {
//                    Text("Opening range: " + String(format: "%.3f", angle))
//                        .font(.headline)
//                } else {
//                    Text("No detected marker")
//                        .font(.headline)
//                }
                Text("Opening range: " + String(format: "%.3f", 0.32))
                    .font(.headline)
                    .frame(minWidth: 80)
                   
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
//                    if let angle = clawAngle.ClawAngleDataforShow {
//                        Text("Opening range: " + String(format: "%.3f", angle))
//                            .font(.headline)
//                            .frame(minWidth: 80)
//                        
//                    } else {
//                        Text("No detected marker")
//                            .font(.headline)
//                            .frame(minWidth: 80)
//                    }
                    Text("Opening range: " + String(format: "%.3f", 0.32))
                        .font(.headline)
                        .frame(minWidth: 80)
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
#endif
