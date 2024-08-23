//
//  ControlButtonView.swift
//  talkWithRpi
//
//  Created by Tianyu on 7/23/24.
//

import SwiftUI
import SwiftData
import UIKit

struct ControlButtonView: View {
    @Environment(RecordAllDataModel.self) var recordAllDataModel
    @Environment(WebSocketManager.self) private var webSocketManager
    @Environment(\.verticalSizeClass) var verticalSizeClass
    
    // 让UnSpecified排在最前面，剩下的按字母顺序排
    @Query private var storedScenarios: [Scenario2]
   
    @State var isSaved = false
    @State private var description = ""
//    @State private var scenario: Scenario = .unspecified
    
    @State private var newScenario: Scenario2?
  
   
    @FocusState private var isFocused: Bool
    
    var body: some View {
        if verticalSizeClass == .regular {
            GroupBox {
                VStack(alignment: .leading) {
                    Text("Control Panel")
                        .font(.title3)
                        .fontWeight(.bold)
                    Divider()
                    HStack {
                        Text("Select a scenario: ")
                        
                        // TODO: - 检查是否为空
                        Picker("Scenario", selection: $newScenario) {
//                            Text("")
//                                .tag(Optional<Scenario2>(nil))
                            
                            ForEach (storedScenarios.sorted {
                                if $0.name == "Unspecified" {
                                    return true
                                } else if $1.name == "Unspecified" {
                                    return false
                                } else {
                                    return $0.name.localizedCompare($1.name) == .orderedAscending
                                }
                            }, id: \.self) { scenario in
                                
                                Text(scenario.name.capitalized)
//
                                    .tag(Optional(scenario))
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                        // 传递给class，以用作文件名
                        .onChange(of: self.newScenario) { oldValue, newValue in
                            if let scenario = newValue {
                                recordAllDataModel.scenarioName = scenario.name
                            } else {
                                // 处理 newValue 为 nil 的情况
                                recordAllDataModel.scenarioName = ""
                            }
                        }
                    }
                    
                    TextField("Enter description", text: $description)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .focused($isFocused)
                        .keyboardType(.URL)
                           .textContentType(.URL)
                        .onChange(of: description) {oldValue, newValue in
                            recordAllDataModel.description = newValue
                        }
                        .disableAutocorrection(true)
                       
                    HStack {
                        Spacer()
                        StartRecordingButton(isSaved: self.$isSaved, description: self.$description, newScenario: self.$newScenario)
                        Spacer()
                    }
                }
            }
            .alert(
                "Recording completed.",
                isPresented: $isSaved
            ) {
                Button("OK") {
                }
            } message: {
//                Text("You have successfully recorded an action😁")
                Text("You have successfully recorded an action😁\n" +
                     "Left Force Data: \(self.recordAllDataModel.recordedForceData.count)\n" +
//                     "Right Force Data: \(self.recordAllDataModel.recordedRightForceData.count)\n" +
                     "Angle Data: \(self.recordAllDataModel.recordedAngleData.count)\n" +
                     "AR Data: \(self.recordAllDataModel.recordedARData.count)")
            }
        } else {
                GroupBox {
                    VStack(alignment: .leading, spacing: 0) {
                        Text("Control Panel")
                            .font(.title3)
                            .fontWeight(.bold)
                        Divider()
                        
                        HStack(alignment: .firstTextBaseline) {
                            VStack(alignment: .leading) {
                                Text("Description:")
                                    .alignmentGuide(.firstTextBaseline) { d in d[.firstTextBaseline] }
                                TextEditor(text: $description)
                                    .focused($isFocused)
                                    .onChange(of: description) {oldValue, newValue in
                                        recordAllDataModel.description = newValue
                                    }
                                    .disableAutocorrection(true)
                                    .frame(minWidth: 100, minHeight: 50)
                                    .keyboardType(.URL)
                                    .textContentType(.URL)
                            }
                            Spacer()
                            VStack(alignment: .leading) {
                                HStack {
                                    Text("Scenario:")
                                        .alignmentGuide(.firstTextBaseline) { d in d[.firstTextBaseline] }

                                    // TODO: - 检查是否为空
                                    Picker("Scenario", selection: $newScenario) {
                                        ForEach (storedScenarios.sorted {
                                            if $0.name == "Unspecified" {
                                                return true
                                            } else if $1.name == "Unspecified" {
                                                return false
                                            } else {
                                                return $0.name.localizedCompare($1.name) == .orderedAscending
                                            }
                                        }, id: \.self) { scenario in
                                            Text(scenario.name.capitalized)
//                                                .tag(Optional<Scenario2>(nil))
//                                                .tag(scenario as Scenario2?)
                                                .tag(Optional(scenario))
                                        }
                                    }
                                    .pickerStyle(MenuPickerStyle())
                                    // 传递给class，以用作文件名
                                    .onChange(of: self.newScenario) { oldValue, newValue in
                                        if let scenario = newValue {
                                            recordAllDataModel.scenarioName = scenario.name
                                        } else {
                                            // 处理 newValue 为 nil 的情况
                                            recordAllDataModel.scenarioName = ""
                                        }
                                    }
                                }
                                Spacer()
                                HStack {
                                    Spacer()
                                     StartRecordingButton(isSaved: self.$isSaved, description: self.$description, newScenario: self.$newScenario)
                                    Spacer()
                                }
                                Spacer()
                            }
                        }
                    }
                }
            .alert(
                "Recording completed.",
                isPresented: $isSaved
            ) {
                Button("OK") {
                    // Handle the acknowledgement.
                }
            } message: {
//                Text("You have successfully recorded an action😁")
                Text("You have successfully recorded an action😁\n" +
                     "Left Force Data: \(self.recordAllDataModel.recordedForceData.count)\n" +
//                     "Right Force Data: \(self.recordAllDataModel.recordedRightForceData.count)\n" +
                     "Angle Data: \(self.recordAllDataModel.recordedAngleData.count)\n" +
                     "AR Data: \(self.recordAllDataModel.recordedARData.count)")
                
            }
        }
    }
}



#Preview(traits: .landscapeRight) {
    ControlButtonView()
        .environment(RecordAllDataModel())
        .environment(WebSocketManager.shared)
}

struct StartRecordingButton: View {
    @State var isRunningTimer = false
    @Environment(RecordAllDataModel.self) var recordAllDataModel
    @Environment(WebSocketManager.self) private var webSocketManager
    @State private var startTime = Date()
    @State private var display = "00:00:00"
    @State private var timer = Timer.publish(every: 1/60, on: .main, in: .common).autoconnect()
    
    @Binding var isSaved: Bool
    @Binding var description: String
//    @Binding var scenario: Scenario
    @Binding var newScenario: Scenario2?
    
    @AppStorage("ignore websocket") private var ignoreWebsocket = false
    @State var isWaitingtoSave = false
    @Environment(\.modelContext) private var modelContext
    
    var body: some View {
        Button(action: {
            withAnimation {
                if isRunningTimer { //结束录制
                    recordAllDataModel.stopRecordingData()
                    timer.upstream.connect().cancel()
                    self.isRunningTimer = false
                    self.isWaitingtoSave = true
                    
                    // MARK: - Save All Data to SwiftData Here
                    let newAllData = AllStorgeData(
                        createTime: Date(),
                        timeDuration: recordAllDataModel.recordingDuration,
                        notes: self.description,
                        forceData: recordAllDataModel.recordedForceData, 
                        rightForceData: recordAllDataModel.recordedRightForceData,
                        angleData: recordAllDataModel.recordedAngleData,
                        aRData: recordAllDataModel.recordedARData
                    )
                    newAllData.scenario = self.newScenario
                    modelContext.insert(newAllData)
                    isSaved = true
//                    do {
//                        try modelContext.save()
//                        isSaved = true
//                    } catch {
//                        print("Failed to save data: \(error.localizedDescription)")
//                    }
                    
                } else {
                    recordAllDataModel.startRecordingData()
                    display = "00:00:00"
                    startTime = Date()
                    timer = Timer.publish(every: 0.01, on: .main, in: .common).autoconnect()
                    self.isRunningTimer = true
                    self.isWaitingtoSave = false
                }
            }
        }) {
            HStack {
                if isRunningTimer {
                    Image(systemName: "stop.circle.fill")
                        .resizable()
                        .frame(width: 30, height: 30)
                        .foregroundColor(.white)
                        .symbolEffect(.pulse.wholeSymbol)
                    
                    Text(display)
                        .font(.system(.headline, design: .monospaced))
                        .foregroundColor(.white)
                } else {
                    Text("Start Recording")
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                }
            }
            .frame(height: 25)
            .padding()
            .background((ignoreWebsocket || webSocketManager.isConnected) ? (isRunningTimer ? Color.red : Color.green) : Color.gray)
            .clipShape(Capsule())
        }
        
        // 当ignorewebsocket为true时，按钮就可以用
        .disabled(!(ignoreWebsocket || webSocketManager.isConnected))
        .onReceive(timer) { _ in
            if isRunningTimer {
                let duration = Date().timeIntervalSince(startTime)
                let minutes = Int(duration) / 60
                let seconds = Int(duration) % 60
                let milliseconds = Int((duration - Double(minutes * 60 + seconds)) * 100) % 100
                display = String(format: "%02d:%02d:%02d", minutes, seconds, milliseconds)
            }
        }
        .onAppear {
            timer.upstream.connect().cancel()
        }
    }
}
