//
//  RaspberryPiView.swift
//  talkWithRpi
//
//  Created by Tianyu on 7/15/24.
// 使用访问GeS的树莓派

import SwiftUI
import Combine
import Starscream
import TipKit

struct RaspberryPiView: View {
    @Environment(\.verticalSizeClass) var verticalSizeClass
    @Environment(WebSocketManager.self) private var webSocketManager
    @State private var message: String = ""
    @Binding var showPopover: Bool
    var body: some View {
        HStack {
            if !webSocketManager.isConnected {
                HStack {
                    Spacer()
                    Label("Connected", systemImage: "checkmark.circle")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.green)
                        .symbolEffect(.bounce, value: webSocketManager.isConnected)
                  
                    if verticalSizeClass == .regular {
                        Spacer()
                        Button(action: {
                            self.showPopover.toggle()
                        }) {
                            Image(systemName: "info.circle")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .foregroundStyle(Color("tintColor"))
                                .frame(width: 25, height: 25)
                        }
                        .popover(isPresented: $showPopover,
                                 attachmentAnchor: .point(.center),
                                 content: {
                            RaspberryPiStatusView()
                                .padding()
                                .presentationCompactAdaptation(.popover)
                        })
                    } else {
                        Button(action: {
                            self.showPopover.toggle()
                        }) {
                            Image(systemName: "info.circle")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .foregroundStyle(Color("tintColor"))
                                .frame(width: 25, height: 25)
                        }
                        .padding(.horizontal)
                        .popover(isPresented: $showPopover,
                                 attachmentAnchor: .point(.center),
                                 content: {
                            RaspberryPiStatusView()
                                .padding()
                                .presentationCompactAdaptation(.popover)
                        })
                        Spacer()
                    }

                }
            } else {
                HStack {
                    Spacer()
                    Label("Offline", systemImage: "wifi.router")
                        .foregroundColor(.red)
                        .font(.title3)
                        .fontWeight(.bold)
                        .symbolEffect(.variableColor.iterative.reversing)
                    
                    if verticalSizeClass == .regular {
                        Spacer()
                        Button(action: {
                            self.showPopover.toggle()
                        }) {
                            Image(systemName: "info.circle")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .foregroundStyle(Color("tintColor"))
                                .frame(width: 25, height: 25)
                        }
                        .popover(isPresented: $showPopover,
                                 attachmentAnchor: .point(.center),
                                 content: {
                            RaspberryPiStatusView()
                                .padding()
                                .presentationCompactAdaptation(.popover)
                        })
                    } else {
                        Button(action: {
                            self.showPopover.toggle()
                        }) {
                            Image(systemName: "info.circle")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .foregroundStyle(Color("tintColor"))
                                .frame(width: 25, height: 25)
                        }
                        .padding(.horizontal)
                        .popover(isPresented: $showPopover,
                                 attachmentAnchor: .point(.center),
                                 content: {
                            RaspberryPiStatusView()
                                .padding()
                                .presentationCompactAdaptation(.popover)
                        })
                        Spacer()
                    }
                }
            }
        }
    }
    
}

struct FilledButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(8)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
    }
}

struct ViaWifiView_Previews: PreviewProvider {
    static var previews: some View {
        RaspberryPiView(showPopover: .constant(false))
            .environment(WebSocketManager.shared)
    }
}



