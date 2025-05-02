//
//  HomeViewMac.swift
//  MagiClaw
//
//  Created by Tianyu on 4/18/25.
//

import SwiftUI
#if os(macOS)
struct HomeViewMac: View {
    var body: some View {
        TabView {
            Group {
                ATIView()
                    .tabItem {
                        Label("ATI", systemImage: "camera" )
                    }
                AirpodsView()
                    .tabItem {
                        Label("headphone", systemImage: "camera" )
                    }
                
            }
        }
    }
}

#Preview {
    HomeViewMac()
}
#endif
