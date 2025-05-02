//
//  ConnectPanel.swift
//  MagiClawClient
//
//  Created by Tianyu on 9/21/24.
//

#if os(iOS)
import SwiftUI



struct ConnectPanel: View {
    @Bindable var controlWebsocket: ControlWebsocket
//    @AppStorage("ip") private var ip = "192.168.5."
//    @AppStorage("port") private var port = ""
    @State private var messageToSend = ""
    
    var body: some View {
            VStack {
                Text("Connect to iPhone")
                    .font(.title3)
                    .fontWeight(.bold)
                TextField("Server IP", text: $controlWebsocket.hostname)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .keyboardType(.decimalPad)
                TextField("Server Port", text: $controlWebsocket.port)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .keyboardType(.numberPad)
                    .disabled(true)
                
                if controlWebsocket.isConnected {
                    Button("Disconnect", role: .destructive) {
                        controlWebsocket.disconnect()
                    }
                    .padding()
//                    .buttonStyle(.borderedProminent)
                } else {
                    Button("Connect") {
                        controlWebsocket.connect2iphone()
                        print("ip: ", controlWebsocket.hostname)
                    }
                    .padding()
//                    .buttonStyle(.borderedProminent)
                }
            }
            .padding()
            
        #if os(iOS)
            .background(Color(UIColor.secondarySystemBackground))
            .cornerRadius(15)
        #elseif os(visionOS)
            .background(Material.regular)
            .cornerRadius(40)
        #endif
            .shadow(color: Color.black.opacity(0.15), radius: 5)
    }
}

#Preview {
    ConnectPanel(controlWebsocket: ControlWebsocket())
}
#endif
