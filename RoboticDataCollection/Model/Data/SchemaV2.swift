//
//  SchemaV2.swift
//  MagiClaw
//
//  Created by 吴天禹 on 2024/9/12.
//
#if os(iOS)
import Foundation
import SwiftData
import SwiftUI

enum SchemaV2: VersionedSchema {
    static var versionIdentifier = Schema.Version(1, 1, 0)
    
    static var models: [any PersistentModel.Type] {
        [AllStorgeData.self, Scenario.self] // 只保留AllStorgeData也可以
    }
}

extension SchemaV2 {
    
    @Model
    class AllStorgeData: Identifiable {
        var createTime: Date
        var timeDuration: TimeInterval
        var notes: String
    //    var scenario: Scenario
        
        @Relationship(inverse: \Scenario.allData) var scenario: Scenario?
        
        var leftForceCount: Int
        var rightForceCount: Int
        var angleDataCount: Int
        var ARDataCount: Int
        
        init(createTime: Date,
             timeDuration: TimeInterval,
             notes: String,
    //         scenario: Scenario,
             leftForceCount: Int = 0,
             rightForceCount: Int = 0,
             angleDataCount: Int = 0,
             ARDataCount: Int = 0
        ){
            self.createTime = createTime
            self.timeDuration = timeDuration
            self.notes = notes
    //        self.scenario = scenario
            self.leftForceCount = leftForceCount
            self.rightForceCount = rightForceCount
            self.angleDataCount = angleDataCount
            self.ARDataCount = ARDataCount
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
#endif
