//
//  StopWach.swift
//  talkWithRpi
//
//  Created by Tianyu on 7/24/24.
//

import SwiftUI

struct StopWatchView: View {
    @Binding var isRunning: Bool
    @State private var startTime = Date()
    @State private var display = "00:00"
    @State private var timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    var body: some View {
        Text(display)
            .font(.system(size: 20))
            .foregroundColor(.white)
            .clipShape(Capsule())
            .padding()
            .onReceive(timer) { _ in
                if isRunning {
                    let duration = Date().timeIntervalSince(startTime)
                    let formatter = DateComponentsFormatter()
                    formatter.allowedUnits = [.minute, .second]
                    formatter.unitsStyle = .positional
                    formatter.zeroFormattingBehavior = .pad
                    display = formatter.string(from: duration) ?? ""
                }
            }
            .onTapGesture {
                if isRunning {
                    stop()
                } else {
                    display = "00:00"
                    startTime = Date()
                    start()
                }
                isRunning.toggle()
            }
            .onAppear {
                stop()
            }
    }
    
    func stop() {
        timer.upstream.connect().cancel()
    }
    func start() {
        timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    }
}


struct StopWatchView_Previews: PreviewProvider {
    static var previews: some View {
        StopWatchView(isRunning: .constant(false))
    }
}
