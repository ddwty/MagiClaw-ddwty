//
//  RemotePanel.swift
//  MagiClaw
//
//  Created by 吴天禹 on 2024/9/8.
//
#if os(iOS)
import SwiftUI

struct VisualizationView: View {
    @Environment(\.verticalSizeClass) var verticalSizeClass
    @Environment(\.dismiss) var dismiss
//    @StateObject var poseRGBWebsocketServer = WebSocketServerManager(port: 8080)
//    @ObservedObject var audioWebSocketServer: WebSocketServerManager
    @State var clawAngle = ClawAngleManager.shared
    
    let screenWidth = UIScreen.main.bounds.size.width
    let screenHeight = UIScreen.main.bounds.size.height
    @State private var tabBarVisible: Bool = false
    @State private var dragOffset = CGSize.zero // 存储当前拖动中的偏移量
    @State var showFullView: Bool = true
    @State var flashLightOn: Bool = false
//    @State var remoteControlManager = RemoteControlManager.shared
    @State private var showDepthView: Bool = false // 修改为枚举类型
    @State private var showViewModeMenu: Bool = false // 控制菜单显示
    @State private var minDepth: Float = 0.0
    @State private var maxDepth: Float = 5.0
    @State private var isFirstAppear = true
    
    // 修改视图模式枚举，只保留 sideBySide
    enum ARViewMode: String, CaseIterable, Identifiable {
        case sideBySide = "Side by Side"
        
        var id: String { self.rawValue }
        
        var iconName: String {
            return "rectangle.split.2x1"
        }
    }
    
    var body: some View {
        ZStack {
            ZStack {
                VisualizationARView(
                             minDepth: $minDepth,
                             maxDepth: $maxDepth)
                    .ignoresSafeArea(edges: [.bottom])
              
                    // exitButton
//                    HStack {
//                        Spacer()
//                        VStack {
//                            exitButton()
//                            Spacer()
//                          
//                        }
//                        .padding(.trailing)
//                    }
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
           
            .onAppear {
                // 当视图出现时，设置为横屏
                AppDelegate.orientationLock = .landscapeRight
                
                // 强制旋转到横屏
                if isFirstAppear {
                    isFirstAppear = false
                    
                    // 使用 UIDevice 强制旋转
                    if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
                        if #available(iOS 16.0, *) {
                            windowScene.requestGeometryUpdate(.iOS(interfaceOrientations: .landscape))
                        } else {
                            UIDevice.current.setValue(UIInterfaceOrientation.landscapeRight.rawValue, forKey: "orientation")
                        }
                        UIViewController.attemptRotationToDeviceOrientation()
                    }
                }
            }
            .onDisappear {
                // 当视图消失时，恢复为所有方向
                AppDelegate.orientationLock = .all
                
                // 延迟一小段时间后尝试恢复到竖屏
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
                        if #available(iOS 16.0, *) {
                            windowScene.requestGeometryUpdate(.iOS(interfaceOrientations: .portrait))
                        } else {
                            UIDevice.current.setValue(UIInterfaceOrientation.portrait.rawValue, forKey: "orientation")
                        }
                        UIViewController.attemptRotationToDeviceOrientation()
                    }
                }
            }
            
//            // 添加深度信息视图
//            if viewMode != .rgb {
//                DepthInfoView(minDepth: minDepth, maxDepth: maxDepth)
//                    .frame(maxWidth: 300)
//                    .padding(.horizontal)
//                    .padding(.top, 40)
//                    .animation(.easeInOut, value: viewMode)
//                    .transition(.opacity)
//            }
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
        Button(action: {
            dismiss()
        }) {
            Image(systemName: "xmark")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.white)
                .frame(width: 36, height: 36)
                .background(Color.black.opacity(0.6))
                .clipShape(Circle())
        }
        .padding()
        .shadow(color: Color.black.opacity(0.15), radius: 10)
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
    func settingButton() -> some View {
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
        
    }
}

// 添加 DepthInfoView 结构体
struct DepthInfoView: View {
    var minDepth: Float
    var maxDepth: Float
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 8) {
                // 最小深度标签
                HStack(spacing: 4) {
                    Circle()
                        .fill(Color.red)
                        .frame(width: 10, height: 10)
                    Text(String(format: "Min: %.2f m", minDepth))
                        .font(.system(size: 14, weight: .semibold, design: .monospaced))
                        .foregroundColor(.primary)
                }
                
                Spacer()
                
                // 最大深度标签
                HStack(spacing: 4) {
                    Text(String(format: "Max: %.2f m", maxDepth))
                        .font(.system(size: 14, weight: .semibold, design: .monospaced))
                        .foregroundColor(.primary)
                    Circle()
                        .fill(Color.blue)
                        .frame(width: 10, height: 10)
                }
            }
            
            // 深度范围条
            ZStack(alignment: .leading) {
                Rectangle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [.red, .orange, .yellow, .green, .blue]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(height: 6)
                    .cornerRadius(3)
            }
        }
        .padding(8)
        .background(Material.thickMaterial)
        .cornerRadius(10)
    }
}

#endif
