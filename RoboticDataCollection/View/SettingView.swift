//
//  SettingView.swift
//  talkWithRpi
//
//  Created by Tianyu on 7/22/24.
//

import SwiftUI

struct SettingView: View {
    @AppStorage("ignore websocket") private var ignorWebsocket = false
    var body: some View {
        NavigationStack {
            Form {
                Toggle(isOn: $ignorWebsocket) {
                    Label("ignore websocket", systemImage: "network.slash")
                }
            }
            .navigationTitle("Settings")
        }
       
        
        
    }
}

#Preview {
    SettingView()
}

