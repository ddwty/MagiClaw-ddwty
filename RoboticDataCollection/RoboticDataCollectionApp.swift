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
    @State private var recordAllDataModel = RecordAllDataModel()
    @State var webSocketManager = WebSocketManager.shared
//    @State var selectedScenario = SelectedScenario()
    
       var body: some Scene {
           WindowGroup {
               ContentView()
                   .environment(recordAllDataModel)
                   .environment(webSocketManager)
                   .environmentObject(ARRecorder.shared)
                   .modelContainer(for: AllStorgeData.self)
           }
       }
}

extension View {
    func hideKeyboard() {
        let resign = #selector(UIResponder.resignFirstResponder)
        UIApplication.shared.sendAction(resign, to: nil, from: nil, for: nil)
    }
}
