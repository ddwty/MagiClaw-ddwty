//
//  StoreTempDataModel.swift
//  RoboticDataCollection
//
//  Created by 吴天禹 on 2024/8/16.
// 用来存放一条记录的数据，使用单例，能够让其他类，
// 比如recordedAllDataModel访问到刚录制的数据，
// 充当recordedAllDataModel与WebSocketManager的桥梁，
// 这样WebSocketManager就不需要使用单例模式了

import Foundation
class StoreTempDataModel {
    static let shared = StoreTempDataModel()
    private init() {}
    var recordedForceData: [ForceData] = []  //用于储存
    var recordedAngleData: [AngleData] = []
}
