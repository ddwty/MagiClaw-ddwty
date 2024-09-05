//
//  ContentView.swift
//  talkWithRpi
//
//  Created by Tianyu on 7/13/24.
//


import SwiftUI
import SwiftData

struct ContentView: View {
   
    @Environment(\.modelContext) private var modelContext
    @AppStorage("firstLaunch") private var isFirstLaunch = true
    var body: some View {
        TabView {
            PanelView()
                .onTapGesture {
                hideKeyboard()
            }
               
            .tabItem {
                Label("Panel", systemImage: "camera" )
            }
            HistoryView()
                .tabItem {
                    Label("History",systemImage: "clock")
                }
            SettingView()
                .tabItem {
                    Label("Settings",systemImage: "gear")
                }
        }
        // 首次进入创建scenario例子
        .onAppear {
            if isFirstLaunch {
                modelContext.insert(Scenario.unspecifiedScenario)
                let array = Scenario.sampleScenario
                    array.forEach { example in
                        modelContext.insert(example)
                    }
                self.isFirstLaunch = false
            }
        }
        
    }
}

#Preview() {
    ContentView()
            .environment(RecordAllDataModel())
            .environment(WebSocketManager.shared)
            .environmentObject(ARRecorder.shared)
            .modelContainer(previewContainer)
    
}
