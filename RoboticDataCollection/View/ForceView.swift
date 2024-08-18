//
//  ForceView.swift
//  talkWithRpi
//
//  Created by Tianyu on 7/24/24.
//

import SwiftUI
import Charts
import Combine

//struct TotalForceView: View {
//    @EnvironmentObject var webSocketManager: WebSocketManager
//    var body: some View {
//        let _ = Self._printChanges()
//        Text("Force (N): \(webSocketManager.totalForce, specifier: "%.1f")")
//            .font(.headline)
//            .multilineTextAlignment(.leading)
//            .lineLimit(1)
//    }
//}

#Preview() {
    TotalForceView(force: 1, leftOrRight: "L")
        .environment(WebSocketManager.shared)
}

struct TotalForceView: View {
    @Environment(\.verticalSizeClass) var verticalSizeClass
    @Environment(WebSocketManager.self) private var webSocketManager
    @State private var displayedForce: Double = 0.0
    @State private var timer: Timer?
    var force: Double 
    var leftOrRight: String
    var updateInterval: TimeInterval = 0.1

    var body: some View {
//        let _ = Self._printChanges()
            VStack(alignment: .leading) {
                if self.leftOrRight == "L" {
                    Text("Left Force (N)")
                        .font(.headline)
                        .multilineTextAlignment(.leading)
                        .lineLimit(1)
                } else {
                    Text("Right Force (N)")
                        .font(.headline)
                        .multilineTextAlignment(.leading)
                        .lineLimit(1)
                }
                
                Chart {
                    BarMark(
                        x: .value("Force", displayedForce),
                        y: .value("Value", "force")
                    )
                    .foregroundStyle(LinearGradient(
                        colors: [.green,.yellow, .orange, .red],
                        startPoint: .leading,
                        endPoint: .trailing
                    ))
                    .alignsMarkStylesWithPlotArea()
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .chartYAxis(Visibility.hidden)
                .chartXScale(domain: 0...10)
                .chartXAxis {
                    AxisMarks(values: Array(stride(from: 0, through: 10, by: 2))) { _ in
                        AxisGridLine()
                            .foregroundStyle(Color.gray)
                        
                        AxisTick()
                            .foregroundStyle(Color.gray)
                        
                        AxisValueLabel()
                            .foregroundStyle(Color.primary)
                            .font(.caption)
                    }
                    AxisMarks(values: Array(stride(from: 0, through: 10, by: 1))) {
                        AxisGridLine()
                    }
                }
                .frame(height: 30)
                .padding(.trailing, 50)
                
                
            }
//            .animation(.easeInOut(duration: 0.1), value: displayedForce)
            .onAppear {
                // Create a timer that updates displayedForce at the specified interval
                
                timer = Timer.scheduledTimer(withTimeInterval: updateInterval, repeats: true) { _ in
                    displayedForce = webSocketManager.totalLeftForce
                }
            }
            .onDisappear {
                timer?.invalidate()
                timer = nil
            }
    }
}
