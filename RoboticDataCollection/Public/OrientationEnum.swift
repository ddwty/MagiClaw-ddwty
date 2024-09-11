//
//  OrientationEnum.swift
//  MagiClaw
//
//  Created by 吴天禹 on 2024/9/10.
//

import SwiftUI

// 用于强制锁定Remote视图的方向
enum Orientation: Int, CaseIterable {
    case landscapeLeft
    case landscapeRight
    case portrait
    
    var title: String {
        switch self {
        case .landscapeLeft:
            return "LandscapeLeft"
        case .landscapeRight:
            return "LandscapeRight"
        case .portrait:
            return "Portrait"
        }
    }
    
    var mask: UIInterfaceOrientationMask {
        switch self {
        case .landscapeLeft:
            return .landscapeLeft
        case .landscapeRight:
            return .landscapeRight
        case .portrait:
            return .portrait
        }
    }
    
    var portraitMask: UIInterfaceOrientationMask {
        return .portrait
    }
}
