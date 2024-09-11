//
//  RemoteControlButton.swift
//  MagiClaw
//
//  Created by 吴天禹 on 2024/9/8.
//

import SwiftUI

struct RemoteControlButton: View {
    @ObservedObject var settingModel = SettingModel.shared
    @State private var isLocked = false
    var body: some View {
            VStack(alignment: .leading) {
                HStack {
                    Button {
                        let impactFeedbackGenerator = UIImpactFeedbackGenerator(style: .medium)
                        impactFeedbackGenerator.impactOccurred()
                        toggleLock()
                        withAnimation(.easeInOut(duration: 0.15)) {
                            settingModel.enableSendingData.toggle()
                        }
                    } label: {
                        HStack {
                            if settingModel.enableSendingData {
                                Label("Stop sending", systemImage: "wave.3.forward")
                                    .if(settingModel.enableSendingData) {
                                        $0.symbolEffect(.variableColor.iterative.dimInactiveLayers.nonReversing)
                                    }
                                    .labelStyle(ReverseLabelStyle())
                            } else {
                                Text("Enable sending data")
                            }
                        }
                        .padding()
                        .background(
                            .regularMaterial,
                            in: RoundedRectangle(cornerRadius: 10, style: .continuous)
                        )
                        .background(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .foregroundStyle(settingModel.enableSendingData ? Color.green.opacity(0.3) : Color.blue.opacity(0.3))
                        )
//                        .clipShape(Capsule())
                        
                    }
//                    .buttonStyle(.bordered)
                    .tint(settingModel.enableSendingData ? .green : .blue)
//                    .clipShape(Capsule())
//                    .controlSize(.large)
                    
                    
                    .onAppear {
                        // 当视图出现时，重置为默认方向
                        AppDelegate.orientationLock = .all
                    }
                }
            }
        
    }
}

extension RemoteControlButton {
    private func toggleLock() {
        let currentOrientation = UIDevice.current.orientation

        if isLocked {
            // 解除锁定
            AppDelegate.orientationLock = .all
        } else {
            // 锁定当前方向
            switch currentOrientation {
            case .portrait, .portraitUpsideDown:
                AppDelegate.orientationLock = .portrait
            case .landscapeLeft, .landscapeRight:
                AppDelegate.orientationLock = .landscape
            default:
                AppDelegate.orientationLock = .all
            }
        }

        // 触发屏幕旋转
//        UIViewController.attemptRotationToDeviceOrientation()
        // 更新支持的界面方向
           if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
               windowScene.keyWindow?.rootViewController?.setNeedsUpdateOfSupportedInterfaceOrientations()
           }
        isLocked.toggle()
    }
}


#Preview {
    RemoteControlButton()
}
