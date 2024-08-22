//
//  Extensions.swift
//  RoboticDataCollection
//
//  Created by 吴天禹 on 2024/8/19.
//

import Foundation
import Accelerate
import ARKit

extension simd_float4x4 {
    var description: String {
        return """
        [\(columns.0.x), \(columns.0.y), \(columns.0.z), \(columns.0.w)]
        [\(columns.1.x), \(columns.1.y), \(columns.1.z), \(columns.1.w)]
        [\(columns.2.x), \(columns.2.y), \(columns.2.z), \(columns.2.w)]
        [\(columns.3.x), \(columns.3.y), \(columns.3.z), \(columns.3.w)]
        """
    }
    
    // 提取平移量
        var translation: simd_float3 {
            return simd_float3(columns.3.x, columns.3.y, columns.3.z)
        }
        
        // 提取四元数
        var quaternion: simd_quatf {
            // 从4x4矩阵中提取3x3旋转矩阵
            let rotationMatrix = simd_float3x3(
                columns.0.xyz,  // 提取第一列的前三个元素
                columns.1.xyz,  // 提取第二列的前三个元素
                columns.2.xyz   // 提取第三列的前三个元素
            )
            return simd_quatf(rotationMatrix)
        }
        
        // 转换为JSON字符串
        func toJSONString() -> String? {
            let quaternion = self.quaternion
            let translation = self.translation
            
            let dict: [String: Any] = [
                "quaternion": [
                    "x": quaternion.vector.x,
                    "y": quaternion.vector.y,
                    "z": quaternion.vector.z,
                    "w": quaternion.vector.w
                ],
                "translation": [
                    "x": translation.x,
                    "y": translation.y,
                    "z": translation.z
                ]
            ]
            
            if let jsonData = try? JSONSerialization.data(withJSONObject: dict, options: .prettyPrinted) {
                return String(data: jsonData, encoding: .utf8)
            }
            
            return nil
        }
    
       
}

extension simd_float4 {
    var xyz: simd_float3 {
        return simd_float3(self.x, self.y, self.z)
    }
}
