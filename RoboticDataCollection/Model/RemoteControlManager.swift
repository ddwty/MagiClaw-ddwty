//
//  RemoteControlManager.swift
//  MagiClaw
//
//  Created by Tianyu on 9/15/24.
//

import Foundation
@Observable
class RemoteControlManager{
    static let shared = RemoteControlManager()
    private init() {}
    
    var enableSendingData = false
    var enableStreamingAudio = false
}
