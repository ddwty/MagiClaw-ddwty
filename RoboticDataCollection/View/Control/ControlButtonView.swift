//
//  ControlButtonView.swift
//  MagiClaw
//
//  Created by Tianyu on 11/18/24.
//

import SwiftUI
import Combine
import simd

// MARK: - Constants
struct JoystickConstants {
    static let maxDistance: CGFloat = 100 // 这里保留原有常量，但我们将动态计算最大移动范围
    static let leftJoystickSize: CGFloat = 150
    static let rightJoystickSize: CGFloat = 150
    static let handleSizeRatio: CGFloat = 0.3 // 摇杆柄大小比例
    static let tickCount: Int = 4 // 改为4，用于四个方向箭头
}


// MARK: - 左侧双轴摇杆视图
struct LeftJoystickView: View {
    @GestureState private var dragOffset: CGSize = .zero
    @Binding var position: CGSize
    let size: CGFloat
    let color: Color
    
    var body: some View {
        ZStack {
            // 背景圆
            Circle()
                .fill(color.opacity(0.3))
                .frame(width: size, height: size)
                .overlay(
                    // 添加四个方向的箭头
                    VStack {
                        Image(systemName: "arrow.up")
                            .foregroundColor(color)
                        Spacer()
                        Image(systemName: "arrow.down")
                            .foregroundColor(color)
                    }
                    .frame(width: size, height: size)
                    .overlay(
                        HStack {
                            Image(systemName: "arrow.left")
                                .foregroundColor(color)
                            Spacer()
                            Image(systemName: "arrow.right")
                                .foregroundColor(color)
                        }
                    )
                )
            
            // 摇杆柄
            Circle()
                .fill(color)
                .frame(width: size * JoystickConstants.handleSizeRatio, height: size * JoystickConstants.handleSizeRatio)
                .offset(x: position.width, y: position.height)
                .shadow(radius: 4)
                .animation(.easeOut(duration: 0.2), value: position)
        }
        .gesture(
            DragGesture()
                .updating($dragOffset) { value, state, _ in
                    let translation = value.translation
                    let handleRadius = size * JoystickConstants.handleSizeRatio / 2
                    let maxMovement = (size / 2) - handleRadius
                    var newX = translation.width
                    var newY = translation.height
                    
                    // 限制在圆形范围内
                    let distance = sqrt(newX * newX + newY * newY)
                    if distance > maxMovement {
                        let angle = atan2(newY, newX)
                        newX = maxMovement * cos(angle)
                        newY = maxMovement * sin(angle)
                    }
                    state = CGSize(width: newX, height: newY)
                    position = state
                }
                .onEnded { _ in
                    withAnimation(.easeOut(duration: 0.2)) {
                        position = .zero
                    }
                }
        )
    }
}

// MARK: - 右侧单轴摇杆视图
struct RightJoystickView: View {
    @GestureState private var dragOffset: CGSize = .zero
    @Binding var position: CGSize
    let size: CGFloat
    let color: Color
    
    var body: some View {
        ZStack {
            // 背景圆
            Circle()
                .fill(color.opacity(0.3))
                .frame(width: size, height: size)
                .overlay(
                    VStack {
                        Image(systemName: "arrow.up")
                            .foregroundColor(color)
                        Spacer()
                        Image(systemName: "arrow.down")
                            .foregroundColor(color)
                    }
                    .frame(width: size, height: size)
                )
            
            // 摇杆柄
            Circle()
                .fill(color)
                .frame(width: size * JoystickConstants.handleSizeRatio, height: size * JoystickConstants.handleSizeRatio)
                .offset(x: position.width, y: position.height)
                .shadow(radius: 4)
                .animation(.easeOut(duration: 0.2), value: position)
        }
        .gesture(
            DragGesture()
                .updating($dragOffset) { value, state, _ in
                    let translation = value.translation
                    let handleRadius = size * JoystickConstants.handleSizeRatio / 2
                    let maxMovement = (size / 2) - handleRadius
                    var newY = translation.height
                    
                    // 限制 Y 值在最大移动范围内
                    newY = min(max(newY, -maxMovement), maxMovement)
                    state = CGSize(width: 0, height: newY)
                    position = state
                }
                .onEnded { _ in
                    withAnimation(.easeOut(duration: 0.2)) {
                        position = .zero
                    }
                }
        )
    }
}


// MARK: - ViewModel

class GameControllerViewModel: ObservableObject {
    @Published var leftJoystickPosition: CGSize = .zero
    @Published var rightJoystickPosition: CGSize = .zero
    
    // Combine the joystick positions into a simd_float3
    var joystickData: AnyPublisher<simd_float3, Never> {
        Publishers.CombineLatest($leftJoystickPosition, $rightJoystickPosition)
            .map { left, right in
                let maxDistanceLeft = JoystickConstants.leftJoystickSize / 2 - (JoystickConstants.leftJoystickSize * JoystickConstants.handleSizeRatio / 2)
                let maxDistanceRight = JoystickConstants.rightJoystickSize / 2 - (JoystickConstants.rightJoystickSize * JoystickConstants.handleSizeRatio / 2)
                
                let x = Float(left.width / maxDistanceLeft) // 归一化到 -1.0 到 1.0
                let y = Float(left.height / maxDistanceLeft)
                let z = Float(right.height / maxDistanceRight)
                return simd_float3(x, y, z)
            }
            .eraseToAnyPublisher()
    }
}

// MARK: - GameControllerView
struct GameControllerView: View {
    @StateObject private var viewModel = GameControllerViewModel()
    @State private var joystickVector: simd_float3 = .zero
    
    var body: some View {
        ZStack {
            Color.black.edgesIgnoringSafeArea(.all)
            
            HStack {
                // 左侧双轴摇杆
                LeftJoystickView(
                    position: $viewModel.leftJoystickPosition,
                    size: JoystickConstants.leftJoystickSize,
                    color: .blue
                )
                .padding()
                
                Spacer()
                
                // 右侧单轴摇杆
                RightJoystickView(
                    position: $viewModel.rightJoystickPosition,
                    size: JoystickConstants.rightJoystickSize,
                    color: .green
                )
                .padding()
            }
        }
        .onReceive(viewModel.joystickData) { data in
            self.joystickVector = data
            // 在这里可以使用 joystickVector 来控制物体
            print("Joystick Data: \(joystickVector)")
        }
    }
}


// MARK: - Preview
struct GameControllerView_Previews: PreviewProvider {
    static var previews: some View {
        GameControllerView()
    }
}
