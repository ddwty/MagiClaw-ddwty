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
    @Query private var scenarios: [Scenario]
    @Environment(\.modelContext) private var modelContext
    
    private let colors: [Color] = [
        .red, .blue, .green, .yellow, .orange, .purple, .pink, .gray, .mint, .cyan, .indigo, .brown, .teal
    ]
    
    private func randomColor() -> Color {
        // 选择不同于当前颜色的随机颜色
        var newColor: Color
        repeat {
            newColor = colors.randomElement() ?? .red
        } while newColor == color
        return newColor
    }
    
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Add New Scenario")) {
                    TextField("New scenario", text: $name)
                    //                    ColorPicker("Set the color", selection: $color, supportsOpacity: false)
                    HStack {
                        ColorPicker("Pick the color", selection: $color, supportsOpacity: false)
                        Button(action: {
                            withAnimation {
                                color = randomColor()
                            }
                        }) {
                            Text("Random")
                            
                        }
                        .padding(.leading)
                        .buttonStyle(.bordered)
                    }
                    HStack {
                        Spacer()
                        Button("Create") {
                            withAnimation {
                                // 触发震动
                                let impactFeedbackGenerator = UIImpactFeedbackGenerator(style: .light)
                                impactFeedbackGenerator.impactOccurred()
                                
                                let newScenario = Scenario(name: name, color: color.toHexString()!)
                                context.insert(newScenario)
                                self.name = ""
                            }
                            
                        }
                        //                        .buttonStyle(.borderedProminent)
                        .disabled(name.isEmpty)
#if DEBUG
                        Button("Add") {
                            let sampleDatas: [AllStorgeData] = generateSampleData()
                            
                            for sampleData in sampleDatas {
                                let container = modelContext.container
                                let actor = BackgroundSerialPersistenceActor(container: container)
                                modelContext.insert(sampleData)
                            }
                        }
#endif
                        Spacer()
                    }
                }
                Section(header: Text("Existing scenarios")) {
                    
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
