//
//  HowtoUseView.swift
//  MagiClaw
//
//  Created by Tianyu on 9/13/24.
//

import SwiftUI



struct HowtoUseView: View {
    
    var body: some View {
        
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    
                    // 大标题
                    //                Text("User guidelines")
                    //                    .font(.largeTitle)
                    //                    .fontWeight(.bold)
                    //                    .padding(.top, 32)
                    //                
                    //                Divider()
                    //                    .padding(.vertical, 8)
                    //                
                    //                // 介绍部分
                    //                Text("Introduction")
                    //                    .font(.title2)
                    //                    .fontWeight(.semibold)
                    //                
                    //                Text("This app is designed to ")
                    //                    .font(.body)
                    //                    .foregroundStyle(.secondary)
                    //                    .padding(.bottom, 16)
                    
                    // 功能部分
                    Group {
                        ForEach(documentationSections, id: \.title) { section in
                            UserGuideCard(doc: section)
                        }
                    }
                    
                    // 提示部分
                    //                Text("Tips and Tricks")
                    //                    .font(.title2)
                    //                    .fontWeight(.semibold)
                    //                    .padding(.top, 16)
                    //
                    //                Text("1. Use swipe gestures to quickly navigate between sections.\n2. Long press on a data entry to access additional options like edit or delete.\n3. Export your data frequently to ensure you always have a backup.")
                    //                    .font(.body)
                    //                    .foregroundStyle(.secondary)
                    
                    Spacer(minLength: 32)
                }
                .padding(.horizontal, 24)
            }
            .scrollContentBackground(.hidden)
            .background(Color.background)
            .navigationTitle("User guide")
        }
    }
}


#Preview {
    HowtoUseView()
//    DocumentationView()

}
//#Preview {
//    UserGuideCard()
//}

#Preview {
    UserGuideCard(doc: UserDoc(
        title: "Connecting to a Raspberry Pi",
        imageName: "tray.and.arrow.down",
        description: nil,
        docSection: [
            DocSection(numPoints: "Ensure your device and the Raspberry Pi are on the same local network (e.g., the same Wi-Fi).", bullist: nil),
            DocSection(numPoints: "Open the “Settings” page at the bottom of the app.", bullist: nil),
            DocSection(numPoints: "Enter your Raspberry Pi’s IP address or hostname in the Hostname input box. Format: 192.168.x.x or hostname.local.",
                       bullist: ["   - Run `ifconfig` on the Raspberry Pi to find its local IP address (format: 192.168.x.x).",
                                 "   - Run `hostname` to retrieve the Raspberry Pi’s hostname."
                                ]
                      )
        ]
    ))
}


struct UserGuideCard: View {
    @Environment(\.colorScheme) var colorScheme
    let doc: UserDoc
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: doc.imageName)
                    .foregroundColor(Color("tintColor"))
                    .font(.title)
                Spacer()
                
            }
            
            Text(doc.title)
                .font(.title2)
                .fontWeight(.semibold)
            
            Divider()
            
            if let description = doc.description {
                Text(description)
                    .font(.body)
            }
            
            ForEach(Array(doc.docSection.enumerated()), id: \.offset) { index, docSection in
                HStack(alignment: .top, spacing: 8) {
                    
                    if docSection.numPoints != nil {
                        Text("\(index + 1).")
                            .font(.body)
                            .fontWeight(.bold)
                            .foregroundColor(Color("tintColor"))
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                       
                        if let point = docSection.numPoints {
                            Text(point)
                                .font(.body)
                                .foregroundColor(Color.primary)
                        }
                        
                    
                        if let bullist = docSection.bullist {
                            VStack(alignment: .leading, spacing: 8) {
                                ForEach(bullist, id: \.self) { bullet in
                                    HStack(alignment: .top, spacing: 8) {
                                        Text("•")
                                            .font(.body)
                                            .foregroundColor(Color("tintColor"))
                                        Text(bullet)
                                            .font(.body)
                                            .foregroundColor(.primary)
                                    }
                                }
                            }
                        }
                    }
                }
            }
            
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(colorScheme == .light ? Color(.systemBackground) : Color(.secondarySystemBackground))
                .shadow(color: Color.black.opacity(0.15), radius: 10, x: 0, y: 0)
        )
    }
}

//struct UserGuideCard3: View {
//    @Environment(\.colorScheme) var colorScheme
//    let section: UserDocModel
//
//    var body: some View {
//        VStack(alignment: .leading, spacing: 16) {
//            // 标题部分
//            HStack {
//                Text("\(section.number).")
//                    .font(.title)
//                    .fontWeight(.bold)
//                    .foregroundColor(.blue)
//                Text(section.title)
//                    .font(.title)
//                    .fontWeight(.semibold)
//                Spacer()
//            }
//
//            // 内容部分
//            if let contents = section.contents {
//                VStack(alignment: .leading, spacing: 8) {
//                    ForEach(contents, id: \.self) { content in
//                        Text(content)
//                            .font(.body)
//                            .foregroundColor(.primary)
//                    }
//                }
//            }
//
//            // 子部分
//            if let subsections = section.subsections {
//                ForEach(subsections) { subsection in
//                    VStack(alignment: .leading, spacing: 8) {
//                        Text(subsection.title)
//                            .font(.headline)
//                            .fontWeight(.semibold)
//                            .foregroundColor(.blue)
//
//                        VStack(alignment: .leading, spacing: 4) {
//                            ForEach(subsection.contents, id: \.self) { content in
//                                Text(content)
//                                    .font(.body)
//                                    .foregroundColor(.primary)
//                            }
//                        }
//                    }
//                    .padding(.top, 8)
//                }
//            }
//        }
//        .padding()
//        .background(
//            RoundedRectangle(cornerRadius: 15)
//                .fill(colorScheme == .light ? Color(.systemBackground) : Color(.secondarySystemBackground))
//        )
//        .shadow(color: Color.black.opacity(0.15), radius: 10, x: 0, y: 0)
//        .padding(.horizontal)
//    }
//}



// Helper View for Sections
//struct SectionView: View {
//    let title: String
//    let description: String
//
//    var body: some View {
//        VStack(alignment: .leading, spacing: 12) {
//            Text(title)
//                .font(.title2)
//                .fontWeight(.bold)
//            Text(description)
//                .font(.body)
//                .foregroundStyle(.secondary)
//        }
//        .padding()
//        .background(Material.regular)
//        .clipShape(RoundedRectangle(cornerRadius: 15, style: .continuous))
//        .shadow(color: Color.primary.opacity(0.1), radius: 10, x: 0, y: 5)
//    }
//}





//struct DocumentationCard: View {
//    var title: String
//    var description: String
//    var imageName: String // 可选：用于显示图标
//
//    var body: some View {
//        VStack(alignment: .leading, spacing: 16) {
//            // 可选图标
//            if !imageName.isEmpty {
//                Image(systemName: imageName)
//                    .font(.system(size: 40))
//                    .foregroundColor(.white)
//            }
//
//            Text(title)
//                .font(.title)
//                .fontWeight(.bold)
//                .foregroundColor(.white)
//
//            Text(description)
//                .font(.body)
//                .foregroundColor(.white.opacity(0.8))
//        }
//        .padding()
//        .background(
//            LinearGradient(gradient: Gradient(colors: [Color.blue, Color.purple]),
//                           startPoint: .topLeading,
//                           endPoint: .bottomTrailing)
//        )
//        .cornerRadius(20)
//        .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 10)
//        .padding()
//    }
//}

//struct DocumentationCard_Previews: PreviewProvider {
//    static var previews: some View {
//        DocumentationCard(
//            title: "如何使用本应用",
//            description: "本应用可以帮助您管理任务，提高生产力。以下是一些使用指南……",
//            imageName: "book.fill"
//        )
//    }
//}
