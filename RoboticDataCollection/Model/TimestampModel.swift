//
//  TimestampModel.swift
//  MagiClaw
//
//  Created by Tianyu on 10/9/24.
//

import Foundation

class TimestampModel {
    static let shared = TimestampModel()
    private init() {}
    
    private(set) var startTime: Date?
    private(set) var isRecording = false
    
    func startRecording() {
        guard !isRecording else { return }
        startTime = Date()
        isRecording = true
    }
    
    func stopRecording() {
        isRecording = false
    }
    
    func resetStartTime() {
        startTime = nil
    }
    
    func getElapsedTime() -> TimeInterval? {
        guard let startTime = startTime else { return nil }
        return Date().timeIntervalSince(startTime)
    }
}
