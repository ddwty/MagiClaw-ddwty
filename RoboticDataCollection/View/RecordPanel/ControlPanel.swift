//
//  ControlButtonView.swift
//  talkWithRpi
//
//  Created by Tianyu on 7/23/24.
//

import SwiftUI
import SwiftData
import UIKit

struct ControlPanel: View {
//    let container: ModelContainer
    @Environment(RecordAllDataModel.self) var recordAllDataModel
    @Environment(WebSocketManager.self) private var webSocketManager
    @Environment(\.verticalSizeClass) var verticalSizeClass
    
    // 让UnSpecified排在最前面，剩下的按字母顺序排
    @Query private var storedScenarios: [Scenario]
    
    @State var showSaveAlert = false
    @State private var description = ""
    //    @State private var scenario: Scenario = .unspecified
    
    @State private var newScenario: Scenario?
    @ObservedObject var settingModel = SettingModel.shared
    
    @Binding var showPopover: Bool
    @FocusState private var isFocused: Bool
    @State private var isLocked = false
    
    
    var body: some View {
        if verticalSizeClass == .regular {
                VStack(alignment: .leading) {
                    HStack {
                        Text("Control Panel")
                            .font(.title3)
                            .fontWeight(.bold)
                        Spacer()
                        
                    }
                    Divider()
                            HStack {
                                Text("Select a scenario: ")
        
                                // TODO: - 检查是否为空
                                Picker("Scenario", selection: $newScenario) {
                                    Text("Unspecified")
                                        .tag(Optional<Scenario>(nil))
        
                                    ForEach(storedScenarios
                                                    .filter { $0.name != "Unspecified" } // 过滤掉 "Unspecified"
                                                    .sorted { $0.name.localizedCompare($1.name) == .orderedAscending } // 按首字母排序
                                                    , id: \.self) { scenario in
        
                                                    Text(scenario.name.capitalized)
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
                        .onChange(of: description) {oldValue, newValue in
                            recordAllDataModel.description = newValue
                        }
                        .disableAutocorrection(true)
                        .onTapGesture {  } // outer tap gesture has no effect on field
                        .toolbar {
                            ToolbarItemGroup(placement: .keyboard) {
                                Spacer()
                                Button("Done") {
                                    isFocused = false
                                }
                            }
                        }
                    
                    HStack {
                        Spacer()
                        StartRecordingButton( showPopover: self.$showPopover, isSaved: self.$showSaveAlert, description: self.$description, newScenario: self.$newScenario)
                           
                        Spacer()
                    }
                }
                .cardBackground()
               
            .alert(
                "Recording completed",
                isPresented: $showSaveAlert
            ) {
                Button("OK") {
                    self.showSaveAlert = false
                }
            } message: {
                let title = "You have successfully recorded an action😁"
                   let leftForceData = "Left Force Data: \(self.recordAllDataModel.recordedForceData.count)"
                   let rightForceData = "Right Force Data: \(self.recordAllDataModel.recordedRightForceData.count)"
                   let angleData = "Angle Data: \(self.recordAllDataModel.recordedAngleData.count)"
                   let arData = "AR Data: \(self.recordAllDataModel.recordedARData.count)"

                   Text("\(title)\n\n\(leftForceData)\n\(rightForceData)\n\(angleData)\n\(arData)")
                       .multilineTextAlignment(.leading)
            }
        } else {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(alignment: .bottom) {
                        Text("Control Panel")
                            .font(.title3)
                            .fontWeight(.bold)
                        Spacer()
                        
                    }
                    Divider()
                    
                    HStack(alignment: .firstTextBaseline) {
                        VStack(alignment: .leading) {
                            Text("Description:")
                                .alignmentGuide(.firstTextBaseline) { d in d[.firstTextBaseline] }
                            TextEditor(text: $description)
                                .background(Color.primary.colorInvert())
                                               .cornerRadius(5)
                                               .overlay(
                                                   RoundedRectangle(cornerRadius: 5)
                                                       .stroke(.black, lineWidth: 1 / 3)
                                                       .opacity(0.3)
                                               )
                                .focused($isFocused)
                                .onChange(of: description) {oldValue, newValue in
                                    recordAllDataModel.description = newValue
                                }
                                .disableAutocorrection(true)
                                .frame(minWidth: 100, minHeight: 30)
                                .onTapGesture {  } // outer tap gesture to hide keyboard has no effect on this field
                                .toolbar {
                                    ToolbarItemGroup(placement: .keyboard) {
                                        Spacer()
                                        Button("Done") {
                                            isFocused = false
                                        }
                                    }
                                }
                        }
                        Spacer()
                        VStack(alignment: .leading) {
                            HStack {
                                Text("Scenario:")
                                    .alignmentGuide(.firstTextBaseline) { d in d[.firstTextBaseline] }
                                
                                Picker("Scenario", selection: $newScenario) {
                                    Text("Unspecified")
                                        .tag(Optional<Scenario>(nil))
                                    
                                    ForEach(storedScenarios
                                        .filter { $0.name != "Unspecified" } // 过滤掉 "Unspecified"
                                        .sorted { $0.name.localizedCompare($1.name) == .orderedAscending } // 按首字母排序
                                            , id: \.self) { scenario in
                                        
                                        Text(scenario.name.capitalized)
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
                                StartRecordingButton(showPopover: self.$showPopover, isSaved: self.$showSaveAlert, description: self.$description, newScenario: self.$newScenario)
                                Spacer()
                            }
                            Spacer()
                        }
                    }
                }
                .cardBackground()
          
            .alert(
                "Recording completed",
                isPresented: $showSaveAlert
            ) {
                Button("OK") {
                }
            } message: {
                let title = "You have successfully recorded an action😁"
                   let leftForceData = "Left Force Data: \(self.recordAllDataModel.recordedForceData.count)"
                   let rightForceData = "Right Force Data: \(self.recordAllDataModel.recordedRightForceData.count)"
                   let angleData = "Angle Data: \(self.recordAllDataModel.recordedAngleData.count)"
                   let arData = "AR Data: \(self.recordAllDataModel.recordedARData.count)"

                   Text("\(title)\n\n\(leftForceData)\n\(rightForceData)\n\(angleData)\n\(arData)")
                       .multilineTextAlignment(.leading)
            }
        }
    }
}



#Preview(traits: .landscapeRight) {
    ControlPanel(showPopover: .constant(false))
            .environment(RecordAllDataModel())
            .environment(WebSocketManager.shared)
            
}







struct GaugeProgressStyle: ProgressViewStyle {
    var strokeColor = Color.blue
    var strokeWidth = 3

    func makeBody(configuration: Configuration) -> some View {
        let fractionCompleted = configuration.fractionCompleted ?? 0

        return ZStack {
            Circle()
                .trim(from: 0, to: fractionCompleted)
                .stroke(strokeColor, style: StrokeStyle(lineWidth: CGFloat(strokeWidth), lineCap: .round))
                .rotationEffect(.degrees(-90))
        }
    }
}

class SavingProgress: ObservableObject {
    static let shared = SavingProgress()
    private init() { }
    @Published var progress = 0.0
}
