//
//  RoboticDataCollectionApp.swift
//  RoboticDataCollection
//
//  Created by 吴天禹 on 2024/7/27.
//

import SwiftUI
import SwiftData

@main
struct MagiClawApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @State private var recordAllDataModel = RecordAllDataModel()
    @State var webSocketManager = WebSocketManager.shared
//    @StateObject var tcpServerManager = TCPServerManager(port: 8080)
    @StateObject var poseRGBWebsocketServer = WebSocketServerManager(port: 8080)
    
//    @StateObject var audioWebsocketServer = WebSocketServerManager(port: 8081)
    @Environment(\.scenePhase) private var scenePhase // 用于监控应用的生命周期阶段
    @AppStorage("hostname") private var hostname = "raspberrypi.local"
    @AppStorage("firstLaunch") private var isFirstLaunch = true
    
   
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(recordAllDataModel)
                .environment(webSocketManager)
                .environmentObject(ARRecorder.shared)
//                .environmentObject(tcpServerManager)
                .environmentObject(poseRGBWebsocketServer)
//                .environmentObject(audioWebsocketServer)
                .modelContainer(for: AllStorgeData.self)
            
                .tint(Color("tintColor"))
//                .modelContainer(container)
                
        }
//        .accentColor(.red)
       
        .onChange(of: scenePhase) { old, newPhase in
            switch newPhase {
            case .background, .inactive:
                webSocketManager.disconnect()
                print("WebSocket disconnected.")
            case .active:
                // 应用回到前台时
                webSocketManager.reConnectToServer()
                print("WebSocket reconnected.")
            default:
                break
            }
        }
    }
}


