//
//  SwiftDataModel.swift
//  talkWithRpi
//
//  Created by Tianyu on 7/26/24.
//

import Foundation
import SwiftData

@Model
// 代表每一次录制的这条AR data
class ARStorgeData {
    var createTime: Date
    var timeDuration: TimeInterval
    var unsortedData: [ARData]
    var data: [ARData] {
        return unsortedData.sorted { $0.timestamp < $1.timestamp }
    }
    
    
    init(createTime: Date, timeDuration: TimeInterval, originalData unsortedData: [ARData]) {
        self.createTime = createTime
        self.timeDuration = timeDuration
        self.unsortedData = unsortedData
        
    }
}

extension ARStorgeData: Identifiable {}


@Model 
class AllStorgeData {
    var createTime: Date
    var timeDuration: TimeInterval
    var notes: String
    var scenario: Scenario
   
    var unsortedForceData: [ForceData]
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
         angleData unsortedAngleData: [AngleData],
         aRData unsortedARData: [ARData]
    ){
        self.createTime = createTime
        self.timeDuration = timeDuration
        self.notes = notes
//        self.scenarioString = scenario.rawValue
        self.scenario = scenario
        self.unsortedForceData = unsortedForceData
        self.unsortedAngleData = unsortedAngleData
        self.unsortedARData = unsortedARData
    }
    
}

extension AllStorgeData: Identifiable {}
