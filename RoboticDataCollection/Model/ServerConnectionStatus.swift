//
//  ServerConnectionStatus.swift
//  MagiClaw
//
//  Created by Tianyu on 9/15/24.
//

import Foundation
import ARKit

@Observable
class ServerConnectionStatus {
    static let shared = ServerConnectionStatus()
    private init() {}
    
    var isSendingDataServerReady = false
    var isStreamingAudioServerReady = false
    
    var sendDataClientID: [Int] = []
    var audioStreamClientID: [Int] = []
}

@Observable
class ARTrackingStatus {
    static let shared = ARTrackingStatus()
    private init() {}
    
    var isLimited = false
    var reason: ARCamera.TrackingState.Reason?
    
}
