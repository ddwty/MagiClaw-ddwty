//
//  Extensions.swift
//  RoboticDataCollection
//
//  Created by 吴天禹 on 2024/8/19.
//
#if os(iOS)
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
            columns.0.xyz,
            columns.1.xyz,
            columns.2.xyz
        )
        return simd_quatf(rotationMatrix)
    }
    
    
    func toJSONString() -> String? {
        let quaternion = self.quaternion
        let translation = self.translation
        
        let poseDict: [String: Any] = [
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
        
        if let jsonData = try? JSONSerialization.data(withJSONObject: poseDict, options: .prettyPrinted) {
            var jsonString = String(data: jsonData, encoding: .utf8)
            jsonString?.append("\n")
            return jsonString
        }
        
        return nil
    }
    
    func getTranslationAndQuaternion() -> [Float] {
        let quaternionX = Float(self.quaternion.vector.x)
        let quaternionY = Float(self.quaternion.vector.y)
        let quaternionZ = Float(self.quaternion.vector.z)
        let quaternionW = Float(self.quaternion.vector.w)
        
        let translationX = Float(self.translation.x)
        let translationY = Float(self.translation.y)
        let translationZ = Float(self.translation.z)
        
        
        return [quaternionX, quaternionY, quaternionZ, quaternionW, translationX, translationY, translationZ]
    }
    
    func getPoseMatrix() -> [Float] {
        return [Float(columns.0.x), Float(columns.0.y), Float(columns.0.z), Float(columns.0.w),
                Float(columns.1.x), Float(columns.1.y), Float(columns.1.z), Float(columns.1.w),
                Float(columns.2.x), Float(columns.2.y), Float(columns.2.z), Float(columns.2.w),
                Float(columns.3.x), Float(columns.3.y), Float(columns.3.z), Float(columns.3.w)]
    }
    
}

extension simd_float4 {
    var xyz: simd_float3 {
        return simd_float3(self.x, self.y, self.z)
    }
}
#endif
