//
//  ScenarioCase.swift
//  RoboticDataCollection
//
//  Created by Tianyu on 8/8/24.
//

import Foundation
import SwiftData
import SwiftUI


//enum Scenario: String, CaseIterable, Identifiable, Codable {
//    case unspecified, bedroom, bathroom, diningroom, kitchen, livingRoom, laboratory, office, outdoor
//    var id: Self {self}
//    
//    var color: Color {
//        switch self {
//        case .unspecified: return .gray
//        case .bedroom: return .purple
//        case .bathroom: return .blue
//        case .diningroom: return .green
//        case .kitchen: return .orange
//        case .livingRoom: return .yellow
//        case .laboratory: return .red
//        case .office: return .cyan
//        case .outdoor: return .brown
//        default : return .gray
//        }
//    }
//    
//}




extension Scenario {
    static let sampleScenario: [Scenario] = [
            Scenario(name: "Laboratory", color: "1D39C4"),  // 金黄色
            Scenario(name: "Living Room", color: "F98B15"),
            Scenario(name: "Bathroom", color: "13C2C2"),
            Scenario(name: "Kitchen", color: "712DD1"),
            Scenario(name: "Outdoor", color: "864D00"),
            Scenario(name: "Office", color: "8A2BE2"),      // 蓝紫色
            Scenario(name: "Garden", color: "228B22"),      // 森林绿
            Scenario(name: "Balcony", color: "FF69B4")      // 热粉色
    ]
    static let unspecifiedScenario = Scenario(name: "Unspecified", color: "A2AAAD")
}

extension Scenario: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(name)
        hasher.combine(color)
    }

    static func == (lhs: Scenario, rhs: Scenario) -> Bool {
        return lhs.name == rhs.name && lhs.color == rhs.color
    }
}

let defaultScenario = Scenario(name: "Unspecified", color: "#808080")
