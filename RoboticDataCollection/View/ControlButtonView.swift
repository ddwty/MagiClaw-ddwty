//
//  ControlButtonView.swift
//  talkWithRpi
//
//  Created by Tianyu on 7/23/24.
//

import SwiftUI
import SwiftData
struct ControlButtonView: View {
    @EnvironmentObject var recordAllDataModel: RecordAllDataModel
    //    @EnvironmentObject var cameraManager: CameraManager
    @EnvironmentObject var webSocketManager: WebSocketManager
    @Environment(\.modelContext) private var modelContext
    //    @EnvironmentObject var arRecorder: ARRecorder
    @AppStorage("ignore websocket") private var ignorWebsocket = false
    
    
    @State var isRunningTimer = false
    @State var isWaitingtoSave = false
    @State var isSaved = false
    
    @State private var startTime = Date()
    @State private var display = "00:00:00"
    @State private var timer = Timer.publish(every: 0.01, on: .main, in: .common).autoconnect()
    @State private var description = ""
    
    var body: some View {
        VStack {
            TextField("Enter description", text: $description)
                .padding()
            Button(action: {
                withAnimation {
                    if isRunningTimer {
                        recordAllDataModel.stopRecordingData()
                        timer.upstream.connect().cancel()
                        self.isRunningTimer = false
                        self.isWaitingtoSave = true
                        
                        
                        let newAllData = AllStorgeData(createTime: Date(), timeDuration: recordAllDataModel.recordingDuration, notes: self.description, forceData: recordAllDataModel.recordedForceData, angleData: recordAllDataModel.recordedAngleData, aRData: recordAllDataModel.recordedARData)
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
                        //                            .symbolVariant(.fill.circle)
                            .foregroundColor(.white)
                            .symbolEffect(.pulse.wholeSymbol)
                        
                        Text(display)
                            .font(.system(.headline, design: .monospaced))
                            .foregroundColor(.white)
                        //                            .frame(width: 80, alignment: .leading)
                    } else {
                        Text("Start Recording")
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                    }
                }
                //                .frame(width: 180, height: 30)
                .frame(height: 25)
                .padding()
                .background((ignorWebsocket || webSocketManager.isConnected) ? (isRunningTimer ? Color.red : Color.green) : Color.gray)
                .clipShape(Capsule())
                
                //                .shadow(color: .green, radius: 5)
            }
            
            // 当ignorewebsocket为true时，按钮就可以用
            .disabled(!(ignorWebsocket || webSocketManager.isConnected))
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
            
//            Button(action: {
////                guard !recordAllDataModel.recordedARData.isEmpty else { return }
//                // TODO: - 记得改一下这里的Date
////                let newARData = ARStorgeData(createTime: Date(), timeDuration: recordAllDataModel.recordingDuration, originalData: recordAllDataModel.recordedARData)
////                modelContext.insert(newARData)
//                // TODO: - check if it's empty, fill the notes, correct the time duration
//                let newAllData = AllStorgeData(createTime: Date(), timeDuration: recordAllDataModel.recordingDuration, notes: "Default description", forceData: recordAllDataModel.recordedForceData, angleData: recordAllDataModel.recordedAngleData, aRData: recordAllDataModel.recordedARData)
//                modelContext.insert(newAllData)
//                
//                do {
//                        try modelContext.save()
//                        isSaved = true
//                    } catch {
//                        print("Failed to save AR data: \(error.localizedDescription)")
//                    }
//                
//                
//            }) {
//                Text("Save")
//            }
        }
        
        .alert(
            "Recording completed.",
            isPresented: $isSaved
        ) {
            Button("OK") {
                // Handle the acknowledgement.
            }
        } message: {
            Text("You have succefully recorded an action😁")
            //TODO: - 显示数据长度
        }
        
    }
}



#Preview(traits: .landscapeRight) {
    ControlButtonView()
        .environmentObject(RecordAllDataModel())
        .environmentObject(MotionManager.shared)
    //        .environmentObject(CameraManager.shared)
        .environmentObject(WebSocketManager.shared)
        .environmentObject(ARRecorder.shared)
}
