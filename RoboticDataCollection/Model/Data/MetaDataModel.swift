//
//  MetaDataModel.swift
//  MagiClaw
//
//  Created by Tianyu on 9/15/24.
//

import Foundation

struct MetaData: Codable {
    
    var fileUUID: String
    var userID: String?

    var createTime: String
    var timeDuration: TimeInterval
    var description: String
    var scenario: String
    var leftForceDataSize: Int
    var rightForceDataSize: Int
    var angleDataSize: Int
    var ARDataSize: Int
    
    var deviceModel: String
    var systemName: String
    var systemVersion: String
    var appVersion: String
    
    init(fileUUID: String, userID: String?, createTime: String, timeDuration: TimeInterval, description: String, scenario: String, leftForceDataSize: Int, rightForceDataSize: Int, angleDataSize: Int, ARDataSize: Int, deviceModel: String, systemName: String,  systemVersion: String, appVersion: String) {
        self.fileUUID = fileUUID
        self.userID = userID
        self.createTime = createTime
        self.timeDuration = timeDuration
        self.description = description
        self.scenario = scenario
        self.leftForceDataSize = leftForceDataSize
        self.rightForceDataSize = rightForceDataSize
        self.angleDataSize = angleDataSize
        self.ARDataSize = ARDataSize
        self.deviceModel = deviceModel
        self.systemName = systemName
        self.systemVersion = systemVersion
        self.appVersion = appVersion
    }
}
