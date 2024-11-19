//
//  StickControlView.swift
//  MagiClaw
//
//  Created by Tianyu on 11/17/24.
//

import SwiftUI

struct StickControlView: View {
    @State var controlWebsocket = ControlWebsocket()
    var body: some View {
        NavigationStack {
            ZStack {
                ScrollView {
                    ConnectPanel(controlWebsocket: controlWebsocket)
                        .padding()
                    BinaryView(controlWebsocket: controlWebsocket)
                    GameControllerView()
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
