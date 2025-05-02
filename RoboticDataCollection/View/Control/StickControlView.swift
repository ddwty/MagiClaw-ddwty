//
//  StickControlView.swift
//  MagiClaw
//
//  Created by Tianyu on 11/17/24.
//
#if os(iOS)

import SwiftUI

struct StickControlView: View {
    @Environment(\.verticalSizeClass) var verticalSizeClass
    @State var controlWebsocket = ControlWebsocket()
    
    var body: some View {
        NavigationStack {
            ZStack {
                ScrollView {
                    if verticalSizeClass == .regular {
                        ConnectPanel(controlWebsocket: controlWebsocket)
                            .padding()
                        BinaryView(controlWebsocket: controlWebsocket)
                        HStack {
                            Spacer()
                            GripperControlView()
                                .padding(.trailing, 35)
                        }
                        JoystickView()
                    } else {
                        ConnectPanel(controlWebsocket: controlWebsocket)
                            .padding()
                       
                        HStack {
                            Spacer()
                            GripperControlView()
                                .padding(.trailing, 35)
                        }
                        ZStack {
                            BinaryView(controlWebsocket: controlWebsocket)
                            JoystickView()
                        }
                            
                    }
                }
            }
            .onTapGesture {
                hideKeyboard()
            }
        }
        
    }
}

#Preview {
    StickControlView()
}
#endif
