//
//  SettingModel.swift
//  MagiClaw
//
//  Created by 吴天禹 on 2024/9/11.
//

import Foundation
import SwiftUI

class SettingModel: ObservableObject {
//    @Published var ignoreWebsocket = false
//    @Published var hostname = "raspberrypi.local"
//    @Published var selectedFrameRate: Int = 30
//    @Published var smoothDepth = true
    static let shared = SettingModel()
    private init() {}
    
    @Published var enableSendingData = false
    @AppStorage("saveZipFile") var saveZipFile = false
    @AppStorage("selectedFrameRate") var frameRate: Int = 30 // 默认帧率
    @AppStorage("smoothDepth") var smoothDepth = true
    @AppStorage("showWorldOrigin") var showWorldOrigin = false
    @AppStorage("position") var devicePosition = "Right"
}

