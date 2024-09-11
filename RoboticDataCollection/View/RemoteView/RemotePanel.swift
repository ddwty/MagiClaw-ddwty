//
//  RemotePanel.swift
//  MagiClaw
//
//  Created by 吴天禹 on 2024/9/8.
//

import SwiftUI

struct RemotePanel: View {
    @Environment(\.verticalSizeClass) var verticalSizeClass
    @Environment(\.dismiss) var dismiss
//    @Binding var visibility: Visibility
    @State var showBigAr = false
    
    let screenWidth = UIScreen.main.bounds.size.width
    let screenHeight = UIScreen.main.bounds.size.height
    @State private var tabBarVisible: Bool = false
    @State private var dragOffset = CGSize.zero // 存储当前拖动中的偏移量

    
    var body: some View {
        ZStack {
            RemoteARView()
                .ignoresSafeArea(edges: [.bottom])
//                .ignoresSafeArea()
                VStack {
                        HStack {
                            Spacer()
                           
                            
                            VStack { // Close button
                                HStack {
                                    Spacer()
                                    Button(action: {
                                        dismiss()
                                    }) {
                                        Text("")
                                    }
                                    .padding()
                                    .shadow(color: Color.gray.opacity(0.6), radius: 10)
                                    .buttonStyle(ExitButtonStyle())
                                    
                                }
                                Spacer()
                            }
                        }
                    Spacer()
                    RemoteControlButton()
                        .padding()
                }
        }
        .offset(y: dragOffset.height) // 应用偏移量
        .gesture(
            DragGesture()
                .onChanged { gesture in
                    // 实时更新拖动的偏移量，只允许向下拖动
                    if gesture.translation.height > 0 {
                        self.dragOffset = gesture.translation
                    }
                }
                .onEnded { _ in
                    // dissmiss
                    if self.dragOffset.height > 100 {
                        dismiss()
                    }
                    self.dragOffset = .zero
                }
        )
        .animation(.easeInOut(duration: 0.3), value: dragOffset)
        
    }
}

#Preview {
    RemotePanel()
        .environment(RecordAllDataModel())
        .environment(WebSocketManager.shared)
        .environmentObject(ARRecorder.shared)
        .environmentObject(WebSocketServerManager(port: 8080))
}
