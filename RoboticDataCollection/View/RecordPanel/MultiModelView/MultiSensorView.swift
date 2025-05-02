//
//  MultiSensorView.swift
//  MagiClaw
//
//  Created by Tianyu on 10/7/24.
//
#if os(iOS)
import SwiftUI

struct MultiSensorView: View {
    var poseMatrix: [Float]
    // 定义 4 列的网格布局
    let columns = Array(repeating: GridItem(.flexible(), spacing: 1), count: 4)
    var body: some View {
        NavigationStack {
            ScrollView {
                poseMatrixView
                    .padding()
                ForceChart(leftOrRight: "L")
                
            }
//            .padding()
            .navigationBarTitle("Raw data", displayMode: .inline)
            .background(Material.regular)
            
        }
    }
    
    private var poseMatrixView: some View {
        VStack(alignment: .leading) {
            HStack {
                Text("Pose matrix")
                    .font(.title3)
                    .fontWeight(.bold)
                Spacer()
            }
            Divider()
            LazyVGrid(columns: columns, spacing: 10) {
                ForEach(0..<poseMatrix.count, id: \.self) { index in
                    Text(String(format: "%.3f", poseMatrix[index]))  // 显示浮点数，格式化保留4位小数
                        .frame(width: 70, height: 30)
                        .cornerRadius(5)
                        .overlay(
                            RoundedRectangle(cornerRadius: 5)
                                .stroke(Color.secondary.opacity(0.8), lineWidth: 1)
                        )
                        .multilineTextAlignment(.center)
                }
            }
        }
        .cardBackground()
//        .background(Color.white)
        
    }
}

#Preview {
    MultiSensorView(poseMatrix: [0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15])
        .environment(RecordAllDataModel())
        .environment(WebSocketManager.shared)
        .environmentObject(ARRecorder.shared)
        .environmentObject(WebSocketServerManager(port: 8080))
}
#endif
