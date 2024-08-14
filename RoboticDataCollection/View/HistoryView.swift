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
    @Environment(\.modelContext) private var modelContext
    //    @State private var navigationPath: [ARStorgeData] = []
    
    var body: some View {
        NavigationStack {
                    List {
                        ForEach(allStorgeData) { recording in
                            NavigationLink(destination: RecordingDetailView(recording: recording)) {
                                HStack(alignment: .center, spacing: 6) {
                                    VStack(alignment: .leading) {
                                        Text("Created at: \(recording.createTime, formatter: dateFormatter)")
                                        Text(recording.notes)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                    Spacer()
                                    Text("Duration: \(recording.timeDuration, specifier: "%.2f") seconds")
                                        .font(.body)
                                        .foregroundStyle(.gray)
                                }
                            }
                        }
                        .onDelete(perform: deleteRecordings) // Add this line
                    }
                    .navigationTitle("History")
                }
    }
    
    private func deleteRecordings(at indexSet: IndexSet) {
        for index in indexSet {
            modelContext.delete(allStorgeData[index])
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
                        HStack {
                            Spacer()
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle())
                            Spacer()
                        }
                    } else if csvOutputURLs.isEmpty{
                        Button(action: {
                            generateCSV()
                        }) {
                            HStack {
                                Spacer()
                                Label("Generate CSV file", systemImage: "square.and.arrow.up")
                                Spacer()
                            }
                        }
                    } else if !csvOutputURLs.isEmpty {
                        ShareLink(items: csvOutputURLs) {
                            HStack {
                                Spacer()
                                Label("Ready to share", systemImage: "square.and.arrow.up")
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
                NavigationLink(destination: ARDataView(arData: recording.arData)) {
                    Text("AR Data")
                }
                NavigationLink(destination: ForceDataView(forceData: recording.forceData)) {
                    Text("Rpi Data")
                }
                NavigationLink(destination: AngleDataView(angleData: recording.angleData)) {
                    Text("Angle Data")
                }
               
                
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
        
    }
    
    private func generateCSV() {
        isProcessing = true
        
        DispatchQueue.global(qos: .userInitiated).async {
            let arCSVURL = exportToCSV(data: recording.arData, fileName: "PoseData")
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

struct ARDataView: View {
    let arData: [ARData]
    
    var body: some View {
        List(arData) { data in
            NavigationLink(destination: ARDataDetailView(arData: data)) {
                VStack(alignment: .leading) {
                    Text("Timestamp: \(data.timestamp, specifier: "%.3f")")
                        .font(.body)
//                    Text("Transform: \(data.transform.prefix(4).map { String(format: "%.3f", $0) }.joined(separator: ", "))...")
//                        .font(.caption)
//                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 4)
            }
        }
        .navigationTitle("AR Data")
        .navigationBarTitleDisplayMode(.inline)
    }

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

struct AngleDataView: View {
    let angleData: [AngleData]
    var body: some View {
        ScrollView {
            ForEach(angleData) { data in
                NavigationLink(destination: AngleDataDetailView(angleData: data)) {
                    VStack(alignment: .leading) {
                        Text("Timestamp: \(data.timeStamp, specifier: "%.2f")")
                            .font(.body)
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .navigationTitle("Angle Data")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct ForceDataView: View {
    let forceData: [ForceData]
    var body: some View {
        List(forceData) { data in
            NavigationLink(destination: ForceDataDetailView(forceData: data)) {
                Text("Timestamp: \(data.timeStamp, specifier: "%.3f")")
                
            }
        }
        .navigationTitle("Force Data")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct ForceDataDetailView: View {
    let forceData: ForceData
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Timestamp: \(forceData.timeStamp)")
                .font(.headline)
            
            Text("Force: \(String(describing: forceData.forceData))")
                .font(.headline)
            
            Spacer()
        }
        .padding()
        .navigationTitle("Force Data Details")
        .navigationBarTitleDisplayMode(.inline)
    }
}


struct AngleDataDetailView: View {
    let angleData: AngleData
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Timestamp: \(angleData.timeStamp)")
                .font(.headline)
            
            Text("Angle: \(angleData.angle)")
                .font(.headline)
            
            Spacer()
        }
        .padding()
        .navigationTitle("Angle Data Details")
        .navigationBarTitleDisplayMode(.inline)
    }
}
