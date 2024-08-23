//
//  ScenarioCase.swift
//  RoboticDataCollection
//
//  Created by Tianyu on 8/8/24.
//

import Foundation
import SwiftData
import SwiftUI


enum Scenario: String, CaseIterable, Identifiable, Codable {
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
        default : return .gray
        }
    }
    
}



@Model
class Scenario2 {
    @Attribute(.unique) var name: String
    var color: String
    var allData: [AllStorgeData]?
    
    init(name: String = "", color: String = "FF4500") {
        self.name = name
        self.color = color
    }
    
    var hexColor: Color {
        Color(hex: self.color) ?? .red
    }
}
extension Scenario2: Identifiable {}

extension Scenario2 {
    static let sampleScenario: [Scenario2] = [
            Scenario2(name: "Laboratory", color: "FFD700"),  // 金黄色
            Scenario2(name: "Living Room", color: "FF4500"), // 橙红色
            Scenario2(name: "Office", color: "8A2BE2"),      // 蓝紫色
            Scenario2(name: "Garage", color: "A52A2A"),      // 棕色
            Scenario2(name: "Garden", color: "228B22"),      // 森林绿
            Scenario2(name: "Balcony", color: "FF69B4")      // 热粉色
    ]
    static let unspecifiedScenario = Scenario2(name: "Unspecified", color: "A2AAAD")
}

extension Scenario2: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(name)
        hasher.combine(color)
    }

    static func == (lhs: Scenario2, rhs: Scenario2) -> Bool {
        return lhs.name == rhs.name && lhs.color == rhs.color
    }
}

let defaultScenario = Scenario2(name: "Unspecified", color: "#808080")
