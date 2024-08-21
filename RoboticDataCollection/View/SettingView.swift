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
    @Environment(WebSocketManager.self) private var webSocketManager
    @AppStorage("hostname") private var hostname = "raspberrypi.local"
    @AppStorage("selectedFrameRate") var selectedFrameRate: Int = 30
    
    let availableFrameRates = [30, 60] // 可以选择的帧率选项
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("General")) {
                    Toggle(isOn: $ignorWebsocket) {
                        Text("Ignore Raspberry Pi connection")
                    }
                    
                    HStack {
                        Text("Frame Rate")
                        Spacer()
                        Picker("Frame Rate", selection: $selectedFrameRate) {
                            ForEach(availableFrameRates, id: \.self) { rate in
                                Text("\(rate) FPS").tag(rate)
                            }
                        }
                        .pickerStyle(SegmentedPickerStyle())
                    }
                }
                Section() {
                    HStack {
                                            Text("Hostname:")
                                            TextField("Enter hostname", text: $hostname)
                                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                                .padding(5)
                                        }
                    NavigationLink(destination: IPView()) {
//                            Label("Show IP Address", systemImage: "network")
                        Text("iPhone's IP Address")
                        
                    }
                }
//                    .textFieldStyle(RoundedBorderTextFieldStyle())
//                    .focused($arRecorder.isFocused)
                Section(header: Text("Frame Rate:")) {
                   
                }
            }
            .navigationTitle("Settings")
        }
    }
}


#Preview {
    SettingView()
        .environmentObject(ARRecorder.shared)
        .environment(WebSocketManager.shared)
}

