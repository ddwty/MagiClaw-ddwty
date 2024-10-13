//
//  HomeView.swift
//  MagiClaw
//
//  Created by 吴天禹 on 2024/9/8.
//

import SwiftUI

struct HomeView: View {
    @Environment(\.verticalSizeClass) var verticalSizeClass
    @State var showRecordView: Bool = false
    @State var showRemoteView: Bool = false
    @State var visibility = Visibility.visible
    @StateObject var audioWebsocketServer = WebSocketServerManager(port: 8081)
    
    var body: some View {
        NavigationStack {
            VStack {
                Spacer()
                Text("MagiClaw")
                    .font(.system(size: 52))
                    .fontWeight(.bold)
                    .fontDesign(.rounded)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color("magiclawLinear1"), Color("magiclawLinear2"), Color("magiclawLinear3")],
                            startPoint: .leading, endPoint: .trailing)
                    )
                    .padding()
                Text("The Next Generation of DeepClaw for Embodied Actions")
                    .foregroundStyle(Color.secondary)
                if verticalSizeClass == .regular {
                    VStack(spacing: 20) {
                        HomeRecordButton()
                            .onTapGesture {
                                self.showRecordView.toggle()
                            }
                        HomeRemoteButton()
                            .onTapGesture {
                                self.showRemoteView.toggle()
                            }
                    }
                    .padding()
                } else  {
                    HStack(spacing: 30) {
                      
                        HomeRecordButton()
                            .onTapGesture {
                                self.showRecordView.toggle()
                            }
                        HomeRemoteButton()
                            .onTapGesture {
                                self.showRemoteView.toggle()
                            }
                    }
                    .padding()
                }
                Link(destination: URL(string: "https://deepclaw.com")!) {
                    Label("Our Website", systemImage: "safari")
                        .foregroundStyle(Color("tintColor"))
                }
                Spacer()
            }
            .frame(maxWidth: .infinity)
            .background(Color("background"))
            
            .fullScreenCover(isPresented: self.$showRecordView, content: {
                PanelView()
            })
            .fullScreenCover(isPresented: self.$showRemoteView, content: {
                RemotePanel(audioWebSocketServer: self.audioWebsocketServer)
            })
            
        }
        
    }
}

#Preview {
    HomeView()
}

struct HomeRecordButton: View {
    let device = UIDevice.current.userInterfaceIdiom
    var body: some View {
        VStack {
            Label("Record", systemImage: "camera.metering.center.weighted")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
        }
        
        .frame(width: device == .phone ? 200 : 300, height: device == .phone ? 100 : 150)
        
        .background(
            LinearGradient(
                colors: [Color("linearBlue1"), Color("linearBlue2")],
                startPoint: .top, endPoint: .bottom)
        )
        .cornerRadius(20)
        .shadow(color: .black.opacity(0.2), radius:10)
    }
}


struct HomeRemoteButton: View {
    let device = UIDevice.current.userInterfaceIdiom
    var body: some View {
        VStack {
            Label("Stream", systemImage: "paperplane.fill")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
        }
        .frame(width: device == .phone ? 200 : 300, height: device == .phone ? 100 : 150)
        .background(
            LinearGradient(
                colors: [Color("linearGreen1"), Color("linearGreen2")],
                startPoint: .top, endPoint: .bottom)
        )
        .cornerRadius(20)
        .shadow(color: .black.opacity(0.2), radius:10)
    }
}


enum NavigationType {
    case navigationLink
    case sheet
}
