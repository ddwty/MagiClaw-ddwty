//
//  SwiftDataModel.swift
//  talkWithRpi
//
//  Created by Tianyu on 7/26/24.
//

import Foundation
import SwiftData
//
//@Model class RecordingHistory: Identifiable {
//    @Attribute var id: UUID = UUID()
//    @Attribute var date: Date
//    @Attribute var fileURL: URL
//    @Attribute var duration: TimeInterval
//    @Attribute var frameDataJSON: String
//    
//    init(date: Date, fileURL: URL, duration: TimeInterval, frameDataArray: [ARFrameData]) {
//        self.date = date
//        self.fileURL = fileURL
//        self.duration = duration
//        self.frameDataJSON = try! JSONEncoder().encode(frameDataArray).toString()
//    }
//    
//    var frameDataArray: [ARFrameData] {
//        get {
//            return try! JSONDecoder().decode([ARFrameData].self, from: frameDataJSON.data(using: .utf8)!)
//        }
//        set {
//            frameDataJSON = try! JSONEncoder().encode(newValue).toString()
//        }
//    }
//}
//
//extension Data {
//    func toString() -> String {
//        return String(data: self, encoding: .utf8)!
//    }
//}


@Model
// 代表每一次录制的这条AR data
class ARStorgeData {
    var createTime: Date
    var timeDuration: TimeInterval
    var data: [ARData]
    
    
    init(createTime: Date, timeDuration: TimeInterval, data: [ARData]) {
        self.createTime = createTime
        self.timeDuration = timeDuration
        self.data = data
    }
}

extension ARStorgeData: Identifiable {}
