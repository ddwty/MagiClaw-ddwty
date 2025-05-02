//
//  ATIView.swift
//  MagiClaw
//
//  Created by Tianyu on 4/17/25.
//

import Foundation
import SwiftUI
import Charts
import AVFoundation
#if os(macOS)
struct ATIView: View {
    @State private var viewModel = ATIViewModel()
    
    var body: some View {
        VStack(spacing: 15) {
            // 相机模块
            USBCameraView(isVisible: $viewModel.showCameraView)
            
            Text("F/T Sensor Data")
                .font(.title)
                .padding(.top)
            
            HStack {
                Text("IP Address:")
                TextField("Enter sensor IP", text: $viewModel.ipAddress)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .disabled(viewModel.isConnected)
            }
            .padding(.horizontal)
            
            HStack(spacing: 20) {
                Button(viewModel.isConnected ? "Disconnect" : "Connect") {
                    if viewModel.isConnected {
                        viewModel.disconnectSensor()
                    } else {
                        viewModel.connectSensor()
                    }
                }
                .padding()
                .foregroundColor(.white)
                .cornerRadius(10)
                .disabled(viewModel.isStreaming)
                
                Button(viewModel.isStreaming ? "Stop" : "Start") {
                    if viewModel.isStreaming {
                        viewModel.stopStreaming()
                    } else {
                        viewModel.startStreaming()
                    }
                }
                .padding()
                .foregroundColor(.white)
                .cornerRadius(10)
                .disabled(!viewModel.isConnected)
                
                Button("Reset") {
                    viewModel.resetSensorData()
                }
                .padding()
                .foregroundColor(.white)
                .cornerRadius(10)
                .disabled(!viewModel.isConnected)
            }
            
            if !viewModel.errorMessage.isEmpty {
                Text(viewModel.errorMessage)
                    .foregroundColor(.red)
                    .padding()
            }
            
            // 图表区域
            FTDataChartView(ftDataHistory: viewModel.ftDataHistory)
            
            // 数值显示区域
            HStack {
                // 力数据显示
                VStack(alignment: .leading, spacing: 5) {
                    Text("Force (N)")
                        .font(.headline)
                    ForEach(0..<3, id: \.self) { index in
                        HStack {
                            Circle()
                                .fill(viewModel.forceColors[index])
                                .frame(width: 10, height: 10)
                            Text(viewModel.getAxisName(index) + ":")
                                .frame(width: 40, alignment: .leading)
                            Text(String(format: "%.3f", Double(viewModel.ftData[index]) / 1000000))
                                .font(.system(.body, design: .monospaced))
                                .frame(width: 60, alignment: .leading)
                        }
                    }
                }
                .padding()
                .frame(minWidth: 150)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(10)
                
                // 扭矩数据显示
                VStack(alignment: .leading, spacing: 5) {
                    Text("Torque (Nm)")
                        .font(.headline)
                    ForEach(3..<6, id: \.self) { index in
                        HStack {
                            Circle()
                                .fill(viewModel.torqueColors[index-3])
                                .frame(width: 10, height: 10)
                            Text(viewModel.getAxisName(index) + ":")
                                .frame(width: 40, alignment: .leading)
                            Text(String(format: "%.3f", Double(viewModel.ftData[index]) / 1000))
                                .font(.system(.body, design: .monospaced))
                                .frame(width: 60, alignment: .leading)
                        }
                    }
                }
                .padding()
                .frame(minWidth: 150)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(10)
            }
            .padding(.horizontal)
            Spacer()
        }
        .padding()
        .onDisappear {
            viewModel.stopStreaming()
            viewModel.disconnectSensor()
        }
    }
}

#Preview {
    ATIView()
}


#endif
