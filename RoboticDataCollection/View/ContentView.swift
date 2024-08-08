//
//  ContentView.swift
//  talkWithRpi
//
//  Created by Tianyu on 7/13/24.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            PanelView()
                .onTapGesture {
                hideKeyboard()
            }
            .tabItem {
                Label("Panel", systemImage: "record.circle" )
            }
            HistoryView()
                .tabItem {
                    Label("History",systemImage: "clock")
                }
            SettingView()
                .tabItem {
                    Label("Settings",systemImage: "gear")
                }
            MyARView()
                .tabItem {
                    Label("AR",systemImage: "arkit")
                }
        }
    }
}

#Preview() {
    ContentView()
//        .environmentObject(MotionManager.shared)
        .environmentObject(RecordAllDataModel())
        .environmentObject(WebSocketManager.shared)
        .environmentObject(ARRecorder.shared)
        .modelContainer(previewContainer)
}
