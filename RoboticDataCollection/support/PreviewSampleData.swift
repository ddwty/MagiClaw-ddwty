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
            for: ARStorgeData.self,
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
    static var contents: [ARStorgeData] = [
        ARStorgeData(
            createTime: Date(),
            timeDuration: 1.2,
            data: [ARData(timestamp: 20, transform: simd_float4x4(1))]
        ),
        ARStorgeData(
            createTime: Date().addingTimeInterval(-3600),
            timeDuration: 3.3,
            data: [ARData(timestamp: 30, transform: simd_float4x4(2))]
        )
    ]
}
