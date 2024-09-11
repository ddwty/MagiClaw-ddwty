//
//  SettingView.swift
//  talkWithRpi
//
//  Created by Tianyu on 7/22/24.
//

import SwiftUI
import MessageUI

struct SettingView: View {
    @AppStorage("ignore websocket") private var ignorWebsocket = false
    @EnvironmentObject  var arRecorder: ARRecorder
    @Environment(WebSocketManager.self) private var webSocketManager
    @AppStorage("hostname") private var hostname = "raspberrypi.local"
    @AppStorage("selectedFrameRate") var selectedFrameRate: Int = 30
    @AppStorage("smoothDepth") private var smoothDepth = true
//    @State var enableSendingData = false
    @ObservedObject var settingModel = SettingModel.shared
    
    
    let availableFrameRates = [30, 60] // 可以选择的帧率选项
    
    @State private var showMailComposer = false
    @State private var showMailErrorAlert = false
    @State private var isShowingMailView = false
    @State private var showInfo = false
   
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Recording")) {
                    Toggle(isOn: $ignorWebsocket) {
                        VStack(alignment: .leading) {
                            Text("Ignore Raspberry Pi connection")
                            Text("Record without a Raspberry PI connected")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                
                    Toggle(isOn: $smoothDepth) {
                        VStack(alignment: .leading) {
                            Text("Smooth depth")
                            Text("Minimize the difference in LiDAR readings across frames")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                       
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
                    
                    Toggle(isOn: $settingModel.saveZipFile) {
                        VStack(alignment: .leading) {
                            Text("Zip data files")
                            Text("Reduce storage space usage")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                   
                    
                    NavigationLink(destination: NewScenarioView()) {
                        Text("Scenario")
                    }
                }
                Section(header: Text("Connection")) {
                    HStack {
                        VStack(alignment: .leading) {
                            Text("Hostname")
                            Text("Enter Raspberry Pi's hostname")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        TextField("Enter hostname", text: $hostname)
                            .keyboardType(.URL) // 设置键盘类型为URL
                            .textContentType(.URL)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled(true)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .padding(5)
                            
                            .onChange(of: hostname) { oldValue, newValue in
                                // 防止hostname被设置为空
                                guard !newValue.isEmpty else { return }
                                webSocketManager.setHostname(hostname: newValue)
                                webSocketManager.reConnectToServer()
                            }
                    }
                    
                    Toggle(isOn: $settingModel.enableSendingData) {
                        VStack(alignment: .leading) {
                            Text("Enable sending data")
                            Text("Send data via websocket on port 8080")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    
                    
                    HStack {
                        Text("IP Address")
                        Spacer()
                        IPView()
                        
                    }
                }
                Section() {
                    Button(action: {
                        self.showInfo.toggle()
                    }, label: {
                        Label("About", systemImage: "info.circle")
                            .foregroundColor(.blue)
                            
                    })
                }
                
            }
            
            .navigationTitle("Settings")
            .sheet(isPresented: self.$showInfo) {
                InfoView(isShowingMailView: self.$isShowingMailView)
            }
        }
    }
}



#Preview {
    SettingView(settingModel: SettingModel.shared)
        .environmentObject(ARRecorder.shared)
        .environment(WebSocketManager.shared)
    
}

class SettingModel: ObservableObject {
//    @Published var ignoreWebsocket = false
//    @Published var hostname = "raspberrypi.local"
//    @Published var selectedFrameRate: Int = 30
//    @Published var smoothDepth = true
    static let shared = SettingModel()
    private init() {}
    
    @Published var enableSendingData = false
    @AppStorage("saveZipFile") var saveZipFile = false
}
