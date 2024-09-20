//
//  PreviewSampleData.swift
//  talkWithRpi
//
//  Created by Tianyu on 7/27/24.
//

import SwiftData
import Foundation
import simd

@MainActor
let previewContainer: ModelContainer = {
    do {
        let container = try ModelContainer(
            for: AllStorgeData.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        for data in SampleDeck.contents{
            container.mainContext.insert(data)
        }
//        for data in Scenario.sampleScenario {
//            container.mainContext.insert(data)
//        }
       
        return container
    } catch {
        fatalError("Failed to create container")
    }
}()

struct SampleDeck {
    static var contents: [AllStorgeData] = [
        AllStorgeData(createTime: Date(), timeDuration: 10.4, notes: "Default description", leftForceCount: 100, rightForceCount: 100, angleDataCount: 243, ARDataCount: 34),
        AllStorgeData(createTime: Date(), timeDuration: 22.2, notes: "Default description", leftForceCount: 10, rightForceCount: 10, angleDataCount: 10, ARDataCount: 10),
        AllStorgeData(createTime: Date(), timeDuration: 24.6, notes: "Default description", leftForceCount: 10, rightForceCount: 10, angleDataCount: 10, ARDataCount: 10)
    ]
}

func generateSampleData() -> [AllStorgeData] {
    let sampleData: [AllStorgeData] = [
        AllStorgeData(createTime: Date(), timeDuration: 10.4, notes: "Test data 1", leftForceCount: 120, rightForceCount: 110, angleDataCount: 243, ARDataCount: 34),
        AllStorgeData(createTime: Date().addingTimeInterval(-3600), timeDuration: 15.2, notes: "Testing in kitchen", leftForceCount: 150, rightForceCount: 140, angleDataCount: 200, ARDataCount: 50),
        AllStorgeData(createTime: Date().addingTimeInterval(-7200), timeDuration: 9.8, notes: "Living Room Data", leftForceCount: 130, rightForceCount: 105, angleDataCount: 180, ARDataCount: 60),
        AllStorgeData(createTime: Date().addingTimeInterval(-10800), timeDuration: 12.0, notes: "Outdoor test", leftForceCount: 90, rightForceCount: 95, angleDataCount: 210, ARDataCount: 55),
        AllStorgeData(createTime: Date().addingTimeInterval(-14400), timeDuration: 11.3, notes: "Office environment", leftForceCount: 115, rightForceCount: 120, angleDataCount: 230, ARDataCount: 70)
    ]
    
    
    sampleData[0].scenario = Scenario.sampleScenario[0]
    sampleData[1].scenario = Scenario.sampleScenario[3]
    sampleData[2].scenario = Scenario.sampleScenario[1]
    sampleData[3].scenario = Scenario.sampleScenario[4]
    sampleData[4].scenario = Scenario.sampleScenario[5]
    return sampleData
}
