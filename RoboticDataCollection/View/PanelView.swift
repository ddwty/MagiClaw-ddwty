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
            Group {
                if verticalSizeClass == .regular {
                    VStack {
                        MyARView()
                            .id("ar")
                            .cornerRadius(10)
                            .aspectRatio(3/4, contentMode: .fit)
                            .padding(.top, 15)
                            .offset(y: showBigAr ? -130 : 0)
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
                    VStack {
                        GroupBox {
                            VStack {
                                HStack {
                                    Spacer()
                                    Text("Status:")
                                        .font(.title3)
                                        .fontWeight(.bold)
                                    RaspberryPiView()
                                    Spacer()
                                }
                                Divider()
                                HStack {
                                    TotalForceView()
                                        .frame(width: geometry.size.width * 0.5)
                                    Spacer()
                                    AngleView()
                                    Spacer()
                                }
                            }
                        }
                        .padding()
                        .frame(maxWidth: geometry.size.width,maxHeight: geometry.size.height * 0.4)
                        HStack {
                            VStack {
                                Spacer()
                                MyARView()
                                    .id("ar")
                                    .cornerRadius(15)
                                    .frame(maxWidth: .infinity)
                                    .aspectRatio(4/3, contentMode: .fit)
                                
                                Spacer()
                            }
                            .padding(.leading)
                            .padding(.vertical)
                            VStack {
                                ControlButtonView()
                                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                            }
                            .padding()
                            
                        }
                    }
                    
                }
                
            }
        }
      
        
        
    }
   
    
}


#Preview() {
    PanelView()
        .environmentObject(RecordAllDataModel())
    //        .environmentObject(MotionManager.shared)
        .environmentObject(WebSocketManager.shared)
        .environmentObject(ARRecorder.shared)
}

