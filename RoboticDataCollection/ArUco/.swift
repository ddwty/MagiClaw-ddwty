//
//  ArucoCVWrapper.swift
//  MagiClaw
//
//  Created by Tianyu on 9/30/24.
//
import Foundation
import CoreVideo
import CoreGraphics

class ArucoCVWrapper {
    private let arucoCV = ArucoCV()
    
    // 检测标记，返回标记的角点和 ID
    func detect(pixelBuffer: CVPixelBuffer) -> ([[CGPoint]], [Int]) {
        let cornersObjC: NSMutableArray<NSArray<NSValue *> *> = []
        let idsObjC: NSMutableArray<NSNumber *> = []
        
        arucoCV.detectCorners(cornersObjC, ids: idsObjC, pixelBuffer: pixelBuffer)
        
        var corners: [[CGPoint]] = []
        for markerCorners in cornersObjC {
            let cgPoints = markerCorners.compactMap { ($0 as? NSValue)?.cgPointValue }
            corners.append(cgPoints)
        }
        
        let ids = idsObjC.compactMap { $0.intValue }
        
        return (corners, ids)
    }
}
