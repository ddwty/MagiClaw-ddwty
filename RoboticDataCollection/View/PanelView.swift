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
//#if DEBUG
//        let _ = Self._printChanges()
//    #endif
        GeometryReader { geometry in
            Group {
                if verticalSizeClass == .regular {
                    VStack {
                        
                        MyARView()
                            .id("ar")
                            .cornerRadius(8)
                            .aspectRatio(3/4, contentMode: .fit)
                            .padding(.top, 10)
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
                        
                    }
                } else {
                    VStack {
                        GroupBox {
                            VStack {
                                Spacer()
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
                                Spacer()
                            }
                        }
                        .padding()
                        .frame(maxWidth: geometry.size.width, maxHeight: geometry.size.height * 0.4)
                        HStack {
                            VStack {
                                Spacer()
                                MyARView()
                                    .id("ar")
                                    .cornerRadius(8)
                                    .frame(maxWidth: geometry.size.height * 2 / 3, maxHeight: geometry.size.height * 0.5)
                                    .aspectRatio(4/3, contentMode: .fit)
                                
                                Spacer()
                            }
                            .padding(.leading)
                            .padding(.vertical, 5)
                            VStack {
                                Spacer()
                                ControlButtonView()
                                    .frame(maxWidth: .infinity, maxHeight: geometry.size.height * 0.5)
                                Spacer()
                            }
                            .padding(.trailing)
                            
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
        .environmentObject(ARRecorder.shared)
}

