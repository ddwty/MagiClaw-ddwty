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
    @AppStorage("selectedFrameRate") var selectedFrameRate: Int = 60

    let availableFrameRates = [30, 60] // 可以选择的帧率选项
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
                Section(header: Text("Frame Rate:")) {
                    Picker("Frame Rate", selection: $selectedFrameRate) {
                        ForEach(availableFrameRates, id: \.self) { rate in
                            Text("\(rate) FPS").tag(rate)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
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

