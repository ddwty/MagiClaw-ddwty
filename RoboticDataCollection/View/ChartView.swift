//
//  ChartView.swift
//  talkWithRpi
//
//  Created by Tianyu on 7/18/24.
//


import SwiftUI
import Charts
import CoreMotion

struct ChartView: View {
    //    @StateObject var motionManager = MotionManager.shared
    @EnvironmentObject var motionManager: MotionManager
    @State var motionData: [MotionData] = []  // 用于Chart显示
    
    @State var showCharts = false
    @State var isReadingData = false
    
    let width: CGFloat
    let height: CGFloat
    
    //    @EnvironmentObject var recordAllDataManager: RecordAllDataModel
    
    var body: some View {
        VStack {
            AttitudeIndicatorView(motionManager: motionManager, showCharts: $showCharts, width: self.width, height: self.height)
        }
        .sheet(isPresented: $showCharts) {
            subChartView(motionData: $motionData, showCharts: $showCharts)
                .environmentObject(motionManager)
                .interactiveDismissDisabled()
        }
        .onAppear {
            self.motionData = motionManager.motionDataArray
            self.motionManager.startUpdates()
        }
        .onReceive(motionManager.$motionDataArray) { newMotionData in
            self.motionData = newMotionData
        }
        .onDisappear {
            self.motionManager.stopUpdates()
        }
    }
}



struct subChartView: View {
    @EnvironmentObject var motionManager: MotionManager
    @Binding var motionData: [MotionData]
    @Binding var showCharts: Bool
    private let attitudeKeys = ["Pitch", "Yaw", "Roll"]
    private let rotationRateKeys = ["xRotationRate", "yRotationRate", "zRotationRate"]
    private let accelerationKeys = ["xAcceleration", "yAcceleration", "zAcceleration"]
    
    private let colors: [String: Color] = [
            "Pitch": .red,
            "Yaw": .green,
            "Roll": .blue,
            "xRotationRate": .red,
            "yRotationRate": .green,
            "zRotationRate": .blue,
            "xAcceleration": .red,
            "yAcceleration": .green,
            "zAcceleration": .blue
        ]
    
    var body: some View {
        VStack {
            HStack {
                GroupBox("Quaternion") {
                    Chart {
                        ForEach(attitudeKeys, id: \.self) { key in
                            ForEach(motionData) { data in
                                LineMark(
                                    x: .value("Time", data.timestamp),
                                    y: .value(key, getAttitudeValue(for: key, from: data))
                                )
                                .foregroundStyle(by: .value("Type", key))
                              .foregroundStyle(colors[key] ?? .black)
                            }
                        }
                    }
                    .chartXAxisLabel("Time")
                    .chartYAxisLabel("Attitude")
                    .frame(height: 200)
                    .chartYScale(domain: -3...3)
                    .padding(5)
                }
                
                
                //                GroupBox("Rotation Rate") {
                //                    Chart {
                //                        ForEach(rotationRateKeys, id: \.self) { key in
                //                            ForEach(motionData) { data in
                //                                LineMark(
                //                                    x: .value("Time", data.timestamp),
                //                                    y: .value(key, getRotationRateValue(for: key, from: data))
                //                                )
                //                                .foregroundStyle(by: .value("Type", key))
                //                            }
                //                        }
                //                    }
                //                    .chartXAxisLabel("Time")
                //                    .chartYAxisLabel("Rotation Rate")
                //                    .chartYScale(domain: -5...5)
                //                    .padding(5)
                //                }
                GroupBox("Acceleration") {
                    Chart {
                        ForEach(accelerationKeys, id: \.self) { key in
                            ForEach(motionData) { data in
                                LineMark(
                                    x: .value("Time", data.timestamp),
                                    y: .value(key, getAccelerationValue(for: key, from: data))
                                )
                                .foregroundStyle(by: .value("Type", key))
                                .foregroundStyle(colors[key] ?? .black)
                            }
                        }
                    }
                    .chartXAxisLabel("Time")
                    .chartYAxisLabel("Acceleration")
                    .chartYScale(domain: -1...1)
                    .padding(5)
                }
            }
//            .padding(.horizontal)
            .padding()
            
            
            Button(action: { self.showCharts = false }) {
                Label("Close", systemImage: "xmark")
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .clipShape(Capsule())
            }
            .padding(.bottom, 20)
        }
        .padding()
        .background(Color(UIColor.systemBackground).edgesIgnoringSafeArea(.all))
        .gesture(DragGesture().onEnded {
            if $0.translation.height > 50 {
                self.showCharts = false
            }
        })
    }
    
    func getAttitudeValue(for key: String, from data: MotionData) -> Double {
        switch key {
        case "Pitch":
            return data.attitude.pitch
        case "Yaw":
            return data.attitude.yaw
        case "Roll":
            return data.attitude.roll
        default:
            return 0
        }
    }
    
    func getRotationRateValue(for key: String, from data: MotionData) -> Double {
        switch key {
        case "xRotationRate":
            return data.rotationRate.xRotationRate
        case "yRotationRate":
            return data.rotationRate.yRotationRate
        case "zRotationRate":
            return data.rotationRate.zRotationRate
        default:
            return 0
        }
    }
    
    func getAccelerationValue(for key: String, from data: MotionData) -> Double {
        switch key {
        case "xAcceleration":
            return data.acceleration.x
        case "yAcceleration":
            return data.acceleration.y
        case "zAcceleration":
            return data.acceleration.z
        default:
            return 0
        }
    }
}

#Preview(traits: .landscapeRight) {
    ChartView(width: 200, height: 100)
        .previewInterfaceOrientation(.landscapeLeft)
        .environmentObject(RecordAllDataModel())
        .environmentObject(MotionManager.shared)
//        .environmentObject(CameraManager.shared)
}
