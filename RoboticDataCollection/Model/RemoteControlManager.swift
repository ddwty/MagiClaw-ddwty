//
//  RemoteControlManager.swift
//  MagiClaw
//
//  Created by Tianyu on 9/15/24.
//

import Foundation
class RemoteControlManager: ObservableObject {
    static let shared = RemoteControlManager()
    private init() {}
    
    @Published var enableSendingData = false
    @Published var enableStreamingAudio = false
}
