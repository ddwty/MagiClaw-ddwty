//
//  PanelView.swift
//  talkWithRpi
//
//  Created by Tianyu on 7/22/24.
//

import SwiftUI

struct PanelView: View {
    //    @StateObject var motionManager = MotionManager()
    @EnvironmentObject var motionManager: MotionManager
    
    @State var motionData: [MotionData] = []
    @State var showBigAr = false
    //    @StateObject var recordAllDataManager = RecordAllDataModel()
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                VStack {
                    ChartView(width: geometry.size.width, height: geometry.size.height)
                        .padding()
                    HStack {
                        VStack {
                            MyARView()
                                .cornerRadius(15)
                                .frame(
                                    width: showBigAr ? geometry.size.width  : geometry.size.width * 0.3,
                                    height:  showBigAr ? geometry.size.height : geometry  .size.height * 0.3
                                )
                                .offset(y: showBigAr ? -130 : 0)
                                .onTapGesture {
                                    withAnimation(.easeInOut) {
                                        self.showBigAr.toggle()
                                        
                                    }
                                }
                            Spacer()
                        }
                                                    .border(.green)
                        Spacer()
                        VStack {
                            RaspberryPiView()
                            ControlButtonView()
                                .fixedSize()
                            Spacer()
                        }
//                        .border(.blue)
                        Spacer()
                        Rectangle()
                            .foregroundColor(Color.clear)
                            .cornerRadius(15)
                            .frame(
                                width:  geometry.size.width * 0.3,
                                height: geometry  .size.height * 0.3
                            )
                        
                    }
                    
                }
//                .border(.yellow)
            }
            
        }
    }
}


#Preview(traits: .landscapeRight) {
    PanelView()
        .environmentObject(RecordAllDataModel())
        .environmentObject(MotionManager.shared)
        .environmentObject(WebSocketManager.shared)
        .environmentObject(ARRecorder.shared)
}

