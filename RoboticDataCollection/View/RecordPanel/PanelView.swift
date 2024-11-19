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
    @Environment(\.verticalSizeClass) var verticalSizeClass
    @Environment(\.dismiss) var dismiss
    @State var showBigAr = false
    @State var initGeoWidth: CGFloat = .zero
    @State var initGeoHeight: CGFloat = .zero
    @State var value: CGFloat = .zero
    @State private var showPopover: Bool = false
    @State private var dragOffset = CGSize.zero
    @State var isPortrait: Bool = true
    @State private var showAlert = false
    @State var clawAngle = ClawAngleManager.shared
    @State var showMultiView = false

    let screenWidth = UIScreen.main.bounds.size.width
    let screenHeight = UIScreen.main.bounds.size.height

    var body: some View {
        ZStack {
            GeometryReader { geometry in
                Group {
                    if verticalSizeClass == .regular {
                        portraitView
                    } else {
                        landscapeView
                    }
                }
                .background(Color("background"))
            }
            .onAppear {
                setupKeyboardNotifications()
                updateOrientation()
            }
            .offset(y: verticalSizeClass == .regular ? -value * 0.5 : -value * 0.8)
            .onTapGesture {
                hideKeyboard()
            }
            .offset(y: dragOffset.height)
            .gesture(
                DragGesture()
                    .onChanged { gesture in
                        if gesture.translation.height > 0 {
                            self.dragOffset = gesture.translation
                        }
                    }
                    .onEnded { _ in
                        if self.dragOffset.height > 100 {
                            dismiss()
                        } else {
                            // 当滑动不足时，恢复原始位置
                            withAnimation(.spring()) {
                                self.dragOffset = .zero
                            }
                        }
                    }
            )
            .animation(.easeInOut(duration: 0.3), value: dragOffset)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color("background"))

        .onDisappear {
            AppDelegate.orientationLock = .all
            resetOrientation()
        }
//        .sheet(isPresented: self.$showMultiView) {
//            MultiSensorView(poseMatrix: [0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15])
//        }
        .checkPermissions([.camera,.microphone, .localNetwork])
    }

    private var portraitView: some View {
        ZStack {
            VStack {
                closeButton
                Spacer()
            }
            VStack {
                ZStack {
                    MyARView(isPortrait: self.$isPortrait, clawAngle: clawAngle)
                        .id("ar")
                        .cornerRadius(15)
                        .aspectRatio(3/4, contentMode: .fit)
                        .frame(minWidth: screenWidth * 0.2, minHeight: screenHeight * 0.2)
                        .shadow(color: Color.black.opacity(0.15), radius: 10, x: 0, y: 0)
                }
                StatusCard(showPopover: $showPopover, clawAngle: clawAngle)
                    .padding(.horizontal)
                    .onTapGesture {
                        self.showMultiView.toggle()
                    }
//                ScrollView(.horizontal) {
//                    HStack {
//                        StatusCard(showPopover: $showPopover, clawAngle: clawAngle)
//                            .padding(.horizontal)
//                        MultiSensorView(poseMatrix: [0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15])
//                            .padding(.horizontal)
//                    }
//                    .scrollTargetLayout()
//                }
//                .scrollTargetBehavior(.viewAligned)
//                TabView() {
//                        StatusCard(showPopover: $showPopover, clawAngle: clawAngle)
//                            .padding(.horizontal)
//                            .frame(height: 220)
//                        MultiSensorView(poseMatrix: [0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15])
//                            .padding(.horizontal)
//                            .frame(maxHeight: .infinity)
//                    
//                }
//                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .automatic))
                
                ControlPanel(showPopover: $showPopover)
                    .padding(.horizontal)
            }
        }
    }

    private var landscapeView: some View {
        ZStack {
            VStack {
                StatusCard(showPopover: $showPopover, clawAngle: clawAngle)
                HStack {
                    MyARView(isPortrait: self.$isPortrait, clawAngle: clawAngle)
                        .id("ar")
                        .cornerRadius(15)
                        .aspectRatio(4/3, contentMode: .fit)
                        .padding(.bottom)
                        .shadow(color: Color.black.opacity(0.15), radius: 10, x: 0, y: 0)
                    ControlPanel(showPopover: $showPopover)
                        .padding(.bottom)
                }
            }
            .ignoresSafeArea(.keyboard)
            .padding(.top)
            closeButton
        }
    }

    private var closeButton: some View {
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

    private func setupKeyboardNotifications() {
        NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillShowNotification, object: nil, queue: OperationQueue.current) { (noti) in
            let value = noti.userInfo![UIResponder.keyboardFrameEndUserInfoKey] as! CGRect
            let height = value.height
            withAnimation(.easeInOut) {
                self.value = height - UIApplication.shared.windows.first!.safeAreaInsets.bottom
            }
        }
        NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillHideNotification, object: nil, queue: OperationQueue.current) { (noti) in
            withAnimation(.easeInOut) {
                self.value = 0
            }
        }
    }

    private func updateOrientation() {
        if self.verticalSizeClass == .regular {
            self.isPortrait = true
        } else {
            self.isPortrait = false
        }
    }

    private func resetOrientation() {
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            let geometryPreferences = UIWindowScene.GeometryPreferences.iOS(interfaceOrientations: .all)
            windowScene.requestGeometryUpdate(geometryPreferences) { _ in }
        }
    }
}

#Preview {
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

