//
//  PanelView.swift
//  talkWithRpi
//
//  Created by Tianyu on 7/22/24.
//

import SwiftUI
import SwiftData

struct PanelView: View {
//    let container: ModelContainer
    @Environment(\.verticalSizeClass) var verticalSizeClass
   
    //    @StateObject private var keyboardResponder = KeyboardResponder()
//    @State var motionData: [MotionData] = []
    @State var showBigAr = false
    
    let screenWidth = UIScreen.main.bounds.size.width
    let screenHeight = UIScreen.main.bounds.size.height
    
    @State var initGeoWidth: CGFloat = .zero
    @State var initGeoHeight: CGFloat = .zero
    @State var value: CGFloat = .zero
    @State private var showPopover: Bool = false // 指示树莓派各个组件连接情况
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
                                    RaspberryPiView(showPopover: $showPopover)
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
                        ControlButtonView(showPopover: $showPopover)
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
                                    RaspberryPiView(showPopover: $showPopover)
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
                        
                        HStack {
                            VStack {
                                MyARView()
                                    .id("ar")
                                    .cornerRadius(8)
                                    .aspectRatio(4/3, contentMode: .fit)
                                    .padding(.bottom)
                            }
                            ControlButtonView(showPopover: $showPopover)
                                .padding(.bottom)
                            
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


#Preview {
   
//    let preview = Preview(AllStorgeData.self)
//    let data = AllStorgeData.sampleData
//    preview.addExamples(data)
   PanelView()
            .environment(RecordAllDataModel())
            .environment(WebSocketManager.shared)
            .environmentObject(ARRecorder.shared)
            .environmentObject(WebSocketServerManager(port: 8080))
   
    
}


struct Preview {
    let container: ModelContainer
    init(_ models: any PersistentModel.Type...) {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let schema = Schema(models)
        do {
            container = try ModelContainer(for: schema, configurations: config)
        } catch {
            fatalError("Could not create preview container")
        }
    }
    
    func addExamples(_ examples: [any PersistentModel]) {
        Task { @MainActor in
            examples.forEach { example in
                container.mainContext.insert(example)
            }
        }
    }
}
