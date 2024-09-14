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
                AngleView()
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
                    AngleView()
                        .frame(width: 120)
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

//#Preview {
//    StatusCard()
//}
