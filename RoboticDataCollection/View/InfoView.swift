//
//  InfoView.swift
//  MagiClaw
//
//  Created by 吴天禹 on 2024/8/24.
//

import SwiftUI
import MessageUI


struct InfoView: View {
    @Binding var isShowingMailView: Bool
    @State var result: Result<MFMailComposeResult, Error>? = nil
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        NavigationStack {
            VStack {
                HStack {
                    Spacer()
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Image(systemName: "xmark")
                            .foregroundColor(.white)
                            .padding()
                            .background(Circle().fill(Color.gray.opacity(0.6)))
                    }
                    .padding(.top, 10)
                    .padding(.trailing, 10)
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
                        .foregroundStyle(.primary)
                        .font(.title2)
                }
                .padding()
                Divider()
                VStack(alignment: .leading) {
                    Text("Developed by the Design and Learning Research Group at Southern University of Science and Technology.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.horizontal)
                    HStack(alignment: .firstTextBaseline) {
                        Text("Our website:")
                            .foregroundColor(.secondary)
                            .padding(.horizontal)
                           
                        
                        Link("ancorasir.com", destination: URL(string: "https://ancorasir.com")!)
                            .foregroundColor(.blue)
                    }
                    .padding(.top, 5)
                }

                Divider()
              

                Button(action: {
                    self.isShowingMailView.toggle()
                }) {
                    Label("Contact author by e-mail", systemImage: "envelope")
//                        .font(.headline)
//                        .foregroundColor(.blue)
//                        .padding()
//                        .background(Color.blue.opacity(0.1))
//                        .cornerRadius(8)
                }
                .buttonStyle(.bordered)
                .tint(.blue)
                .controlSize(.large)
                .disabled(!MFMailComposeViewController.canSendMail())
                .sheet(isPresented: $isShowingMailView) {
                    MailView(result: self.$result)
                }
                .padding()

                Spacer()
                Spacer()
            }
            .padding()
//            .navigationTitle("About")
        }
    }
}

#Preview {
    InfoView(isShowingMailView: .constant(false))
}
