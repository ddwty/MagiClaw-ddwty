//
//  PanelView.swift
//  talkWithRpi
//
//  Created by Tianyu on 7/22/24.
//

import SwiftUI
import SwiftData
import AVFoundation


struct PanelView: View {
    //    let container: ModelContainer
    @Environment(\.verticalSizeClass) var verticalSizeClass
    
   
    
    @Environment(\.dismiss) var dismiss
    //    @Binding var visibility: Visibility
    
    //    @StateObject private var keyboardResponder = KeyboardResponder()
    //    @State var motionData: [MotionData] = []
    @State var showBigAr = false
    
    let screenWidth = UIScreen.main.bounds.size.width
    let screenHeight = UIScreen.main.bounds.size.height
    
    @State var initGeoWidth: CGFloat = .zero
    @State var initGeoHeight: CGFloat = .zero
    @State var value: CGFloat = .zero
    @State private var showPopover: Bool = false // 指示树莓派各个组件连接情况
    @State private var dragOffset = CGSize.zero // 存储当前拖动中的偏移量
    @State  var isPortrait: Bool = true  // 用于按钮控制屏幕方向
    @State private var showAlert = false
    
    var body: some View {
        //#if DEBUG
        //        let _ = Self._printChanges()
        //    #endif
        ZStack {
            GeometryReader { geometry in
                Group {
                    if verticalSizeClass == .regular {
                        ZStack {
                            VStack {
                                HStack {
                                    Spacer()
                                    Button(action: {
                                        dismiss()
                                    }) {
                                        Text("")
                                    }
                                    .padding()
                                    .buttonStyle(ExitButtonStyle())
                                }
                                Spacer()
                            }
                            VStack {
                                ZStack {
                                    MyARView(isPortrait: self.$isPortrait)
                                        .id("ar")
                                        .cornerRadius(15)
                                        .aspectRatio(3/4, contentMode: .fit)
                                        .frame(minWidth: screenWidth * 0.2, minHeight: screenHeight * 0.2)
                                        .shadow(color: Color.black.opacity(0.15), radius: 10, x: 0, y: 0)
                                    
                                }
                                StatusCard(showPopover: $showPopover)
                                    .padding(.horizontal)
                                ControlPanel(showPopover: $showPopover)
                                    .padding(.horizontal)
                            }
                            VStack {
                                HStack {
                                    Spacer()
                                    Button(action: {
                                        dismiss()
                                    }) {
                                        Text("")
                                    }
                                    .padding()
                                    .buttonStyle(ExitButtonStyle())
                                }
                                Spacer()
                            }
                        }
                        
                    } else { // landscape
                        ZStack {
                            VStack {
                                StatusCard(showPopover: $showPopover)
                                HStack {
                                    VStack {
                                        MyARView(isPortrait: self.$isPortrait)
                                            .id("ar")
                                            .cornerRadius(15)
                                            .aspectRatio(4/3, contentMode: .fit)
                                            .padding(.bottom)
                                            .shadow(color: Color.black.opacity(0.15), radius: 10, x: 0, y: 0)
                                    }
                                    ControlPanel(showPopover: $showPopover)
                                        .padding(.bottom)
                                    
                                }
                                
                            }
                            .ignoresSafeArea(.keyboard)
                            .padding(.top)
                            
                            VStack { // Close button
                                HStack {
                                    Spacer()
                                    Button(action: {
                                        dismiss()
                                    }) {
                                        Text("")
                                    }
                                    .padding()
                                    .shadow(color: Color.black.opacity(0.2), radius: 10)
                                    .buttonStyle(ExitButtonStyle())
                                }
                                Spacer()
                            }
                        }
                        
                    }
                    
                }
                .background(Color.background)
               
                
            } //: GeometryReader
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
            .onTapGesture {
                hideKeyboard()
            }
            .offset(y: dragOffset.height) // 应用偏移量
            .gesture(
                DragGesture()
                    .onChanged { gesture in
                        // 实时更新拖动的偏移量，只允许向下拖动
                        if gesture.translation.height > 0 {
                            self.dragOffset = gesture.translation
                        }
                    }
                    .onEnded { _ in
                        // dissmiss
                        if self.dragOffset.height > 100 {
                            dismiss()
                        }
                        self.dragOffset = .zero
                    }
            )
            .animation(.easeInOut(duration: 0.3), value: dragOffset)
            
            
        } //: ZStack
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.background)
        .onAppear {
            
            if self.verticalSizeClass == .regular {
                self.isPortrait = true
            } else {
                self.isPortrait = false
            }
//                            AppDelegate.orientationLock = .all // 允许所有方向
        }
//        .onChange(of: verticalSizeClass) { old, newValue in
//            if self.verticalSizeClass == .regular {
//                self.isPortrait = true
//            } else {
//                self.isPortrait = false
//            }
//        }
        
        .onDisappear {
            AppDelegate.orientationLock = .all // 恢复所有方向锁定
            resetOrientation() // 重置方向
        }
        .checkPermissions([.camera, .localNetwork])
        
    }
    private func resetOrientation() {
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            let geometryPreferences = UIWindowScene.GeometryPreferences.iOS(interfaceOrientations: .all)
            windowScene.requestGeometryUpdate(geometryPreferences) { _ in
              
            }
        }
    }
    
    
}


#Preview {
    
    //        let preview = Preview(AllStorgeData.self)
    //        let data = AllStorgeData.sampleData
    //        preview.addExamples(data)
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

