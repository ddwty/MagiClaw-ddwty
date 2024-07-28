//
//  HistoryView.swift
//  talkWithRpi
//
//  Created by Tianyu on 7/22/24.
//

import SwiftUI
import UniformTypeIdentifiers
import SwiftData

struct HistoryView: View {
//    @Query private var dataRecordings: [ARStorgeData]
    @Query private var allStorgeData: [AllStorgeData]
//    @State private var navigationPath: [ARStorgeData] = []
    
    var body: some View {
        NavigationStack() {
            List(allStorgeData) { recording in
                NavigationLink(destination: RecordingDetailView(recording: recording)) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Created at: \(recording.createTime, formatter: dateFormatter)")
                        Text("Duration: \(recording.timeDuration, specifier: "%.2f") seconds")
                            .font(.caption)
                            .foregroundStyle(.gray)
                    }
                }
            }
            .navigationTitle("History")
            
        }
    }
}


private let dateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .short
    formatter.timeStyle = .short
    return formatter
}()

#Preview(traits: .landscapeRight) {
    HistoryView()
        .modelContainer(previewContainer)
}

//#Preview(traits: .landscapeRight) {
//    RecordingDetailView(recording: SampleDeck.contents[0])
//        .modelContainer(previewContainer)
//}


struct RecordingDetailView: View {
//    @Bindable var recording: ARStorgeData
    @Bindable var recording: AllStorgeData
    @State private var isFileExporterPresented = false
    @State private var isProcessing = false
    @State private var csvOutputURLs: [URL] = []
    @State private var isProcessingSort = true
    
//    @State private var sortedARData: [ARData] = []
//    @State private var sortedForceData: [ForceData] = []
//    @State private var sortedAngleData: [AngleData] = []
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack {
                        Text("Task description: ")
                            .font(.headline)
                        
                        Text(recording.notes)
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                }
                
                Section {
                    if isProcessing {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle())
                            .padding()
                    } else {
                        Button(action: {
                            generateCSV()
                        }) {
                            HStack {
                                Spacer()
                                Label("Share", systemImage: "square.and.arrow.up")
                                Spacer()
                            }
                        }
                    }
                    
                    Button(action: {
                        // Add delete functionality if needed
                    }) {
                        HStack {
                            Spacer()
                            Label("Delete", systemImage: "trash")
                            Spacer()
                        }
                    }
                    .foregroundColor(.red)
                }
                Section {
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Text("Duration:")
                                .font(.headline)
                            Spacer()
                            Text("\(recording.timeDuration, specifier: "%.2f") seconds")
                                .font(.body)
                                .foregroundColor(.secondary)
                        }
                        
                        Divider()
                        
                        HStack {
                            Text("Data length:")
                                .font(.headline)
                            Spacer()
//                            if isProcessingSort {
//                                ProgressView()
//                                    .progressViewStyle(CircularProgressViewStyle())
//                            } else {
//                                Text("ARData: \(sortedARData.count) | ForceData: \(sortedForceData.count) | AngleData: \(sortedAngleData.count)")
//                                    .font(.body)
//                                    .foregroundColor(.secondary)
//                            }
                            
                            Text("ARData: \(recording.unsortedARData.count) | ForceData: \(recording.unsortedForceData.count) | AngleData: \(recording.unsortedAngleData.count)")
                                .font(.body)
                                .foregroundColor(.secondary)
                        }
                        
                        Divider()
                        
                        HStack {
                            Text("Create date:")
                                .font(.headline)
                            Spacer()
                            Text("\(recording.createTime, formatter: dateFormatter)")
                                .font(.body)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                }
                
                
//                Section {
//                    ForEach(recording.data) { data in
//                        Text("Timestamp: \(data.timestamp)")
//                    }
//                    .onAppear() {
//                        for data in recording.data {
//                            print("Timestamp: \(data.timestamp)") // not in order
//                        }
//                    }
//                }
//                Section {
//                    ForEach(recording.data) { arData in
//                        NavigationLink(destination: ARDataDetailView(arData: arData)) {
//                            VStack(alignment: .leading) {
//                                Text("Timestamp: \(arData.timestamp, specifier: "%.2f")")
//                                    .font(.body)
//                                Text("Transform: \(arData.transform.prefix(4).map { String(format: "%.3f", $0) }.joined(separator: ", "))...")
//                                    .font(.caption)
//                                    .foregroundColor(.secondary)
//                            }
//                            .padding(.vertical, 4)
//                        }
//                    }
//                }
                
            }
            .navigationTitle("Recording Details")
            .navigationBarTitleDisplayMode(.inline)
            
//            .onAppear { // for showing the data in order
//                            self.isProcessingSort = true
//                            loadSortedData {
//                                self.isProcessingSort = false
//                            }
//                        }
            
        }
        .sheet(isPresented: Binding<Bool>(
                    get: { !csvOutputURLs.isEmpty },
                    set: { if !$0 { csvOutputURLs = [] } }
                )) {
                    ShareSheet(activityItems: csvOutputURLs)
            }
        
    }
    
    private func generateCSV() {
        isProcessing = true

        DispatchQueue.global(qos: .userInitiated).async {
            let arCSVURL = exportToCSV(data: recording.arData, fileName: "ARData")
            let forceCSVURL = exportToCSV(data: recording.forceData, fileName: "ForceData")
            let angleCSVURL = exportToCSV(data: recording.angleData, fileName: "AngleData")

            DispatchQueue.main.async {
                self.csvOutputURLs = [arCSVURL, forceCSVURL, angleCSVURL].compactMap { $0 }
                self.isProcessing = false
            }
        }
    }

    private func exportToCSV<T: CSVConvertible>(data: [T], fileName: String) -> URL? {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyyMMdd_HHmmss"
            let dateString = dateFormatter.string(from: recording.createTime)

            let tempDirectory = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
            let csvOutputURL = tempDirectory.appendingPathComponent("\(dateString)_\(fileName)").appendingPathExtension("csv")

            var csvText = data.first?.csvHeader() ?? ""
            for item in data {
                csvText.append("\(item.csvRow())\n")
            }

            do {
                try csvText.write(to: csvOutputURL, atomically: true, encoding: .utf8)
                print("CSV saved to: \(csvOutputURL.absoluteString)")
                return csvOutputURL
            } catch {
                print("Error saving CSV: \(error.localizedDescription)")
                return nil
            }
        }


    
    // MARK: - not in use for now
//    private func loadSortedData(completion: @escaping () -> Void) {
//            DispatchQueue.global(qos: .userInitiated).async {
//                let sortedARData = recording.arData.sorted { $0.timestamp < $1.timestamp }
//                let sortedForceData = recording.forceData.sorted { $0.timeStamp < $1.timeStamp }
//                let sortedAngleData = recording.angleData.sorted { $0.timeStamp < $1.timeStamp }
//                
//                DispatchQueue.main.async {
//                    self.sortedARData = sortedARData
//                    self.sortedForceData = sortedForceData
//                    self.sortedAngleData = sortedAngleData
//                    completion()
//                }
//            }
//        }
    
    
}

struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        return UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

struct ARDataDetailView: View {
    let arData: ARData
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Timestamp: \(arData.timestamp)")
                .font(.headline)
            
            Text("Transform:")
                .font(.headline)
            
            VStack(alignment: .leading, spacing: 4) {
                ForEach(0..<4) { row in
                    HStack {
                        ForEach(0..<4) { col in
                            Text(String(format: "%.3f", arData.transform[row * 4 + col]))
                                .frame(width: 70, alignment: .leading)
                        }
                    }
                }
            }
            
            Spacer()
        }
        .padding()
        .navigationTitle("AR Data Details")
        .navigationBarTitleDisplayMode(.inline)
    }
}
