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
    @Environment(\.modelContext) private var modelContext
    @State private var sortOrder = SortDescriptor(\AllStorgeData.createTime, order: .reverse)
    
    var body: some View {
        NavigationStack {
            HistoryListView(sort: sortOrder)
            .navigationTitle("Records")
            .toolbar {
                Menu("Sort", systemImage: "arrow.up.arrow.down") {
                    Picker("Sort", selection: $sortOrder) {
                        Label("Time ascending", systemImage: "arrow.up.circle")
                            .tag(SortDescriptor(\AllStorgeData.createTime,  order: .forward))
                       
                        Label("Time descending", systemImage: "arrow.down.circle")
                            .tag(SortDescriptor(\AllStorgeData.createTime, order: .reverse))
                    }
                    .pickerStyle(.inline)
                }
            }
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
//



struct HistoryListView: View {
    @Query private var allStorgeData: [AllStorgeData]
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) var colorScheme
    var body : some View {
        if allStorgeData.isEmpty {
            VStack {
                Spacer()
                Text("Empty")
                    .padding()
                    .font(.title)
                    .foregroundStyle(.secondary)
                Text("Start recording your first data entry")
                    .foregroundStyle(.secondary)
                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color("background"))
            
        } else {
            List {
                ForEach(allStorgeData) { recording in
                    NavigationLink(destination: RecordingDetailView(recording: recording)) {
                        HStack(alignment: .historyAlignment) {
                            VStack(alignment: .leading) {
                                Text(recording.scenario?.name.capitalized ?? "Unspecified")
                                    .font(.caption)
                                    .foregroundColor(recording.scenario?.hexColor ?? Color.gray)
                                    .padding(.horizontal, 5)
                                    .padding(.vertical, 3)
                                    .background(
                                        Capsule()
                                            .strokeBorder(recording.scenario?.hexColor ?? Color.gray, lineWidth: 1)
                                    )
                                    .offset(y: 2)
                                
                                Text("\(recording.createTime, formatter: dateFormatter)")
                                    .foregroundColor(.primary)
                                    .alignmentGuide(.historyAlignment) { (dim) -> CGFloat in
                                        dim[VerticalAlignment.center]
                                        
                                    }
                                
                                Text(recording.notes.isEmpty ? "No description" : recording.notes)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .offset(y: 2)
                                
                            }
                            Spacer()
                            VStack {
                                Spacer()
                                Text("\(recording.timeDuration, specifier: "%.1f") seconds")
                                    .font(.body)
                                    .foregroundStyle(.gray)
                                    .alignmentGuide(.historyAlignment) { (dim) -> CGFloat in
                                        dim[VerticalAlignment.center]
                                    }
                                Spacer()
                            }
                            
                        }
                        
                    }
                    .if(colorScheme == .dark) { view in
                        view.listRowBackground(
                                Rectangle()
                                    .foregroundColor(.clear)
                                    .background(Material.thinMaterial)
                        )
                    }
                    
                    .swipeActions(edge: .trailing) {
                        Button(role: .destructive) {
                            withAnimation {
                                modelContext.delete(recording)
                            }
                           
                        } label: {
                            Label("Delete", systemImage: "trash")
                                .foregroundStyle(Color.red)
                        }
                    }
                    .contextMenu {
                        Button(role: .destructive) {
                            withAnimation {
                                modelContext.delete(recording)
                            }
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                }
                //                .onDelete(perform: deleteRecordings)
                
            }
            .scrollContentBackground(.hidden)
            .background(Color("background"))
            
        }
    }
    init(sort: SortDescriptor<AllStorgeData>) {
        _allStorgeData = Query(sort: [sort])
    }
}


struct RecordingDetailView: View {
    @Environment(\.colorScheme) var colorScheme
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
                        Text("Scenario:")
                            
                        // TODO: - EDIT
                        Text(recording.scenario?.name.capitalized ?? "Unspecified")
                            .font(.caption)
                            .foregroundColor(recording.scenario?.hexColor ?? Color.gray)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 3)
                            .background(
                                Capsule()
                                    .strokeBorder(recording.scenario?.hexColor ?? Color.gray, lineWidth: 1)
                            )
                       
                        
                    }
                    HStack {
                        
                        Text("Task description: ")
                        
                        Text(recording.notes == "" ? "No description " : recording.notes)
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                }
                .if(colorScheme == .dark) { view in
                    view.listRowBackground(
                            Rectangle()
                                .foregroundColor(.clear)
                                .background(Material.thinMaterial)
                    )
                }
                
//                Section {
//                        if isProcessing {
//                            HStack {
//                                Spacer()
//                                ProgressView()
//                                    .progressViewStyle(CircularProgressViewStyle())
//                                Spacer()
//                            }
//                        } else if csvOutputURLs.isEmpty{
//                            Button(action: {
//                                generateCSV()
//                            }) {
//                                HStack {
//                                    Spacer()
//                                    Label("Generate CSV file", systemImage: "arrow.up.doc")
//                                    Spacer()
//                                }
//                            }
//                        } else if !csvOutputURLs.isEmpty {
//                            ShareLink(items: csvOutputURLs) {
//                                HStack {
//                                    Spacer()
//                                    Label("Ready to share", systemImage: "square.and.arrow.up")
//                                        .foregroundColor(.green)
//                                    Spacer()
//                                }
//                            }
//                        }
//                    
//                }
                Section {
                    HStack {
                        Text("Duration")
                        Spacer()
                        Text("\(recording.timeDuration, specifier: "%.3f") seconds")
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Create time")
                        Spacer()
                        Text("\(recording.createTime, formatter: dateFormatter)")
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                }
                .if(colorScheme == .dark) { view in
                    view.listRowBackground(
                            Rectangle()
                                .foregroundColor(.clear)
                                .background(Material.thinMaterial)
                    )
                }
                
                Section(header: Text("Details")) {
                    HStack(alignment: .center) {
                        Text("Pose Data")
                        Spacer()
                        Text("\(recording.ARDataCount)")
                            .foregroundStyle(.gray)
                    }
                    
                    HStack(alignment: .center) {
                        Text("Left Force Data")
                        Spacer()
                        Text("\(recording.leftForceCount)")
                            .foregroundStyle(.gray)
                        
                    }
                    
                    HStack(alignment: .center) {
                        Text("Right Force Data")
                        Spacer()
                        Text("\(recording.rightForceCount)")
                            .foregroundStyle(.gray)
                        
                    }
                    
                    HStack(alignment: .center) {
                        Text("Angle Data")
                        Spacer()
                        Text("\(recording.angleDataCount)")
                            .foregroundStyle(.gray)
                    }
                    
//                    
//                    NavigationLink(destination: ARDataView(arData: recording.unsortedARData)) {
//                        HStack(alignment: .center) {
//                            Text("Pose Data")
//                            Spacer()
//                            Text("\(recording.unsortedARData.count)")
//                                .foregroundStyle(.gray)
//                        }
//                    }
//                    NavigationLink(destination: ForceDataView(forceData: recording.unsortedForceData)) {
//                        HStack(alignment: .center) {
//                            Text("Left Force Data")
//                            Spacer()
//                            Text("\(recording.unsortedForceData.count)")
//                                .foregroundStyle(.gray)
//                            
//                        }
//                    }
//                    
//                    NavigationLink(destination: ForceDataView(forceData: recording.unsortedRightForceData)) {
//                        HStack(alignment: .center) {
//                            Text("Right Force Data")
//                            Spacer()
//                            Text("\(recording.unsortedRightForceData.count)")
//                                .foregroundStyle(.gray)
//                            
//                        }
//                    }
//                    
//                    NavigationLink(destination: AngleDataView(angleData: recording.unsortedAngleData)) {
//                        HStack(alignment: .center) {
//                            Text("Angle Data")
//                            Spacer()
//                            Text("\(recording.unsortedAngleData.count)")
//                                .foregroundStyle(.gray)
//                        }
//                    }
                }
                .if(colorScheme == .dark) { view in
                    view.listRowBackground(
                            Rectangle()
                                .foregroundColor(.clear)
                                .background(Material.thinMaterial)
                    )
                }
            }
            .navigationTitle("Recording Details")
            .navigationBarTitleDisplayMode(.inline)
            .scrollContentBackground(.hidden)
            .background(Color("background"))
            
        }
        
    }
    
//    private func generateCSV() {
//        isProcessing = true
//        
//        //TODO: - right force data
//        DispatchQueue.global(qos: .userInitiated).async {
//            let arCSVURL = exportToCSV(data: recording.arData, fileName: "PoseData")
//            let forceCSVURL = exportToCSV(data: recording.forceData, fileName: "ForceData")
//            let angleCSVURL = exportToCSV(data: recording.angleData, fileName: "AngleData")
//            
//            DispatchQueue.main.async {
//                self.csvOutputURLs = [arCSVURL, forceCSVURL, angleCSVURL].compactMap { $0 }
//                self.isProcessing = false
//            }
//        }
//    }
    
//    private func exportToCSV<T: CSVConvertible>(data: [T], fileName: String) -> URL? {
//        let dateFormatter = DateFormatter()
//        dateFormatter.dateFormat = "yyyyMMdd_HHmmss"
//        let dateString = dateFormatter.string(from: recording.createTime)
//        
//        let tempDirectory = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
//        let csvOutputURL = tempDirectory.appendingPathComponent("\(dateString)_\(fileName)").appendingPathExtension("csv")
//        
//        var csvText = data.first?.csvHeader() ?? ""
//        for item in data {
//            csvText.append("\(item.csvRow())\n")
//        }
//        
//        do {
//            try csvText.write(to: csvOutputURL, atomically: true, encoding: .utf8)
//            print("CSV saved to: \(csvOutputURL.absoluteString)")
//            return csvOutputURL
//        } catch {
//            print("Error saving CSV: \(error.localizedDescription)")
//            return nil
//        }
//    }
    
    
    
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

//struct ARDataView: View {
//    let arData: [ARData]
//    @State private var sortedARData: [ARData] = []
//    
//    var body: some View {
//        List(sortedARData) { data in
//            NavigationLink(destination: ARDataDetailView(arData: data)) {
//                VStack(alignment: .leading) {
//                    Text("Timestamp: \(data.timestamp, specifier: "%.3f")")
//                        .font(.body)
//                }
//                .padding(.vertical, 4)
//            }
//        }
//        .navigationTitle("AR Data")
//        .navigationBarTitleDisplayMode(.inline)
//        .onAppear {
//                    // Perform sorting when the view appears
//                    sortedARData = arData.sorted { $0.timestamp < $1.timestamp }
//        }
//    }
//}
//
//struct ARDataDetailView: View {
//    let arData: ARData
//    
//    var body: some View {
//        VStack(alignment: .leading, spacing: 16) {
//            Text("Timestamp: \(arData.timestamp)")
//                .font(.headline)
//            
//            Text("Transform:")
//                .font(.headline)
//            
//            VStack(alignment: .leading, spacing: 4) {
//                ForEach(0..<4) { col in
//                    HStack {
//                        ForEach(0..<4) { row in
//                            Text(String(format: "%.3f", arData.transform[row * 4 + col]))
//                                .frame(width: 70, alignment: .leading)
//                        }
//                    }
//                }
//            }
//            Spacer()
//        }
//        .padding()
//        .navigationTitle("AR Data Details")
//        .navigationBarTitleDisplayMode(.inline)
//    }
//}
//
//struct AngleDataView: View {
//    let angleData: [AngleData]
//    @State private var sortedAngleData: [AngleData] = []
//    var body: some View {
//        List(sortedAngleData) { data in
//            NavigationLink(destination: AngleDataDetailView(angleData: data)) {
//                Text("Timestamp: \(data.timeStamp, specifier: "%.3f")")
//                    .font(.body)
//            }
//        }
//        
//        .navigationTitle("Angle Data")
//        .navigationBarTitleDisplayMode(.inline)
//        .onAppear {
//                    // Perform sorting when the view appears
//                    sortedAngleData = angleData.sorted { $0.timeStamp < $1.timeStamp }
//        }
//    }
//}
//
//struct ForceDataView: View {
//    let forceData: [ForceData]
//    @State private var sortedForceData: [ForceData] = []
//    var body: some View {
//        List(sortedForceData) { data in
//            NavigationLink(destination: ForceDataDetailView(forceData: data)) {
//                Text("Timestamp: \(data.timeStamp, specifier: "%.3f")")
//                
//            }
//        }
//        .navigationTitle("Force Data")
//        .navigationBarTitleDisplayMode(.inline)
//        .onAppear {
//                    // Perform sorting when the view appears
//            sortedForceData = forceData.sorted { $0.timeStamp < $1.timeStamp }
//        }
//    }
//}
//
//struct ForceDataDetailView: View {
//    let forceData: ForceData
//    
//    var body: some View {
//        VStack(alignment: .leading, spacing: 16) {
//            Text("Timestamp: \(forceData.timeStamp)")
//                .font(.headline)
//            
//            Text("Force: \(String(describing: forceData.forceData))")
//                .font(.headline)
//            
//            Spacer()
//        }
//        .padding()
//        .navigationTitle("Force Data Details")
//        .navigationBarTitleDisplayMode(.inline)
//    }
//}
//
//
//struct AngleDataDetailView: View {
//    let angleData: AngleData
//    
//    var body: some View {
//        VStack(alignment: .leading, spacing: 16) {
//            Text("Timestamp: \(angleData.timeStamp)")
//                .font(.headline)
//            
//            Text("Angle: \(angleData.angle)")
//                .font(.headline)
//            
//            Spacer()
//        }
//        .padding()
//        .navigationTitle("Angle Data Details")
//        .navigationBarTitleDisplayMode(.inline)
//    }
//}
