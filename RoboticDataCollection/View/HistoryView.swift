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
    @Query private var dataRecordings: [ARStorgeData]
//    @State private var navigationPath: [ARStorgeData] = []
    
    var body: some View {
        NavigationStack() {
            List(dataRecordings) { recording in
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

#Preview(traits: .landscapeRight) {
    RecordingDetailView(recording: SampleDeck.contents[0])
        .modelContainer(previewContainer)
}


struct RecordingDetailView: View {
    @Bindable var recording: ARStorgeData
    @State private var isFileExporterPresented = false
    @State private var isProcessing = false
    @State private var csvOutputURL: URL? = nil
    
    var body: some View {
        NavigationStack {
            Form {
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
                            Text("\(recording.data.count)")
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
                    ForEach(recording.data) { data in
                        Text("Timestamp: \(data.timestamp)")
                    }
                    .onAppear() {
                        for data in recording.data {
                            print("Timestamp: \(data.timestamp)") // not in order
                        }
                    }
                }
                Section {
                    ForEach(recording.data) { arData in
                        NavigationLink(destination: ARDataDetailView(arData: arData)) {
                            VStack(alignment: .leading) {
                                Text("Timestamp: \(arData.timestamp, specifier: "%.2f")")
                                    .font(.body)
                                Text("Transform: \(arData.transform.prefix(4).map { String(format: "%.3f", $0) }.joined(separator: ", "))...")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
                
            }
            .navigationTitle("Recording Details")
            .navigationBarTitleDisplayMode(.inline)
            
            
        }
        .sheet(isPresented: Binding<Bool>(
            get: { csvOutputURL != nil },
            set: { if !$0 { csvOutputURL = nil } }
        )) {
            if let url = csvOutputURL {
                ShareSheet(activityItems: [url])
            }
        }
        
    }
    
    private func generateCSV() {
        isProcessing = true
        
        DispatchQueue.global(qos: .userInitiated).async {
            let csvURL = exportToCSV(arStorgeData: recording)
            
            DispatchQueue.main.async {
                self.csvOutputURL = csvURL
                self.isProcessing = false
            }
        }
    }
    func exportToCSV(arStorgeData: ARStorgeData) -> URL? {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMdd_HHmmss"
        let dateString = dateFormatter.string(from: arStorgeData.createTime)
        
        let tempDirectory = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
        let csvOutputURL = tempDirectory.appendingPathComponent(dateString).appendingPathExtension("csv")
        
        var csvText = "Timestamp,Transform\n"
        for arData in arStorgeData.data {
            let timestamp = arData.timestamp
            let transformString = arData.transform.map { String($0) }.joined(separator: ",")
            csvText.append("\(timestamp),\(transformString)\n")
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
    
    
    //    private func exportFrameDataToCSV() {
    //        let dateFormatter = DateFormatter()
    //        dateFormatter.dateFormat = "yyyyMMdd_HHmmss"
    //        let dateString = dateFormatter.string(from: Date())
    //
    //        let tempDirectory = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
    //        csvOutputURL = tempDirectory.appendingPathComponent(dateString + "frameData").appendingPathExtension("csv")
    //
    //        var csvText = "Timestamp,CameraTransform\n"
    //        for frameData in recording.data {
    //            let timestamp = frameData.timestamp
    //            let transform = frameData.transform
    //            let transformString = "\(transform.columns.0.x),\(transform.columns.0.y),\(transform.columns.0.z),\(transform.columns.0.w)," +
    //            "\(transform.columns.1.x),\(transform.columns.1.y),\(transform.columns.1.z),\(transform.columns.1.w)," +
    //            "\(transform.columns.2.x),\(transform.columns.2.y),\(transform.columns.2.z),\(transform.columns.2.w)," +
    //            "\(transform.columns.3.x),\(transform.columns.3.y),\(transform.columns.3.z),\(transform.columns.3.w)"
    //            csvText.append("\(timestamp),\(transformString)\n")
    //        }
    //
    //        do {
    //            try csvText.write(to: csvOutputURL!, atomically: true, encoding: .utf8)
    //            print("CSV saved to: \(csvOutputURL!.absoluteString)")
    //        } catch {
    //            print("Error saving CSV: \(error.localizedDescription)")
    //        }
    //    }
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
