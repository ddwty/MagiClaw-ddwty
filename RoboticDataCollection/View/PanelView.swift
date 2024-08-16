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
                        Text("width: " + String(describing: geometry.size.width) + "height: " + String(describing: geometry.size.height))
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
                            VStack(alignment: .center, spacing: 2) {
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
                                        .frame(width: screenWidth * 0.5)
                                    Spacer()
                                    AngleView()
                                    Spacer()
                                }
                            }
                        }
//                        .frame(maxWidth: screenWidth, maxHeight: screenWidth)
                       
                            HStack {
                                VStack {
                                    MyARView()
                                        .id("ar")
                                        .cornerRadius(8)
                                    //                                    .frame(maxWidth: geometry.size.height * 2 / 3, maxHeight: geometry.size.height * 0.5)
                                        .aspectRatio(4/3, contentMode: .fit)
                                        .padding()
                                    //                                Spacer()
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
}

