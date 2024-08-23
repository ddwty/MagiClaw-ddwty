//
//  NewScenarioView.swift
//  MagiClaw
//
//  Created by 吴天禹 on 2024/8/22.
//

import SwiftUI
import SwiftData

struct NewScenarioView: View {
    @State private var name = ""
    @State private var color = Color.red
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Query private var scenarios: [Scenario2]
    @Environment(\.modelContext) private var modelContext
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Add New Scenario")) {
                    TextField("New scenario", text: $name)
                    ColorPicker("Set the color", selection: $color, supportsOpacity: false)
                    HStack {
                        Spacer()
                        Button("Create") {
                            withAnimation {
                                let newScenario = Scenario2(name: name, color: color.toHexString()!)
                                context.insert(newScenario)
                                self.name = ""
                            }
                           
                        }
//                        .buttonStyle(.borderedProminent)
                        .disabled(name.isEmpty)
                        Spacer()
                    }
                }
                Section(header: Text("Existing scenarios")) {
                   
//                    ForEach(scenarios) { scenario in
//                        Text(scenario.name)
//                            .foregroundStyle(scenario.hexColor)
//                            .padding(.horizontal, 6)
//                            .padding(.vertical, 3)
//                            .background(
//                                Capsule()
//                                    .strokeBorder(scenario.hexColor, lineWidth: 1)
//                            )
//                            .swipeActions(edge: .trailing) {
//                                Button(role: .destructive) {
//                                    guard scenario.name != "Unspecified" else { return }
//                                    modelContext.delete(scenario)
//                                } label: {
//                                    Label("Delete", systemImage: "trash")
//                                }
//                            }
//                    }
                    
                    
                    ForEach(scenarios.sorted {
                        if $0.name == "Unspecified" {
                            return true
                        } else if $1.name == "Unspecified" {
                            return false
                        } else {
                            return $0.name.localizedCompare($1.name) == .orderedAscending
                        }
                    }) { scenario in
                            Text(scenario.name)
                                .foregroundStyle(scenario.hexColor)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 3)
                                .background(
                                    Capsule()
                                        .strokeBorder(scenario.hexColor, lineWidth: 1)
                                )
                                // 禁止Unspecified被删除
                                .if(scenario.name != "Unspecified") { view in
                                    view.swipeActions(edge: .trailing) {
                                        Button(role: .destructive) {
                                            modelContext.delete(scenario)
                                        } label: {
                                            Label("Delete", systemImage: "trash")
                                        }
                                    }
                                }
                        }
                    
                }
            }
            .navigationTitle("New Scenario")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

#Preview {
    NewScenarioView()
        .modelContainer(previewContainer)
}
