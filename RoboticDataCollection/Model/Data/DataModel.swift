//
//  ForceDataModel.swift
//  talkWithRpi
//
//  Created by Tianyu on 7/23/24.
//

import Foundation
import ARKit
import simd
import SwiftData

//@Model
class ForceData {
    let timeStamp: Double
    let forceData:[Double]?
    
    init(timeStamp: Double, forceData: [Double]?) {
        self.timeStamp = timeStamp
        self.forceData = forceData
    }
}

//@Model
//class RightForceData {
//    let timeStamp: Double
//    let forceData:[Double]?
//    
//    init(timeStamp: Double, forceData: [Double]?) {
//        self.timeStamp = timeStamp
//        self.forceData = forceData
//    }
//}

//@Model // 暂时不储存这个了
//TODO: - 这里的时间戳应该是Double or Date
class AngleData {
    let timeStamp: Double
    let angle: Int
    
    init(timeStamp: Double, angle: Int) {
        self.timeStamp = timeStamp
        self.angle = angle
    }
}



//@Model
class ARData {
    var timestamp: Double  // 这一帧的时间戳
    var transform: [Float] // 使用数组来存储矩阵数据
    
    init(timestamp: Double, transform: simd_float4x4) {
        self.timestamp = timestamp
        self.transform = ARData.convertSimdToArray(transform)
    }
    
    static func convertSimdToArray(_ transform: simd_float4x4) -> [Float] {
        return [
            transform.columns.0.x, transform.columns.0.y, transform.columns.0.z, transform.columns.0.w,
            transform.columns.1.x, transform.columns.1.y, transform.columns.1.z, transform.columns.1.w,
            transform.columns.2.x, transform.columns.2.y, transform.columns.2.z, transform.columns.2.w,
            transform.columns.3.x, transform.columns.3.y, transform.columns.3.z, transform.columns.3.w
        ]
    }
    
    static func convertArrayToSimd(_ array: [Float]) -> simd_float4x4 {
        precondition(array.count == 16, "Array must contain exactly 16 elements")
        return simd_float4x4(
            simd_float4(array[0], array[1], array[2], array[3]),
            simd_float4(array[4], array[5], array[6], array[7]),
            simd_float4(array[8], array[9], array[10], array[11]),
            simd_float4(array[12], array[13], array[14], array[15])
        )
    }
}


protocol CSVConvertible {
    func csvHeader() -> String
    func csvRow() -> String
}

extension ARData: CSVConvertible {
    func csvHeader() -> String {
        return "Timestamp,Transform\n"
    }
    
    func csvRow() -> String {
        let transformString = transform.map { String($0) }.joined(separator: ",")
        return "\(timestamp),\(transformString)"
    }
}

extension ForceData: CSVConvertible {
    func csvHeader() -> String {
        return "Timestamp,ForceData\n"
    }
    
    func csvRow() -> String {
        let forceDataString = forceData?.map { String($0) }.joined(separator: ",") ?? ""
        return "\(timeStamp),\(forceDataString)"
    }
}

extension AngleData: CSVConvertible {
    func csvHeader() -> String {
        return "Timestamp,Angle\n"
    }
    
    func csvRow() -> String {
        return "\(timeStamp),\(angle)"
    }
}

extension ClawAngleData: CSVConvertible {
    func csvHeader() -> String {
        return "Timestamp,Angle\n"
    }
    
    func csvRow() -> String {
        return "\(timeStamp),\(angle)"
    }
}
//
//extension RightForceData: CSVConvertible {
//    func csvHeader() -> String {
//        return "Timestamp,ForceData\n"
//    }
//    
//    func csvRow() -> String {
//        let forceDataString = forceData?.map { String($0) }.joined(separator: ",") ?? ""
//        return "\(timeStamp),\(forceDataString)"
//    }
//}
