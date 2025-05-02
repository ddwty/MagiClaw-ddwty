//
//  ForceChart.swift
//  MagiClaw
//
//  Created by Tianyu on 10/7/24.
//
#if os(iOS)
import SwiftUI
import Charts
import Combine


#Preview() {
    ForceChart(leftOrRight: "R")
        .environment(WebSocketManager.shared)
}

struct ForceChart: View {
    @Environment(\.verticalSizeClass) var verticalSizeClass
    @Environment(WebSocketManager.self) private var webSocketManager
    @State private var displayedForce: [ForceData] = []
    @State private var timer: Timer?
    var leftOrRight: String
    var updateInterval: TimeInterval = 0.05
    
    private let forceKeys = ["Fx", "Fy", "Fz"]
    private let colors: [String: Color] = [
        "Fx": .red,
        "Fy": .green,
        "Fz": .blue
    ]
    var body: some View {
        //        let _ = Self._printChanges()
        VStack(alignment: .leading) {
            if self.leftOrRight == "L" {
                Text("Left Force (N)")
                    .font(.headline)
                    .multilineTextAlignment(.leading)
                    .lineLimit(1)
            } else {
                HStack {
                    Spacer()
                    Text("Right Force (N)")
                        .font(.headline)
                        .multilineTextAlignment(.leading)
                        .lineLimit(1)
                }
            }
            
            GroupBox("Force") {
                Chart {
                    ForEach(forceKeys, id: \.self) { key in
                        ForEach(Array(displayedForce.enumerated()), id: \.element.id) { index, data in
                            LineMark(
                                x: .value("Index", index),
                                y: .value(key, getAttitudeValue(for: key, from: data))
                            )
                            .foregroundStyle(by: .value("Type", key))
                            .foregroundStyle(colors[key] ?? .black)
                        }
                    }
                }
                .chartXAxisLabel("Time")
                .chartYAxisLabel("Force")
                .frame(height: 200)
                .chartYScale(domain: -3...3)
                .padding(5)
            }
            
            
        }
        .onAppear {
            timer = Timer.scheduledTimer(withTimeInterval: updateInterval, repeats: true) { _ in
                if self.leftOrRight == "L" {
                    displayedForce = webSocketManager.LforceDataforShow
                } else {
                    displayedForce = webSocketManager.RforceDataforShow
                }
            }
        }
        .onDisappear {
            timer?.invalidate()
            timer = nil
        }
    }
    func getAttitudeValue(for key: String, from data: ForceData) -> Double {
        switch key {
        case "Fx":
            return data.forceData?[0] ?? 0
        case "Fy":
            return data.forceData?[1] ?? 0
        case "Fz":
            return data.forceData?[2] ?? 0
        default:
            return 0
        }
    }
    
}
#endif
