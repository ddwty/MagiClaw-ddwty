//
//  InfoView.swift
//  MagiClaw
//
//  Created by 吴天禹 on 2024/8/24.
//
#if os(iOS)
import SwiftUI
import MessageUI


struct InfoView: View {
    @Binding var isShowingMailView: Bool
    @State var result: Result<MFMailComposeResult, Error>? = nil
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 20.0) {
                HStack {
                    Spacer()
                    Button(action: {
                       dismiss()
                    }) {
                        Text("")
                    }
                    .padding(.top, 10)
                    .padding(.trailing, 10)
                    .buttonStyle(ExitButtonStyle())
                }
                
                Spacer()
                VStack {
                    HStack {
                        Spacer()
                        Image("icon")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .cornerRadius(18)
                            .shadow(radius: 10)
                            .frame(width: 100, height: 100)
                        Spacer()
                    }
                    .padding()
                    Text("MagiClaw")
                        .font(.title)
                        .fontWeight(.bold)
                        .fontDesign(.rounded)
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color("magiclawLinear1"), Color("magiclawLinear2"), Color("magiclawLinear3")],
                                startPoint: .leading, endPoint: .trailing)
                        )
                }
                .padding()
                Divider()
                VStack() {
                    Text("Developed by the Design and Learning Research Group at Southern University of Science and Technology.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.horizontal)
                    HStack(alignment: .firstTextBaseline) {
                        Text("Our website:")
                            .foregroundColor(.secondary)
                           
                        
                        Link("DeepClaw.com", destination: URL(string: "https://deepclaw.com")!)
                            .foregroundStyle(Color("tintColor"))

                    }
                    .padding(.top, 5)
                }

                Divider()
              
                if MFMailComposeViewController.canSendMail() {
                    Button(action: {
                        self.isShowingMailView.toggle()
                    }) {
                        Label("Contact author by e-mail", systemImage: "envelope")
                        //
                    }
                    .buttonStyle(.bordered)
                    .tint(.blue)
                    .controlSize(.large)
                    .disabled(!MFMailComposeViewController.canSendMail())
                    .sheet(isPresented: $isShowingMailView) {
                        MailView(result: self.$result)
                    }
                    .padding()
                }
                else {
                    Text("Author Email: ddwty@163.com")
                        .foregroundColor(.secondary)
                        .padding()
                    
                }

                Spacer()
                Spacer()
            }
            .padding()
            .background(Color("background"))
//            .navigationTitle("About")
        }
    }
}

#Preview {
    InfoView(isShowingMailView: .constant(false))
}
#endif
