//
//  RemoteControlButton.swift
//  MagiClaw
//
//  Created by 吴天禹 on 2024/9/8.
//

import SwiftUI

struct RemoteControlButton: View {
    @ObservedObject var remoteControlManager = RemoteControlManager.shared
    @State private var isLocked = false
    var body: some View {
            VStack(alignment: .leading) {
               
                
               
//                HStack {
//                    Button {
//                        let impactFeedbackGenerator = UIImpactFeedbackGenerator(style: .medium)
//                        impactFeedbackGenerator.impactOccurred()
//                        toggleLock()
//                        withAnimation(.easeInOut(duration: 0.15)) {
//                            remoteControlManager.enableSendingData.toggle()
//                        }
//                    } label: {
//                        HStack {
//                            if remoteControlManager.enableSendingData {
//                                Label("Stop sending", systemImage: "wave.3.forward")
//                                    .if(remoteControlManager.enableSendingData) {
//                                        $0.symbolEffect(.variableColor.iterative.dimInactiveLayers.nonReversing)
//                                    }
//                                    .labelStyle(ReverseLabelStyle())
//                            } else {
//                                Text("Enable sending data")
//                            }
//                        }
//                        .padding()
//                        
//                        .background(
//                            RoundedRectangle(cornerRadius: 10, style: .continuous)
//                                .foregroundStyle(remoteControlManager.enableSendingData ? Color.green : Color.blue)
//                        )
////                        .clipShape(Capsule())
//                        
//                    }
////                    .buttonStyle(.bordered)
//                    .tint(remoteControlManager.enableSendingData ? .green : .white)
////                    .clipShape(Capsule())
////                    .controlSize(.large)
//                    
//                    .onAppear {
//                        // 当视图出现时，重置为默认方向
//                        AppDelegate.orientationLock = .all
//                    }
//                }
            }
        
    }
}

extension RemoteControlButton {
    
}


#Preview {
    RemoteControlButton()
}
