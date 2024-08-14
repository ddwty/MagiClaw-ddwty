//
//  ScenarioCase.swift
//  RoboticDataCollection
//
//  Created by Tianyu on 8/8/24.
//

import Foundation
enum Scenario: String, CaseIterable, Identifiable {
    case unspecified, bedroom, bathroom, diningroom,  kitchen, livingRoom, laboratory, office, outdoor
    var id: Self {self}
}

class SelectedScenario: ObservableObject {
    static let shared = SelectedScenario()
    @Published var selectedScenario: Scenario
    
    private init(selectedScenario: Scenario = .unspecified) {
        self.selectedScenario = selectedScenario
    }
}
