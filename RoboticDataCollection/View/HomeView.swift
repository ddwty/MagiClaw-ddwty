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
    
    var body: some View {
        NavigationStack {
            VStack {
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
                Text("Next Gen Universal Action Embodiment Interface")
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
            }
            .fullScreenCover(isPresented: self.$showRecordView, content: {
                PanelView()
            })
            .fullScreenCover(isPresented: self.$showRemoteView, content: {
                RemotePanel()
            })
            
        }
    }
}

#Preview {
    HomeView()
}

struct HomeRecordButton: View {
    var body: some View {
        VStack {
            Label("Record", systemImage: "camera.metering.center.weighted")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
        }
        .frame(width: 200, height: 100)
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
    var body: some View {
        VStack {
            Label("Remote", systemImage: "paperplane.fill")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
        }
        .frame(width: 200, height: 100)
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
