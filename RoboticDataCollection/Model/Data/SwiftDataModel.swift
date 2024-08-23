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
//    var scenario: Scenario
    
    @Relationship(inverse: \Scenario2.allData) var scenario: Scenario2?
    
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
//let defaultRightForceData = RightForceData(timeStamp: 0.00, forceData: [0, 0, 0, 0, 0, 0])
