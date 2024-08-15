//
//  ForceView.swift
//  talkWithRpi
//
//  Created by Tianyu on 7/24/24.
//

import SwiftUI
import Charts
import Combine


#Preview() {
    TotalForceView()
        .environmentObject(WebSocketManager.shared)
}
struct TotalForceView: View {
    @EnvironmentObject var webSocketManager: WebSocketManager
    var body: some View {
        Text("Force (N): \(webSocketManager.totalForce, specifier: "%.1f")")
            .font(.headline)
            .multilineTextAlignment(.leading)
            .lineLimit(1)
    }
}
//struct TotalForceView: View {
//    @EnvironmentObject var webSocketManager: WebSocketManager
//    @State private var displayedForce: Double = 0.0
//    @State private var cancellable: AnyCancellable? // 使 cancellable 成为 @State 属性
//    private var updateInterval: TimeInterval = 1/30 // Adjust this interval as needed
//
//    var body: some View {
//        VStack {
//            VStack(alignment: .leading) {
//                Text("Force (N)")
//                    .font(.headline)
//                    .multilineTextAlignment(.leading)
//                    .lineLimit(1)
//                
//                Chart {
//                    BarMark(
//                        x: .value("Force", displayedForce),
//                        y: .value("Value", "force")
//                    )
//                    .foregroundStyle(LinearGradient(
//                        colors: [.green,.yellow, .orange, .red],
//                        startPoint: .leading,
//                        endPoint: .trailing
//                    ))
//                    .alignsMarkStylesWithPlotArea()
//                    .clipShape(RoundedRectangle(cornerRadius: 10))
//                }
//                .chartYAxis(Visibility.hidden)
//                .chartXScale(domain: 0...10)
//                .chartXAxis {
//                    AxisMarks(values: Array(stride(from: 0, through: 10, by: 2))) { _ in
//                        AxisGridLine()
//                            .foregroundStyle(Color.gray)
//                        
//                        AxisTick()
//                            .foregroundStyle(Color.gray)
//                        
//                        AxisValueLabel()
//                            .foregroundStyle(Color.primary)
//                            .font(.caption)
//                    }
//                    AxisMarks(values: Array(stride(from: 0, through: 10, by: 1))) {
//                        AxisGridLine()
//                    }
//                }
//                .frame(height: 30)
//                .padding(.trailing, 50)
//            }
////            .animation(.easeInOut(duration: 0.1), value: displayedForce)
//            .onAppear {
//                // Create a timer that updates displayedForce at the specified interval
//                cancellable = Timer.publish(every: updateInterval, on: .main, in: .default)
//                    .autoconnect()
//                    .sink { _ in
//                        displayedForce = webSocketManager.totalForce
//                    }
//            }
//            .onDisappear {
//                cancellable?.cancel() // Cancel the timer when the view disappears
//            }
//        }
//    }
//}
