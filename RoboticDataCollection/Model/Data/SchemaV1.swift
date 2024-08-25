//
//  SchemaV1.swift
//  MagiClaw
//
//  Created by 吴天禹 on 2024/8/24.
//

import Foundation
import SwiftData
import SwiftUI

enum SchemaV1: VersionedSchema {
    static var versionIdentifier = Schema.Version(1, 0, 0)
    
    static var models: [any PersistentModel.Type] {
        [AllStorgeData.self, Scenario.self] // 只保留AllStorgeData也可以
    }
}

extension SchemaV1 {
    
    @Model
    class AllStorgeData: Identifiable {
        var createTime: Date
        var timeDuration: TimeInterval
        var notes: String
    //    var scenario: Scenario
        
        @Relationship(inverse: \Scenario.allData) var scenario: Scenario?
        
        @Relationship(deleteRule: .cascade)  var unsortedForceData: [ForceData]
    //    @Relationship(deleteRule: .cascade)  var unsortedRightForceData: [RightForceData]
        @Relationship(deleteRule: .cascade) var unsortedRightForceData: [ForceData]
        @Relationship(deleteRule: .cascade)  var unsortedAngleData: [AngleData]
        @Relationship(deleteRule: .cascade)  var unsortedARData: [ARData]
        
        // history导出csv用到
        var forceData: [ForceData] {
            return unsortedForceData.sorted { $0.timeStamp < $1.timeStamp }
        }
        var angleData: [AngleData] {
            return unsortedAngleData.sorted { $0.timeStamp < $1.timeStamp }
        }
        var arData: [ARData] {
            return unsortedARData.sorted { $0.timestamp < $1.timestamp }
        }
        
        init(createTime: Date,
             timeDuration: TimeInterval,
             notes: String,
    //         scenario: Scenario,
             forceData unsortedForceData: [ForceData],
             rightForceData unsortedRightForceData: [ForceData],
             
             angleData unsortedAngleData: [AngleData],
             aRData unsortedARData: [ARData]
        ){
            self.createTime = createTime
            self.timeDuration = timeDuration
            self.notes = notes
    //        self.scenario = scenario
            self.unsortedForceData = unsortedForceData
            self.unsortedRightForceData = unsortedRightForceData
            self.unsortedAngleData = unsortedAngleData
            self.unsortedARData = unsortedARData
        }
        
    }
    
    
    @Model
    class Scenario: Identifiable {
        @Attribute(.unique) var name: String
        var color: String
        var allData: [AllStorgeData]?
        
        init(name: String = "", color: String = "FF4500") {
            self.name = name
            self.color = color
        }
        
        var hexColor: Color {
            Color(hex: self.color) ?? .red
        }
    }
}
