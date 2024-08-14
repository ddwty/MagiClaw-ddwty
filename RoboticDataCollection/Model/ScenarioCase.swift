//
//  ScenarioCase.swift
//  RoboticDataCollection
//
//  Created by Tianyu on 8/8/24.
//

import Foundation
import SwiftData
import SwiftUI

enum Scenario: String, CaseIterable, Identifiable , Codable{
    case unspecified, bedroom, bathroom, diningroom, kitchen, livingRoom, laboratory, office, outdoor
    var id: Self {self}
    
    var color: Color {
            switch self {
            case .unspecified: return .gray
            case .bedroom: return .purple
            case .bathroom: return .blue
            case .diningroom: return .green
            case .kitchen: return .orange
            case .livingRoom: return .yellow
            case .laboratory: return .red
            case .office: return .cyan
            case .outdoor: return .brown
            }
        }
    
}


class SelectedScenario: ObservableObject {
    static let shared = SelectedScenario()
    @Published var selectedScenario: Scenario
    
    private init(selectedScenario: Scenario = .unspecified) {
        self.selectedScenario = selectedScenario
    }
}
