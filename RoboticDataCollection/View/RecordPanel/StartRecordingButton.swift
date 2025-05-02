//
//  StartRecordingButton.swift
//  MagiClaw
//
//  Created by Tianyu on 9/3/24.
//
#if os(iOS)
import SwiftUI
import SwiftData



@Observable
final class StartButtonViewModel: Sendable {
    let modelContainer: ModelContainer
    
    init(modelContainer: ModelContainer) {
        self.modelContainer = modelContainer
    }
}







struct StartRecordingButton: View {
    
//    let modelContainer: ModelContainer
//    var viewModel:  StartButtonViewModel
//    init(modelContainer: ModelContainer, showPopover: Binding<Bool>, showSaveAlert: Binding<Bool>, description: Binding<String>, newScenario: Binding<Scenario?>) {
//        self.modelContainer = modelContainer
//        viewModel =  StartButtonViewModel(modelContainer: modelContainer)
//        _showPopover = showPopover
//        _isSaved = showSaveAlert
//        _description = description
//        _newScenario = newScenario
//        
//    }
    
    
    
    
    
    
    
    @State var isRunningTimer = false // 在展示popover时，禁用录制按钮
    @State private var isLocked = false // Lock screen oirtation when recording
    
    @Environment(RecordAllDataModel.self) var recordAllDataModel
    @Environment(WebSocketManager.self) private var webSocketManager
    @State private var startTime = Date()
    @State private var display = "00:00:00"
    @State private var timer = Timer.publish(every: 1/60, on: .main, in: .common).autoconnect()
    
    @Binding var showPopover: Bool
    @Binding var isSaved: Bool
//    @Binding var description: String
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
//                        self.showSaveAlert = true
                        recordAllDataModel.stopRecordingData()
                        timer.upstream.connect().cancel()
                        self.isRunningTimer = false
                        self.isWaitingtoSave = true
                        Task {
                            let container = modelContext.container
                            let actor = BackgroundSerialPersistenceActor(container: container)
                            // MARK: - Save All Data to SwiftData Here
                            let newAllData = AllStorgeData(
                                createTime: Date(),
                                timeDuration: recordAllDataModel.recordingDuration,
                                notes: recordAllDataModel.description,
                                leftForceCount: recordAllDataModel.recordedForceData.count,
                                rightForceCount: recordAllDataModel.recordedRightForceData.count,
                                angleDataCount: recordAllDataModel.recordedAngleData.count,
                                ARDataCount: recordAllDataModel.recordedARData.count
                            )
                            newAllData.scenario = self.newScenario
                            modelContext.insert(newAllData)
                            
                        }
                        
                    } else { // start recording
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
            .sensoryFeedback(.success, trigger: isRunningTimer)
            
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

//#Preview {
//    StartRecordingButton(showPopover: .constant(false), showSaveAlert: .constant(false), description: .constant(""), newScenario: .constant(nil))
//}
#endif
