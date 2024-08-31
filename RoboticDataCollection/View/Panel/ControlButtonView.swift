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
    @Query private var storedScenarios: [Scenario]
    
    @State var isSaved = false
    @State private var description = ""
    //    @State private var scenario: Scenario = .unspecified
    
    @State private var newScenario: Scenario?
    
    @Binding var showPopover: Bool
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
                            StartRecordingButton(showPopover: self.$showPopover, isSaved: self.$isSaved, description: self.$description, newScenario: self.$newScenario)
                        Spacer()
                    }
                }
            }
            .alert(
                "Recording completed",
                isPresented: $isSaved
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
                                .onTapGesture {  } // outer tap gesture has no effect on field
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
                                StartRecordingButton(showPopover: self.$showPopover, isSaved: self.$isSaved, description: self.$description, newScenario: self.$newScenario)
                                Spacer()
                            }
                            Spacer()
                        }
                    }
                }
            }
            .alert(
                "Recording completed",
                isPresented: $isSaved
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
    ControlButtonView(showPopover: .constant(false))
        .environment(RecordAllDataModel())
        .environment(WebSocketManager.shared)
}

struct StartRecordingButton: View {
    @State var isRunningTimer = false // 在展示popover时，禁用录制按钮
    @State private var isLocked = false // Lock screen oirtation when recording
    @Binding var showPopover: Bool
    @Environment(RecordAllDataModel.self) var recordAllDataModel
    @Environment(WebSocketManager.self) private var webSocketManager
    @State private var startTime = Date()
    @State private var display = "00:00:00"
    @State private var timer = Timer.publish(every: 1/60, on: .main, in: .common).autoconnect()
    

    @Binding var isSaved: Bool
    @Binding var description: String
    @Binding var newScenario: Scenario?

    @AppStorage("ignore websocket") private var ignoreWebsocket = false
    @State var isWaitingtoSave = false
    @Environment(\.modelContext) private var modelContext
    @StateObject var savingProgress = SavingProgress.shared

    var body: some View {
        ZStack {
            Button(action: {
                toggleLock() // 屏幕方向锁定
                withAnimation {
                    if isRunningTimer { //结束录制
                        // 触发震动
                        let impactFeedbackGenerator = UIImpactFeedbackGenerator(style: .medium)
                        impactFeedbackGenerator.impactOccurred()
                        
                        recordAllDataModel.stopRecordingData()
                        timer.upstream.connect().cancel()
                        self.isRunningTimer = false
                        self.isWaitingtoSave = true
                        
                        DispatchQueue.global(qos: .userInitiated).async {
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
                            
                        }
                        isSaved = true
                        
                    } else { // start recording
                        // 触发震动
                        let impactFeedbackGenerator = UIImpactFeedbackGenerator(style: .medium)
                        impactFeedbackGenerator.impactOccurred()
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
                .onAppear {
                    // 当视图出现时，重置为默认方向
                    AppDelegate.orientationLock = .all
                }
            }
            
            // 当ignorewebsocket为true时，按钮就可以用,只要showPopover，就禁用
            .disabled((!(ignoreWebsocket || webSocketManager.isConnected)) || showPopover)
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
//            HStack {
//                Spacer()
//                ProgressView(value: savingProgress.progress, total: 1.0)
//                            .progressViewStyle(GaugeProgressStyle())
//                            .frame(width: 30, height: 30)
//                            .padding(.trailing)
//                            .contentShape(Rectangle())
//                            .onTapGesture {
//                                if savingProgress.progress < 1.0 {
//                                    withAnimation {
//                                        savingProgress.progress += 0.2
//                                    }
//                                }
//                            }
//            }
        }
    }

    private func toggleLock() {
        let currentOrientation = UIDevice.current.orientation

        if isLocked {
            // 解除锁定
            AppDelegate.orientationLock = .all
        } else {
            // 锁定当前方向
            switch currentOrientation {
            case .portrait, .portraitUpsideDown:
                AppDelegate.orientationLock = .portrait
            case .landscapeLeft, .landscapeRight:
                AppDelegate.orientationLock = .landscape
            default:
                AppDelegate.orientationLock = .all
            }
        }

        // 触发屏幕旋转
//        UIViewController.attemptRotationToDeviceOrientation()
        // 更新支持的界面方向
           if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
               windowScene.keyWindow?.rootViewController?.setNeedsUpdateOfSupportedInterfaceOrientations()
           }
        isLocked.toggle()
    }
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
