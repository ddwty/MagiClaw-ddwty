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
   
    @State var isSaved = false
    @State private var description = ""
    @State private var scenario: Scenario = .unspecified
//    @State var scenarioModel = SelectedScenario()
   
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
                        Picker("Scenario", selection: $scenario) {
                            ForEach(Scenario.allCases) { scenario in
                                Text(scenario.rawValue.capitalized)
                                    .tag(scenario)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                        // 传递给class，以用作文件名
                        .onChange(of: scenario) { oldValue, newValue in
                            recordAllDataModel.scenarioName = newValue
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
                        StartRecordingButton(isSaved: self.$isSaved, description: self.$description, scenario: self.$scenario)
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
                     "Right Force Data: \(self.recordAllDataModel.recordedRightForceData.count)\n" +
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
                                    Picker("Scenario", selection: $scenario) {
                                        ForEach(Scenario.allCases) { scenario in
                                            Text(scenario.rawValue.capitalized)
                                                        .lineLimit(1)
                                                        .truncationMode(.tail)
                                                        .tag(scenario)
                                                
                                        }
                                    }
                                    .pickerStyle(MenuPickerStyle())
                                    // 传递给class，以用作文件名
                                    .onChange(of: scenario) {oldValue,  newValue in
                                        recordAllDataModel.scenarioName = newValue
                                    }
                                }
                                Spacer()
                                HStack {
                                    Spacer()
                                    StartRecordingButton(isSaved: self.$isSaved, description: self.$description, scenario: self.$scenario)
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
                     "Right Force Data: \(self.recordAllDataModel.recordedRightForceData.count)\n" +
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
    @Binding var scenario: Scenario
    
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
                        scenario: self.scenario,
                        forceData: recordAllDataModel.recordedForceData, rightForceData: recordAllDataModel.recordedRightForceData,
                        angleData: recordAllDataModel.recordedAngleData,
                        aRData: recordAllDataModel.recordedARData
                    )
                    modelContext.insert(newAllData)
                    
                    do {
                        try modelContext.save()
                        isSaved = true
                    } catch {
                        print("Failed to save AR data: \(error.localizedDescription)")
                    }
                    
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
