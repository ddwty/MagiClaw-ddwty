//
//  SwiftDataModel.swift
//  talkWithRpi
//
//  Created by Tianyu on 7/26/24.
//
#if os(iOS)
import Foundation
import SwiftData


@Model
class TestNew {
    var name: String
    init(name: String) {
        self.name = name
    }
}





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


extension AllStorgeData {
    static let sampleData: [AllStorgeData] = [
        AllStorgeData(createTime: Date(), timeDuration: 0, notes: "" ),
        AllStorgeData(createTime: Date(), timeDuration: 0, notes: ""),
        AllStorgeData(createTime: Date(), timeDuration: 0, notes: "")
        ]
}
#endif
