//
//  SwiftDataModel.swift
//  talkWithRpi
//
//  Created by Tianyu on 7/26/24.
//

import Foundation
import SwiftData


@Model
class TestNew {
    var name: String
    init(name: String) {
        self.name = name
    }
}



@Model
class AllStorgeData {
    var createTime: Date
    var timeDuration: TimeInterval
    var notes: String
    var scenario: Scenario
    
    var unsortedForceData: [ForceData]
    var unsortedRightForceData: [ForceData]
    var unsortedAngleData: [AngleData]
    var unsortedARData: [ARData]
    
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
         scenario: Scenario,
         forceData unsortedForceData: [ForceData],
         rightForceData unsortedRightForceData: [ForceData]? = nil,
         angleData unsortedAngleData: [AngleData],
         aRData unsortedARData: [ARData]
    ){
        self.createTime = createTime
        self.timeDuration = timeDuration
        self.notes = notes
//        self.scenarioString = scenario.rawValue
        self.scenario = scenario
        self.unsortedForceData = unsortedForceData
        self.unsortedRightForceData = unsortedRightForceData ?? [defaultForceData] // 在这里设置默认值
        self.unsortedAngleData = unsortedAngleData
        self.unsortedARData = unsortedARData
    }
    
}

extension AllStorgeData: Identifiable {}

//enum StoredDataSchemaV1: VersionedSchema {
//    static var versionIdentifier: Schema.Version = Schema.Version.init(1, 0, 0)
//    
//    static var models: [any PersistentModel.Type] {
//        return [AllStorgeData.self, ForceData.self, AngleData.self, ARData.self]
//    }
//    
//    
//    
//}

let defaultForceData = ForceData(timeStamp: 0.0000, forceData: [0,0,0,0,0,0])
