//
//  RoboticDataCollectionApp.swift
//  RoboticDataCollection
//
//  Created by 吴天禹 on 2024/7/27.
//

import SwiftUI
import SwiftData

@main
struct RoboticDataCollectionApp: App {
    @StateObject private var recordAllDataModel = RecordAllDataModel()
      
           
       var body: some Scene {
           WindowGroup {
               ContentView()
                   .environmentObject(MotionManager.shared)
                   .environmentObject(recordAllDataModel)
   //                .environmentObject(CameraManager.shared)
                   .environmentObject(WebSocketManager.shared)
                   .environmentObject(ARRecorder.shared)
                   .modelContainer(for: ARStorgeData.self)
               
           }
       }

}
