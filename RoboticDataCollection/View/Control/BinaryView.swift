//
//  BinaryView.swift
//  MagiClawClient
//
//  Created by Tianyu on 9/21/24.
//

import SwiftUI


struct BinaryView: View {
    let controlWebsocket: ControlWebsocket
    
    // 定义 4 列的网格布局
    let columns = Array(repeating: GridItem(.flexible(), spacing: 10), count: 4)
    
    var body: some View {
        VStack {
//            Text("Received Binary Data")
//                .font(.largeTitle)
//                .fontWeight(.bold)
//                .padding(.top)
//           
//            Text(String(format: "%.4f", controlWebsocket.receivedAngle))
            
            // 显示 Pose 矩阵
//            if !controlWebsocket.receivedPose.isEmpty {
//                VStack(alignment: .leading) {
//                    Text("Pose Matrix (4x4)")
//                        .font(.headline)
//                        .padding(.bottom, 10)
//                    
//                    LazyVGrid(columns: columns, spacing: 10) {
//                        ForEach(0..<controlWebsocket.receivedPose.count, id: \.self) { index in
//                            Text(String(format: "%.4f", controlWebsocket.receivedPose[index]))  // 显示浮点数，格式化保留4位小数
//                                .frame(width: 70, height: 30)
//                                .background(Color.gray.opacity(0.2))
//                                .cornerRadius(5)
//                                .overlay(
//                                    RoundedRectangle(cornerRadius: 5)
//                                        .stroke(Color.blue.opacity(0.8), lineWidth: 1)
//                                )
//                                .multilineTextAlignment(.center)
//                        }
//                    }
//                    .padding()
//                    .cornerRadius(10)
//                    .shadow(radius: 5)
//                }
//                .padding([.leading, .trailing], 20)
//            }
            
           
            HStack {
                if let image = controlWebsocket.receivedImage, controlWebsocket.isConnected {
                    VStack {
                        Text("Received Image")
                            .font(.headline)
                        
                        GeometryReader { geometry in
                            HStack {
                                Image(uiImage: image)
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(maxWidth: geometry.size.width * 0.9)
                                    .cornerRadius(15)
                            }
                        }
                        .padding()
                    }
                    .cornerRadius(15)
                    .shadow(radius: 5)
                    .padding([.leading, .trailing], 20)
                } else {
                    Text("No image received")
                        .foregroundColor(.gray)
                }
            }
        }
        .frame(height: 200)
    }
}



#Preview {
    BinaryView(controlWebsocket: ControlWebsocket())
}
