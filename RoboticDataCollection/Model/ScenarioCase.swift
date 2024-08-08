//
//  ScenarioCase.swift
//  RoboticDataCollection
//
//  Created by Tianyu on 8/8/24.
//

import Foundation
enum Scenario: String, CaseIterable, Identifiable {
    case bedroom, livingRoom, kitchen, bathroom, diningRoom, office, outdoor, laboratory, undefined, other
    var id: Self {self}
}
