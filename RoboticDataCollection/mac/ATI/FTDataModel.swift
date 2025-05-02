//
//  FTDataModel.swift
//  MagiClaw
//
//  Created by Tianyu on 4/19/25.
//

import Foundation

struct FTDataPoint: Identifiable {
    let id = UUID()
    let timestamp: Date
    let value: Double
    let type: String
}
