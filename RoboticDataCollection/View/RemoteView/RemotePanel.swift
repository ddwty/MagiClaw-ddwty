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
    @ObservedObject var audioWebSocketServer: WebSocketServerManager
    
    let screenWidth = UIScreen.main.bounds.size.width
    let screenHeight = UIScreen.main.bounds.size.height
    @State private var tabBarVisible: Bool = false
    @State private var dragOffset = CGSize.zero // 存储当前拖动中的偏移量
    @State var showFullView: Bool = false
    @State var flashLightOn: Bool = false
    
    var body: some View {
        ZStack {
            ZStack {
                RemoteARView()
//                    .ignoresSafeArea(edges: [.bottom])
                    .aspectRatio(verticalSizeClass == .regular ? 3/4 : 4/3, contentMode: .fit)
                
                //            #if DEBUG
                //                Image("fakeRemoteView")
                //                    .resizable()
                //                    .aspectRatio(contentMode: .fill)
                //                    .offset(x: 200)
                //                    .ignoresSafeArea(edges: .bottom)
                //            #endif
                
               
                exitButton()
                if verticalSizeClass == .regular {
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            flashLightButton()
                            Button(action : {
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    self.showFullView.toggle()
                                }
                            }) {
                                Image(systemName: "switch.2")
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 30, height: 30)
                                    .padding()
                                    .foregroundStyle(Color.primary.opacity(0.3))
                                    .background(.regularMaterial)
                                    .clipShape(RoundedRectangle(cornerRadius: 15, style: .continuous))
                                    .shadow(color: Color.black.opacity(0.15), radius: 5, x: 0, y: 2)
                                    .animation(.easeInOut(duration: 0.3), value: showFullView)
                            }
                            .padding(.horizontal)
                            .padding(.bottom)
                        }
                    }
                } else  {
                    HStack {
                        Spacer()
                        VStack {
                            Spacer()
                            flashLightButton()
                            Button(action : {
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    self.showFullView.toggle()
                                }
                            }) {
                                Image(systemName: "switch.2")
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 30, height: 30)
                                    .padding()
                                    .foregroundStyle(Color.primary.opacity(0.3))
                                    .background(.regularMaterial)
                                    .clipShape(RoundedRectangle(cornerRadius: 15, style: .continuous))
                                    .shadow(color: Color.black.opacity(0.15), radius: 5, x: 0, y: 2)
                                    .animation(.easeInOut(duration: 0.3), value: showFullView)
                            }
                            .padding(.horizontal)
                            .padding(.bottom)
                        }
                    }
                    
                }
                if showFullView {
                    GeometryReader { geo in
                        HStack {
                            Spacer()
                            VStack {
                                Spacer()
                                RemoteControlCard(audioWebsocketServer: self.audioWebSocketServer, showFullPanel: $showFullView)
                                    .padding()
                                    .frame(width:
                                            UIDevice.current.userInterfaceIdiom == .phone ?
                                           (verticalSizeClass == .regular ? nil : geo.size.width * 0.6) :
                                            geo.size.width * 0.5
                                    )
                                Spacer()
                            }
                            Spacer()
                        }
                    }
//                                        .transition(.move(edge: .bottom))
                    .transition(.asymmetric( insertion: .move(edge: .bottom).combined(with: .opacity),
                                                removal: .move(edge: .bottom).combined(with: .opacity)
                                            ))
                    .zIndex(1)
                }
            } //: ZStack
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
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color("background"))
        .onTapGesture {
            if showFullView {
                withAnimation(.easeInOut(duration: 0.3)) {
                    showFullView = false
                }
            }
        }
        .persistentSystemOverlays(.hidden)
        
        
    }
    
    func exitButton() -> some View {
        VStack { // Close button
            HStack {
                Spacer()
                Button(action: {
                    dismiss()
                }) {
                    Text("")
                }
                .padding()
                .shadow(color: Color.black.opacity(0.15), radius: 10)
                .buttonStyle(ExitButtonStyle())
                
            }
            Spacer()
            Spacer()
        }
    }
    
    func flashLightButton() -> some View {
                Button(action: {
                    self.flashLightOn.toggle()
                    let impactFeedbackGenerator = UIImpactFeedbackGenerator(style: .medium)
                    impactFeedbackGenerator.impactOccurred()
                    toggleTorch(on: flashLightOn)
                    
                }) {
                    Image(systemName: self.flashLightOn ? "flashlight.on.fill" : "flashlight.off.fill")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 30, height: 30)
                        .foregroundColor(self.flashLightOn ? Color.yellow : Color.primary.opacity(0.3))
                        .padding()
                        .background(.regularMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 15, style: .continuous))
                        .shadow(color: Color.black.opacity(0.15), radius: 5, x: 0, y: 2)
                        
                }
                .padding()
        
    }
}

#Preview {
    RemotePanel(audioWebSocketServer: WebSocketServerManager(port: 8081))
        .environment(RecordAllDataModel())
        .environment(WebSocketManager.shared)
        .environmentObject(ARRecorder.shared)
        .environmentObject(WebSocketServerManager(port: 8080))
}

