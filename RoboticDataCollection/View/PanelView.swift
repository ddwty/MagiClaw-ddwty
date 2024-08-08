//
//  PanelView.swift
//  talkWithRpi
//
//  Created by Tianyu on 7/22/24.
//

import SwiftUI

struct PanelView: View {
    @EnvironmentObject var motionManager: MotionManager
    @Environment(\.verticalSizeClass) var verticalSizeClass
    
    @State var motionData: [MotionData] = []
    @State var showBigAr = false
    
    var body: some View {
        GeometryReader { geometry in
            if verticalSizeClass == .regular {
                VStack {
//                    MyARView()
//                        .cornerRadius(10)
//                        .aspectRatio(4/3, contentMode: .fill)
//                        .frame(
//                            width: showBigAr ? geometry.size.width  : geometry.size.width * 0.3,
//                            height:  showBigAr ? geometry.size.height : geometry  .size.height * 0.3
//                        )
//                        .padding(.top, 15)
//                        .offset(y: showBigAr ? -130 : 0)
                    GroupBox {
                        VStack(alignment: .leading) {
                            HStack {
                                Text("Status:")
                                    .font(.title3)
                                    .fontWeight(.bold)
                                Spacer()
                                RaspberryPiView()
                                Spacer()
                            }
                            Divider()
                            TotalForceView()
                            Divider()
                            AngleView()
                        }
                    }
                    .padding(.horizontal)
                        ControlButtonView()
                            .padding(.horizontal)
                        //                                .fixedSize()
                   
                }
                
                
            } else {
                ZStack {
                    VStack {
//                        ChartView(width: geometry.size.width, height: geometry.size.height)
//                            .padding()
                        HStack {
                            VStack {
                                MyARView()
                                    .cornerRadius(15)
                                    .aspectRatio(4/3, contentMode: .fill)
                                    .frame(
                                        width: showBigAr ? geometry.size.width  : geometry.size.width * 0.3,
                                        height:  showBigAr ? geometry.size.height : geometry  .size.height * 0.3
                                    )
                                    .padding(.top, 15)
                                    .offset(y: showBigAr ? -130 : 0)
                                    .onTapGesture {
                                        withAnimation(.easeInOut) {
                                            self.showBigAr.toggle()
                                            
                                        }
                                    }
                                Spacer()
                            }
                            Spacer()
                            VStack {
                                RaspberryPiView()
                                ControlButtonView()
                                //                                .fixedSize()
                                Spacer()
                            }
                            //                        .border(.blue)
                            Spacer()
                            //                        Rectangle()
                            //                            .foregroundColor(Color.clear)
                            //                            .cornerRadius(15)
                            //                            .frame(
                            //                                width:  geometry.size.width * 0.3,
                            //                                height: geometry  .size.height * 0.3
                            //                            )
//                            Force3DView()
//                            
//                                .frame(width:  geometry.size.width * 0.3)
//                                .aspectRatio(4/3, contentMode: .fill)
//                                .border(.red)
                            //                            .printSizeInfo()
                            
                            
                        }
                        
                    }
                    //                .border(.yellow)
                }
            }
            
        }
        .border(.red)
    }
}


#Preview() {
    PanelView()
        .environmentObject(RecordAllDataModel())
//        .environmentObject(MotionManager.shared)
        .environmentObject(WebSocketManager.shared)
        .environmentObject(ARRecorder.shared)
}

