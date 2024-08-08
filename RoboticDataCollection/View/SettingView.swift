//
//  SettingView.swift
//  talkWithRpi
//
//  Created by Tianyu on 7/22/24.
//

import SwiftUI

struct SettingView: View {
    @AppStorage("ignore websocket") private var ignorWebsocket = false
    @EnvironmentObject  var arRecorder: ARRecorder
    @EnvironmentObject var websocketManager: WebSocketManager
    @AppStorage("hostname") private var hostname = "raspberrypi.local"
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Toggle(isOn: $ignorWebsocket) {
                        Label("ignore websocket", systemImage: "network.slash")
                    }
                }
                Section(header: Text("Hostname:")) {
                    TextField("Hostname", text: $hostname)
                }
//                    .textFieldStyle(RoundedBorderTextFieldStyle())
//                    .focused($arRecorder.isFocused)
            }
            .navigationTitle("Settings")
        }
       
        
        
    }
}

#Preview {
    SettingView()
        .environmentObject(ARRecorder.shared)
        .environmentObject(WebSocketManager.shared)
}

