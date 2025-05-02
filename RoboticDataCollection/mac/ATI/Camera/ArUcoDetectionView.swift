//
//  ArUcoDetectionView.swift
//  MagiClaw
//
//  Created by Tianyu on 4/21/25.
//

import SwiftUI
import SceneKit

#if os(macOS)
struct ArUcoDetectionView: View {
    var transforms: [SKWorldTransform]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("ArUco Markers Detected: \(transforms.count)")
                .font(.headline)
                .padding(.bottom, 4)
            
            if transforms.isEmpty {
                Text("No markers detected")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        ForEach(transforms, id: \.arucoId) { transform in
                            MarkerInfoView(transform: transform)
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color.white.opacity(0.05))
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
        )
    }
}

struct MarkerInfoView: View {
    var transform: SKWorldTransform
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Marker ID: \(transform.arucoId)")
                .font(.headline)
                .foregroundColor(.blue)
            
            // 位置信息
            HStack {
                Text("Position:")
                    .fontWeight(.medium)
                
                Text(String(format: "X: %.2f, Y: %.2f, Z: %.2f",
                            transform.transform.columns.3.x,
                            transform.transform.columns.3.y,
                            transform.transform.columns.3.z))
                    .foregroundColor(.secondary)
            }
            
            // 旋转信息 (简化显示)
            Text("Rotation Matrix:")
                .fontWeight(.medium)
            
            Grid(alignment: .leading, horizontalSpacing: 10, verticalSpacing: 4) {
                ForEach(0..<3) { row in
                    GridRow {
                        ForEach(0..<3) { col in
                            Text(String(format: "%.2f", getMatrixValue(transform.transform, row: row, col: col)))
                                .monospacedDigit()
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .padding(.leading, 8)
            
            Divider()
        }
        .padding(10)
        .background(Color.blue.opacity(0.05))
        .cornerRadius(8)
    }
    
    private func getMatrixValue(_ matrix: simd_float4x4, row: Int, col: Int) -> Float {
        switch col {
        case 0: return matrix.columns.0[row]
        case 1: return matrix.columns.1[row]
        case 2: return matrix.columns.2[row]
        default: return 0
        }
    }
}
#endif 