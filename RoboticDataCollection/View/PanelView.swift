//
//  PanelView.swift
//  talkWithRpi
//
//  Created by Tianyu on 7/22/24.
//

import SwiftUI

struct PanelView: View {
    @Environment(\.verticalSizeClass) var verticalSizeClass
    
    //    @StateObject private var keyboardResponder = KeyboardResponder()
    @State var motionData: [MotionData] = []
    @State var showBigAr = false
    
    let screenWidth = UIScreen.main.bounds.size.width
    let screenHeight = UIScreen.main.bounds.size.height
    
    @State var initGeoWidth: CGFloat = .zero
    @State var initGeoHeight: CGFloat = .zero
    @State var value: CGFloat = .zero
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
                            .frame(minWidth: screenWidth * 0.2, minHeight: screenHeight * 0.2)
                        //                        Text("width: " + String(describing: geometry.size.width) + "height: " + String(describing: geometry.size.height))
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
                                HStack {
                                    TotalForceView(leftOrRight: "L")
                                        .padding(.trailing)
                                    Spacer()
                                   
                                    TotalForceView(leftOrRight: "R")
                                }
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
                            VStack(alignment: .center) {
                                HStack {
                                    Spacer()
                                    ////                                    Text(String(describing: screenWidth) + "x" + String(describing: screenHeight))
                                    Text("Status:")
                                        .font(.title3)
                                        .fontWeight(.bold)
                                    RaspberryPiView()
                                    Spacer()
                                }
                                Divider()
                                HStack {
                                    TotalForceView(leftOrRight: "L")
                                    //                                        .frame(width: screenHeight * 0.3)
                                        .frame(minWidth: 200)
                                    Spacer()
                                    AngleView()
                                        .frame(width: 120)
                                    Spacer()
                                    TotalForceView(leftOrRight: "R")
                                    //                                        .frame(width: screenHeight * 0.3)
                                        .frame(minWidth: 200)
                                }
                            }
                        }
                        //                        .frame(maxWidth: screenWidth, maxHeight: screenWidth)
                        
                        HStack {
                            VStack {
                                MyARView()
                                    .id("ar")
                                    .cornerRadius(8)
                                    .aspectRatio(4/3, contentMode: .fit)
                                    .padding(.bottom)
                            }
                            ControlButtonView()
                                .padding(.bottom)
                            
                            
                            //                                    .frame(height: geo.size.height)
                            //                                    .frame(maxWidth: .infinity, maxHeight: geometry.size.height * 0.5)
                            
                            
                            
                        }
                        
                    }
                    .ignoresSafeArea(.keyboard)
                    
                    .padding(.top)
                    
                }
                
            }
        }
        .onAppear {
            //键盘抬起
            NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillShowNotification, object: nil, queue: OperationQueue.current) { (noti) in
                let value = noti.userInfo![UIResponder.keyboardFrameEndUserInfoKey] as! CGRect
                let height = value.height
                withAnimation(.easeInOut) {
                    self.value = height - UIApplication.shared.windows.first!.safeAreaInsets.bottom
                }
            }
            //键盘收起
            NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillHideNotification, object: nil, queue: OperationQueue.current) { (noti) in
                withAnimation(.easeInOut) {
                    self.value = 0
                }
            }
        }
        .offset(y: verticalSizeClass == .regular ?  -value * 0.5 : -value * 0.8)
    }
    
    
}


#Preview() {
    PanelView()
        .environment(RecordAllDataModel())
        .environment(WebSocketManager.shared)
        .environmentObject(ARRecorder.shared)
        .environmentObject(TCPServerManager(port: 8080))
}

