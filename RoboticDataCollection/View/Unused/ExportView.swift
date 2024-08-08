//
//  ExportView.swift
//  talkWithRpi
//
//  Created by Tianyu on 7/26/24.
//

//import SwiftUI
//
//
//
//#Preview {
//    ExportView()
//}
//import SwiftUI
//import UniformTypeIdentifiers
//
//struct ExportView: View {
//    @State private var isFileExporterPresented = false
//    @ObservedObject var recorder = ARRecorder.shared
//    
//    var body: some View {
//        VStack {
//            Button("Export CSV File") {
//                if recorder.csvOutputURL != nil {
//                    isFileExporterPresented = true
//                } else {
//                    print("No CSV file to export.")
//                }
//            }
//            .fileExporter(
//                isPresented: $isFileExporterPresented,
//                document: CSVDocument(fileURL: recorder.csvOutputURL ?? URL(fileURLWithPath: "")),
//                contentType: .commaSeparatedText,
//                defaultFilename: "exportedData"
//            ) { result in
//                switch result {
//                case .success(let url):
//                    print("File exported to: \(url)")
//                case .failure(let error):
//                    print("Export failed: \(error.localizedDescription)")
//                }
//            }
//        }
//    }
//}
//
//struct CSVDocument: FileDocument {
//    static var readableContentTypes: [UTType] { [.commaSeparatedText] }
//    
//    var fileURL: URL
//    
//    init(fileURL: URL) {
//        self.fileURL = fileURL
//    }
//    
//    init(configuration: ReadConfiguration) throws {
//        self.fileURL = URL(fileURLWithPath: "")
//    }
//    
//    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
//        return try FileWrapper(url: fileURL)
//    }
//}
