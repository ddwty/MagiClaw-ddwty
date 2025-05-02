//
//  FTChart.swift
//  MagiClaw
//
//  Created by Tianyu on 4/19/25.
//

import SwiftUI
import Charts

struct FTDataChartView: View {
    var ftDataHistory: [[FTDataPoint]]
   
    private let forceColors: [Color] = [.red, .green, .blue]
    private let torqueColors: [Color] = [.red, .green, .blue]
    var body: some View {
        VStack {
            ScrollView {
                    HStack {
                        VStack {
                            ForEach(0..<3) { axisIndex in
                                Chart {
                                    ForEach(ftDataHistory[axisIndex]) { dataPoint in
                                        LineMark(
                                            x: .value("Time", dataPoint.timestamp),
                                            y: .value("Force", dataPoint.value)
                                        )
                                        .foregroundStyle(forceColors[axisIndex])
                                        .lineStyle(StrokeStyle(lineWidth: 2))
                                    }
                                    .interpolationMethod(.catmullRom)
                                }
                                .chartYAxis {
                                    AxisMarks(position: .leading)
                                }
                                .chartXAxis {
                                    AxisMarks(values: .automatic(desiredCount: 5))
                                }
                                .frame(height: 120)
                                .padding(.horizontal)
                                .background(Color.gray.opacity(0.05))
                                .cornerRadius(10)
                                .overlay(
                                    Text("\(getAxisName(axisIndex)) (N)")
                                        .font(.caption)
                                        .padding(5)
                                        .background(Color.white.opacity(0.8))
                                        .cornerRadius(5)
                                        .padding(5),
                                    alignment: .topLeading
                                )
                            }
                        }
                        VStack {
                            // 扭矩图表
                            ForEach(3..<6) { axisIndex in
                                Chart {
                                    ForEach(ftDataHistory[axisIndex]) { dataPoint in
                                        LineMark(
                                            x: .value("Time", dataPoint.timestamp),
                                            y: .value("Torque", dataPoint.value)
                                        )
                                        .foregroundStyle(torqueColors[axisIndex - 3])
                                        .lineStyle(StrokeStyle(lineWidth: 2))
                                    }
                                    .interpolationMethod(.catmullRom)
                                }
                                .chartYAxis {
                                    AxisMarks(position: .leading)
                                }
                                .chartXAxis {
                                    AxisMarks(values: .automatic(desiredCount: 5))
                                }
                                .frame(height: 120)
                                .padding(.horizontal)
                                .background(Color.gray.opacity(0.05))
                                .cornerRadius(10)
                                .overlay(
                                    Text("\(getAxisName(axisIndex)) (Nm)")
                                        .font(.caption)
                                        .padding(5)
                                        .background(Color.white.opacity(0.8))
                                        .cornerRadius(5)
                                        .padding(5),
                                    alignment: .topLeading
                                )
                            }
                        }
                    }
            }
        }
        
    }
    
    private func getAxisName(_ index: Int) -> String {
        let axes = ["Fx", "Fy", "Fz", "Tx", "Ty", "Tz"]
        return axes[index]
    }
}

