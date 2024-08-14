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
       
        return container
    } catch {
        fatalError("Failed to create container")
    }
}()

struct SampleDeck {
    static var contents: [AllStorgeData] = [
        AllStorgeData(createTime: Date(), timeDuration: 10, notes: "Default description", scenario: .bathroom,forceData: [], angleData: [], aRData: []),
        AllStorgeData(createTime: Date(), timeDuration: 10, notes: "Default description", scenario: .bedroom , forceData: [], angleData: [], aRData: []),
        AllStorgeData(createTime: Date(), timeDuration: 10, notes: "Default description", scenario: .livingRoom , forceData: [], angleData: [], aRData: [])
    ]
}
